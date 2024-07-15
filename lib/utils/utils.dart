import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

String getMinecraftDirectoryPath() {
  if (Platform.isWindows) {
    return path.join(Platform.environment["APPDATA"]!, ".minecraft");
  }
  if (Platform.isMacOS) {
    return path.join(
        Platform.environment["HOME"]!, "Library/Application Support/minecraft");
  }
  if (Platform.isLinux) {
    return path.join(Platform.environment["HOME"]!, ".minecraft");
  }
  throw UnsupportedError("Unsupported Platform");
}

Future<String> getLauncherAccountsPath() async {
  if (Platform.isWindows) {
    final microsoftStorePath = path.join(
        getMinecraftDirectoryPath(), "launcher_accounts_microsoft_store.json");
    if (await File(microsoftStorePath).exists()) {
      return microsoftStorePath;
    }
  }
  return path.join(getMinecraftDirectoryPath(), "launcher_accounts.json");
}

Future<String> getTempPath() async {
  var p = path.join(
      (await getTemporaryDirectory()).path, "net.chikach.dqmInstallerFlt");
  if (Platform.isWindows) {
    p = r"\\?\" + p;
  }
  return p;
}

void showSnackBar(BuildContext context, String message,
    {Color? color, Duration duration = const Duration(seconds: 4)}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    backgroundColor: color,
    duration: duration,
  ));
}

void showErrorSnackBar(BuildContext context, String message) {
  showSnackBar(context, message,
      color: Colors.red, duration: const Duration(seconds: 8));
}

void saveErrorToFile(Object e, StackTrace? st) {
  // save error to file
  File(path.join(path.dirname(Platform.resolvedExecutable),
          "error_${DateTime.now().toString().replaceAll(RegExp(":| "), "_")}.txt"))
      .writeAsStringSync("${e.toString()}\n${st.toString()}");
}
