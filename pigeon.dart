// generate with `dart run pigeon --input ./pigeon.dart`

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: "lib/messages.dart",
  cppOptions: CppOptions(namespace: "dqm_installer_flt"),
  cppHeaderOut: "windows/runner/messages.g.h",
  cppSourceOut: "windows/runner/messages.g.cpp",
))
@HostApi()
abstract class SJisIOApi {
  /// Reads a file from the specified [path] and decodes from Shift-JIS.
  /// Supported on Windows only.
  String readFileWithSJis(String path);

  /// Encodes the [data] string to Shift-JIS and writes it to the specified
  /// [path]. Supported on Windows only.
  void writeFileWithSJis(String path, String data);
}
