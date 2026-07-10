import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dqm_installer_flt/libs/profiles.dart';
import 'package:dqm_installer_flt/libs/seven_zip.dart';
import 'package:dqm_installer_flt/utils/utils.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;

import '../data.dart';
import '../utils/precondition.dart';

class Installer {
  List<Procedure> procedure = [];
  ProgressInfo progress = ProgressInfo();
  Procedure? currentProcedure;

  void Function(ProgressInfo info)? onProgressChanged;

  ///
  /// Initialized after [parseDqmFileName] is called.
  ///
  late DqmType dqmType;

  ///
  /// Initialized after [parseDqmFileName] is called.
  ///
  late String dqmVersion;

  ///
  /// Initialized after [parseDqmFileName] is called.
  ///
  late String versionName;

  final String prerequisiteModPath;
  final String bodyModPath;
  final String bgmPath;
  final String forgePath;
  final String skinPath;
  final List<AdditionalMod> additionalMods;

  Installer({
    this.onProgressChanged,
    required this.prerequisiteModPath,
    required this.bodyModPath,
    required this.bgmPath,
    required this.forgePath,
    required this.skinPath,
    required this.additionalMods,
  }) {
    procedure = [
      _CopyRequiredFiles(this),
      _ExtractFiles(this),
      _CompressFiles(this),
      _ExtractVanillaSe(this),
      _CreateDqmProfile(this),
      _Cleanup(this),
    ];

    final modFileName = path.basename(bodyModPath);
    dqmType = parseDqmType(modFileName);
    dqmVersion = parseDqmVersion(modFileName);
    versionName = toVersionName(dqmType, dqmVersion);
  }

  void updateProgress() {
    assert(currentProcedure != null);
    progress.currentProcedureProgress = currentProcedure!.progress;
    progress.overallProgress = (procedure.indexOf(currentProcedure!) +
            progress.currentProcedureProgress) /
        procedure.length;
    progress.currentProcedureTitle = currentProcedure!.procedureTitle;
    onProgressChanged?.call(progress);
  }

  Future<void> install() async {
    await deleteInstalledDqmVersion(versionName);

    for (var item in procedure) {
      await item.execute();
    }
  }

  static DqmType parseDqmType(String fileName) {
    if (fileName.contains("DQMIV")) {
      return DqmType.dqm4;
    } else if (fileName.contains("DQMV")) {
      return DqmType.dqm5;
    } else if (fileName.contains("不思議の")) {
      return DqmType.dqmDungeon;
    } else {
      throw DqmInstallationException(DqmInstallationError.failedToParseDqmType);
    }
  }

  static String parseDqmVersion(String fileName) {
    final match = RegExp("Ver\\.*(\\d+\\.\\d+)").firstMatch(fileName);
    if (match == null || match.group(1) == null) {
      throw DqmInstallationException(DqmInstallationError.failedToParseDqmType);
    }
    return match.group(1)!;
  }

  static String toVersionName(DqmType dqmType, String dqmVersion) {
    return "${dqmType.toNameString()} v$dqmVersion";
  }
}

abstract class Procedure {
  final Installer installer;

  String get procedureTitle;

  double progress = 0;

  Procedure(this.installer);

  Future<void> execute() async {
    installer.currentProcedure = this;
    installer.updateProgress();
  }
}

typedef FileToCopy = ({ String from, String to, bool isAsset });

class _CopyRequiredFiles extends Procedure {
  _CopyRequiredFiles(super.installer);

  @override
  String get procedureTitle => "必要なファイルをコピーしています。";

