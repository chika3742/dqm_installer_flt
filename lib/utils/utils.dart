import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

String getMinecraftDirectoryPath() {
  if (Platform.isWindows) {
    return "%USERPROFILE%\\AppData\\Roaming\\.minecraft";
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
