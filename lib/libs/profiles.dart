import 'dart:convert';
import 'dart:io';

import 'package:dqm_installer_flt/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class MinecraftProfile {
  final profileFile =
      File(path.join(getMinecraftDirectoryPath(), "launcher_profiles.json"));

  Future<Map<String, dynamic>> parse() {
    return profileFile.readAsString().then((data) {
      return json.decode(data);
    });
  }

  Future<void> save(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent("  ");
    return profileFile.writeAsString(encoder.convert(data));
  }

  Future<void> create152Profile() async {
    final meta = json.decode(
        (await http.get(Uri.parse(
            "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"
        ))).body
    );
    final metaUrl = (meta["versions"] as List<dynamic>).firstWhere((e) => e["id"] == "1.5.2")["url"];

    await File(path.join(
      getMinecraftDirectoryPath(),
      "versions", "1.5.2", "1.5.2.json",
    )).create(recursive: true).then((file) async {
      return file.writeAsString((await http.get(Uri.parse(metaUrl))).body);
    });

    var parsedData = await parse();
    parsedData["profiles"]["1.5.2"] = MinecraftProfileEntry(
      created: DateTime.now().toIso8601String(),
      icon: "Furnace",
      lastVersionId: "1.5.2",
      name: "1.5.2",
      type: "custom",
    ).toMap();
    await save(parsedData);
  }
}

class MinecraftProfileEntry {
  final String? created;
  final String? icon;
  final String lastVersionId;
  final String name;
  final String type;
  final String? gameDir;

  const MinecraftProfileEntry({
    required this.created,
    required this.icon,
    required this.lastVersionId,
    required this.name,
    required this.type,
    this.gameDir,
  });

  MinecraftProfileEntry.fromMap(Map<String, dynamic> map)
      : created = map["created"],
        icon = map["icon"],
        lastVersionId = map["lastVersionId"],
        name = map["name"],
        type = map["type"],
        gameDir = map["gameDir"];

  Map<String, dynamic> toMap() {
    return {
      "created": created,
      "icon": icon,
      "lastVersionId": lastVersionId,
      "name": name,
      "type": type,
      "gameDir": gameDir,
    };
  }
}