  @override
  Future<void> execute() async {
    super.execute();

    final List<FileToCopy> filesToCopy = [
      (
        from: path.join(getMinecraftDirectoryPath(), "versions", "1.5.2", "1.5.2.jar"),
        to: path.join(getMinecraftDirectoryPath(), "versions",
            installer.versionName, "${installer.versionName}.zip"),
        isAsset: false,
      ),
      (
        from: installer.bodyModPath,
        to: path.join(getMinecraftDirectoryPath(), "mods",
            path.basename(installer.bodyModPath)),
        isAsset: false,
      ),
    ];

    // add mod files
    for (var e in installer.additionalMods) {
      var modFileName = path.basename(e.mod);
      filesToCopy.add((
        from: e.mod,
        to: path.join(getMinecraftDirectoryPath(), "mods", modFileName),
        isAsset: true,
      ));

      if (e.coreMod case final coreMod?) {
        final coreModFileName = path.basename(coreMod);
        filesToCopy.add((
          from: coreMod,
          to: path.join(getMinecraftDirectoryPath(), "coremods", coreModFileName),
          isAsset: true
        ));
      }
    }

    // copy files
    for (var i = 0; i < filesToCopy.length; i++) {
      var entry = filesToCopy[i];
      await Directory(path.dirname(entry.to)).create(recursive: true);
      if (entry.isAsset) {
        await copyAssetToPath(entry.from, entry.to);
      } else {
        await File(entry.from).copy(entry.to);
      }

      progress = (i + 1) / filesToCopy.length;
      installer.updateProgress();
    }

    // write [versionName].json
    var decoded = json.decode(await rootBundle.loadString("assets/dqm4.json"));
    decoded["id"] = installer.versionName;
    await File(path.join(
      getMinecraftDirectoryPath(),
      "versions",
      installer.versionName,
      "${installer.versionName}.json",
    )).writeAsString(const JsonEncoder.withIndent("  ").convert(decoded));

    // write legacy.json
    await File(path.join(
      getMinecraftDirectoryPath(),
      "assets",
      "indexes",
      "legacy.json",
    )).writeAsString(
      await rootBundle.loadString("assets/legacy.json"),
    );

    await Directory(path.join(getMinecraftDirectoryPath(), "lib"))
        .create(recursive: true);
    // deobfuscation_data_1.5.2.zip
    await copyAssetToPath(
      "assets/resources/deobfuscation_data_1.5.2.zip",
      path.join(getMinecraftDirectoryPath(), "lib", "deobfuscation_data_1.5.2.zip"),
    );
  }
}

class _ExtractFiles extends Procedure {
  _ExtractFiles(super.installer);

  @override
  String get procedureTitle => "前提MODとForgeを展開しています。";

  @override
  Future<void> execute() async {
    super.execute();

    await setupSevenZip();

    final extracts = {
      installer.prerequisiteModPath: path.join(
        await getTempPath(),
        "extracted",
        "prerequisite",
      ),
      installer.forgePath: path.join(
        await getTempPath(),
        "extracted",
        "forge",
      ),
    };

    await extractArchives(
      extracts,
      onProgress: (progress) {
        this.progress = progress;
        installer.updateProgress();
      },
    );
  }
}

class _CompressFiles extends Procedure {
  _CompressFiles(super.installer);

  @override
  String get procedureTitle => "Minecraft実行ファイルを作成しています";

  @override
  Future<void> execute() async {
    super.execute();

    var execJarPath = path.join(
      getMinecraftDirectoryPath(),
      "versions",
      installer.versionName,
      "${installer.versionName}.zip",
    );
    await addFilesToArchive(
      execJarPath,
      [
        path.join(
          await getTempPath(),
          "extracted",
          "forge",
          "*",
        ),
        path.join(
          await getTempPath(),
          "extracted",
          "prerequisite",
          "*",
        ),
      ],
      onProgress: (progress) {
        this.progress = progress;
        installer.updateProgress();
      },
    );

    await deleteFromArchive(execJarPath, "META-INF");

    // Add default skins
    final accountsData = json.decode(
      await File(await getLauncherAccountsPath()).readAsString(),
    );
    final accounts = accountsData["accounts"] as Map<String, dynamic>;
    final usernames = accounts.values.map((e) => e["minecraftProfile"]["name"]);
    await Directory(path.join(
      await getTempPath(),
      "extracted",
      "jar",
      "mob",
    )).create(recursive: true);

    for (var username in usernames) {
      await copyAssetToPath("assets/resources/steve.png", path.join(
        await getTempPath(),
        "extracted",
        "jar",
        "mob",
        "$username.png",
      ));
    }
    await addToArchive(execJarPath, path.join(
      await getTempPath(),
      "extracted",
      "jar",
      "*",
    ));

    // change extension from zip to jar
    await File(execJarPath).rename(path.setExtension(execJarPath, ".jar"));

    progress = 1;
    installer.updateProgress();
  }
}

