import 'dart:io';

import 'package:dqm_installer_flt/libs/profiles.dart';
import 'package:dqm_installer_flt/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

class CompatibilityChecker {
  bool profileFileExists = false;
  List<String> incompatibleProfiles = [];
  List<String> directoriesNotEmpty = [];
  bool failedToCheck = false;
  String checkErrorMessage = "";

  bool get hasError => errorMessage.isNotEmpty;

  static const _directoriesToCheck = [
    "mods",
    "coremods",
    "saves",
  ];

  List<Widget> get errorMessage {
    final texts = <Widget>[];

    if (!profileFileExists) {
      texts.add(const Text("プロファイルデータが見つかりません。ランチャーを1度起動してください。"));
    }
    if (incompatibleProfiles.isNotEmpty) {
      texts.add(Text.rich(TextSpan(
        children: [
          const TextSpan(text: "起動構成"),
          for (var profile in incompatibleProfiles)
            TextSpan(
              children: [
                const TextSpan(text: "「"),
                TextSpan(
                    text: profile,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: "」"),
              ],
            ),
          const TextSpan(text: "にゲームディレクトリを設定してください。"),
        ],
      )));
    }
    if (directoriesNotEmpty.isNotEmpty) {
      texts.add(Text.rich(TextSpan(
        children: [
          const TextSpan(text: ".minecraftフォルダー内のフォルダー"),
          for (var dir in directoriesNotEmpty)
            TextSpan(
              children: [
                const TextSpan(text: "「"),
                TextSpan(
                    text: dir,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: "」"),
              ],
            ),
          const TextSpan(text: "を空にしてください。必要なファイルが入っている場合はバックアップを取ってください。"),
        ],
      )));
    }
    if (failedToCheck) {
      texts.add(Text("チェックに失敗しました: $checkErrorMessage"));
    }

    return texts;
  }

  Future<void> check() async {
    try {
      await _checkProfileFileExists();
      await _checkGameDir();
      await _checkIfDirectoriesEmpty();
    } catch (e, st) {
      failedToCheck = true;
      checkErrorMessage = e.toString();
      saveErrorToFile(e, st);
    }
  }

  Future<void> _checkProfileFileExists() async {
    profileFileExists = await MinecraftProfile().profileFile.exists();
  }

  Future<void> _checkGameDir() async {
    if (!profileFileExists) {
      return;
    }

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
        if (split.length >= 2 && int.parse(split[1]) < 6 || entry.lastVersionId.contains("DQM")) {
          continue;
        }
        incompatibleProfiles.add(entry.type == "latest-release"
            ? "最新のリリース"
            : entry.name.isEmpty
                ? "無題"
                : "${entry.name} (${entry.lastVersionId})");
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
