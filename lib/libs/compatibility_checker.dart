import 'dart:io';

import 'package:dqm_installer_flt/libs/profiles.dart';
import 'package:dqm_installer_flt/utils/utils.dart';
import 'package:path/path.dart';

class CompatibilityChecker {
  bool profileFileExists = false;
  List<String> incompatibleProfiles = [];
  List<String> directoriesNotEmpty = [];

  bool get hasError => errorMessage.isNotEmpty;

  static const _directoriesToCheck = [
    "mods",
    "coremods",
    "saves",
  ];

  String get errorMessage {
    var builder = StringBuffer();

    if (!profileFileExists) {
      builder.writeln("プロファイルデータが見つかりません。ランチャーを1度起動してください。");
    }
    if (incompatibleProfiles.isNotEmpty) {
      builder.writeln(
          "以下のプロファイルにゲームディレクトリが設定されていません。: ${incompatibleProfiles.join(", ")}");
    }
    if (directoriesNotEmpty.isNotEmpty) {
      builder.writeln(
          "以下のフォルダーが空ではありません。必要なファイルが入っている場合はバックアップを取ってください。: ${directoriesNotEmpty.join(", ")}");
    }

    return builder.toString().trim();
  }

  Future<void> check() async {
    await _checkProfileFileExists();
    await _checkGameDir();
    await _checkIfDirectoriesEmpty();
  }

  Future<void> _checkProfileFileExists() async {
    profileFileExists = await MinecraftProfile().profileFile.exists();
  }

  Future<void> _checkGameDir() async {
    incompatibleProfiles.clear();

    var profile = MinecraftProfile();
    var parsedData = await profile.parse();
    for (var entryMap
        in (parsedData["profiles"] as Map<String, dynamic>).entries) {
      var entry = MinecraftProfileEntry.fromMap(entryMap.value);
      if (entry.type == "latest-snapshot") {
        if (parsedData["settings"]["enableSnapshots"] &&
            entry.gameDir == null) {
          incompatibleProfiles.add("最新のスナップショット");
        }
      } else if (entry.gameDir == null) {
        var split = entry.lastVersionId.split(".");
        if (split.length >= 2 && int.parse(split[1]) < 6) {
          continue;
        }
        incompatibleProfiles
            .add(entry.name.isNotEmpty ? entry.name : "最新のリリース");
      }
    }
  }

  Future<void> _checkIfDirectoriesEmpty() async {
    directoriesNotEmpty.clear();

    for (var dirName in _directoriesToCheck) {
      var directory = Directory(join(getMinecraftDirectoryPath(), dirName));
      if (!await directory.exists()) {
        continue;
      }
      var length = await directory
          .list()
          .where((event) => basename(event.path) != ".DS_Store")
          .length;
      if (length >= 1) {
        directoriesNotEmpty.add(dirName);
      }
    }
  }
}