class _ExtractVanillaSe extends Procedure {
  _ExtractVanillaSe(super.installer);

  @override
  String get procedureTitle => "必要なファイルを展開しています。";

  @override
  Future<void> execute() async {
    super.execute();

    final resourcesTmpPath = path.join(await getTempPath(), "resources.zip");
    final fmlLibsTmpPath = path.join(await getTempPath(), "fml_libs15.zip");

    await copyAssetToPath("assets/resources/resources.zip", resourcesTmpPath);
    await copyAssetToPath("assets/resources/fml_libs15.zip", fmlLibsTmpPath);

    final minecraftDir = getMinecraftDirectoryPath();
    final extracts = {
      resourcesTmpPath: minecraftDir, // vanilla SE
      installer.bgmPath: minecraftDir, // DQM BGM
      fmlLibsTmpPath: path.join(minecraftDir, "lib"), // FML libs
    };

    await extractArchives(
      extracts,
      onProgress: (progress) {
        this.progress = progress;
        installer.updateProgress();
      },
    );
  }
}

class _CreateDqmProfile extends Procedure {
  _CreateDqmProfile(super.installer);

  @override
  String get procedureTitle => "DQMプロファイルを作成しています。";

  @override
  Future<void> execute() async {
    super.execute();

    final profileData = await MinecraftProfile().parse();
    profileData["profiles"][installer.dqmType.toNameString()] =
        MinecraftProfileEntry(
      created: DateTime.now().toIso8601String(),
      icon: "Carved_Pumpkin",
      lastVersionId: installer.versionName,
      name: installer.versionName,
      type: "custom",
    ).toMap();
    await MinecraftProfile().save(profileData);

    // Fix options.txt
    var optionsFile = File(path.join(
      getMinecraftDirectoryPath(),
      "options.txt",
    ));
    if (await optionsFile.exists()) {
      String optionsTxt = await readFileWithPlatformEncoding(optionsFile.path);
      optionsTxt = optionsTxt.replaceFirst(RegExp("lang:.*"), "lang:ja_JP");
      await writeFileWithPlatformEncoding(optionsFile.path, optionsTxt);
    }

    progress = 1;
    installer.updateProgress();
  }
}

class _Cleanup extends Procedure {
  _Cleanup(super.installer);

  @override
  String get procedureTitle => "クリーンアップしています。";

  @override
  Future<void> execute() async {
    super.execute();

    await Directory(await getTempPath()).delete(recursive: true);

    progress = 1;
    installer.updateProgress();
  }
}

class ProgressInfo {
  double overallProgress = 0;
  double currentProcedureProgress = 0;
  String currentProcedureTitle = "";
}

enum DqmInstallationError {
  failedToParseDqmType,
  failedToDownloadAsset,
}

enum DqmType {
  dqm5,
  dqm4,
  dqmDungeon,
}

extension DqmTypeExt on DqmType {
  String toNameString() {
    switch (this) {
      case DqmType.dqm5:
        return "DQMV";
      case DqmType.dqm4:
        return "DQMIV";
      case DqmType.dqmDungeon:
        return "DQM in 不思議のダンジョン";
    }
  }
}

class DqmInstallationException implements Exception {
  final DqmInstallationError code;

  DqmInstallationException(this.code);

  @override
  String toString() {
    return "Installation process failed (${code.name})";
  }
}
