import 'dart:io';

import 'package:dqm_installer_flt/utils/utils.dart';
import 'package:path/path.dart' as path;

Future<bool> checkAllModFilesExist(List<String> paths, String skinPath) async {
  return (await Future.wait(paths.map((e) => File(e).exists()).toList()))
      .any((e) => !e)
      || (skinPath.isNotEmpty && !await File(skinPath).exists());
}

Future<bool> check152JarExists() {
  return File(path.join(
          getMinecraftDirectoryPath(), "versions", "1.5.2", "1.5.2.jar"))
      .exists();
}

Future<bool> isDqmAlreadyInstalled(String versionName) {
  return Directory(path.join(
    getMinecraftDirectoryPath(),
    "versions",
    versionName,
  )).exists();
}

Future<void> deleteInstalledDqmVersion(String versionName) {
  return Directory(path.join(
    getMinecraftDirectoryPath(),
    "versions",
    versionName,
  )).delete(recursive: true);
}
