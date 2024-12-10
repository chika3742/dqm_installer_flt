#include "flutter_window.h"

#include <flutter/binary_messenger.h>

#include <memory>
#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "messages.g.h"

namespace {
    using dqm_installer_flt::SJisIOApi;
    using dqm_installer_flt::ErrorOr;
    using dqm_installer_flt::FlutterError;

    class SJisApiImpl : public SJisIOApi {
    public:
        SJisApiImpl() {}
        virtual ~SJisApiImpl() {}

        ErrorOr<std::string> ReadFileWithSJis(const std::string& path) override {
            // open file
            HANDLE hFile = CreateFileW(
                Utf8ToUtf16(path).c_str(),
                GENERIC_READ,
                FILE_SHARE_READ,
                NULL,
                OPEN_EXISTING,
                FILE_ATTRIBUTE_NORMAL,
                NULL
            );
            if (hFile == INVALID_HANDLE_VALUE) {
                return FlutterError("internal", "Failed to open file");
            }

            // get file size
            LARGE_INTEGER fileSize;
            if (!GetFileSizeEx(hFile, &fileSize)) {
                CloseHandle(hFile);
                return FlutterError("internal", "Failed to get file size");
            }

            std::vector<char> buffer(static_cast<size_t>(fileSize.QuadPart));
            DWORD bytesRead = 0;
            if (!ReadFile(hFile, buffer.data(), static_cast<DWORD>(fileSize.QuadPart), &bytesRead, NULL)) {
                CloseHandle(hFile);
                return FlutterError("internal", "Failed to read file");
            }

            CloseHandle(hFile);

            return SJisToUtf8(std::string(buffer.begin(), buffer.end()));
        }

        std::optional<FlutterError> WriteFileWithSJis(const std::string& path, const std::string& data) override {
            // open file
            HANDLE hFile = CreateFileW(
                Utf8ToUtf16(path).c_str(),
                GENERIC_WRITE,
                0,
                NULL,
                CREATE_ALWAYS,
                FILE_ATTRIBUTE_NORMAL,
                NULL
            );
            if (hFile == INVALID_HANDLE_VALUE) {
                return FlutterError("internal", "Failed to open file to write");
            }

            BOOL result = WriteFile(
                hFile,
                Utf8ToSJis(data).c_str(),
                static_cast<DWORD>(data.size()),
                NULL,
                NULL
            );

            CloseHandle(hFile);

            if (!result) {
                return FlutterError("internal", "Failed to write file", GetLastError());
            }

            return std::nullopt; // succeeded
        }

        static std::wstring Utf8ToUtf16(const std::string& input) {
            int wideCharLen = MultiByteToWideChar(CP_UTF8, 0, input.c_str(), -1, (wchar_t*)NULL, 0);

            std::wstring wideStr(wideCharLen, 0);
            MultiByteToWideChar(CP_UTF8, 0, input.c_str(), static_cast<int>(input.size()), &wideStr[0], wideCharLen);

            return wideStr;
        }

        static std::string SJisToUtf8(const std::string& sjisStr) {
            // Step.1: Shift-JIS -> UTF-16
            int wideCharLen = MultiByteToWideChar(CP_ACP, 0, sjisStr.c_str(), static_cast<int>(sjisStr.size()), (wchar_t*)NULL, 0);
            if (wideCharLen == 0) {
                throw std::runtime_error("Failed to convert Shift-JIS to UTF-16");
            }

            std::wstring wideStr(wideCharLen, 0);
            MultiByteToWideChar(CP_ACP, 0, sjisStr.c_str(), static_cast<int>(sjisStr.size()), &wideStr[0], wideCharLen);


            // Step.2: UTF-16 -> UTF-8
            int utf8Len = WideCharToMultiByte(CP_UTF8, 0, wideStr.c_str(), wideCharLen, NULL, 0, NULL, NULL);
            if (utf8Len == 0) {
                throw std::runtime_error("Failed to convert UTF-16 to UTF-8");
            }

            std::string utf8Str(utf8Len, 0);
            WideCharToMultiByte(CP_UTF8, 0, wideStr.c_str(), wideCharLen, &utf8Str[0], utf8Len, NULL, NULL);

            return utf8Str;
        }
        
        static std::string Utf8ToSJis(const std::string& utf8Str) {
            // Step.1: UTF-8 -> UTF-16
            std::wstring wideStr = Utf8ToUtf16(utf8Str);
            int wideCharLen = static_cast<int>(wideStr.size());

            // Step.2: UTF-16 -> Shift-JIS
            int sJisLen = WideCharToMultiByte(CP_ACP, 0, wideStr.c_str(), wideCharLen, NULL, 0, NULL, NULL);
            if (sJisLen == 0) {
                throw std::runtime_error("Failed to convert UTF-16 to UTF-8");
            }

            std::string sJisStr(sJisLen, 0);
            WideCharToMultiByte(CP_ACP, 0, wideStr.c_str(), wideCharLen, &sJisStr[0], sJisLen, NULL, NULL);

            return sJisStr;
        }
    };
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  sJisIOApi_ = std::make_unique<SJisApiImpl>();
  SJisIOApi::SetUp(flutter_controller_->engine()->messenger(), sJisIOApi_.get());

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
