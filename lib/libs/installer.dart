import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:dqm_installer_flt/libs/profiles.dart';
import 'package:dqm_installer_flt/utils/utils.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
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
      _DownloadRequiredFiles(this),
      _CopyRequiredFiles(this),
      _ExtractFiles(this),
      _CompressFiles(this),
      _ExtractVanillaSe(this),
      _ExtractLibs(this),
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

class _DownloadRequiredFiles extends Procedure {
  _DownloadRequiredFiles(super.installer);

  @override
  String get procedureTitle => "必要なファイルをダウンロードしています";

  @override
  Future<void> execute() async {
    super.execute();

    final assetsToDownload = [
      ...requiredAssets,
      ...installer.additionalMods.map((e) => e.toFiles()).expand((e) => e),
    ];

    var tempPath = await getTempPath();
    final totalBytes =
        assetsToDownload.fold(0, (value, element) => value + element.size);
    var bytesDownloaded = 0;

    for (var i = 0; i < assetsToDownload.length; i++) {
      final asset = assetsToDownload[i];

      // local file sink
      final file = await File(path.join(
        tempPath,
        path.basename(Uri.decodeComponent(asset.url.path)),
      )).create(recursive: true);
      final fileSink = file.openWrite();

      // http client for downloading
      final client = http.Client();
      final response = await client.send(http.Request("GET", asset.url));

      final completer = Completer();
      response.stream.listen((value) {
        fileSink.add(value);

        // update progress
        bytesDownloaded += value.length;
        progress = bytesDownloaded / totalBytes;
        installer.updateProgress();
      }).onDone(() {
        fileSink.close();
        completer.complete();
      });
      await completer.future;

      // compute file checksum
      final checksum = await file.openRead().transform(md5).first;
      if (checksum.toString().toUpperCase() != asset.md5.toUpperCase()) {
        log("Checksum mismatch! (${checksum.toString().toUpperCase()} vs ${asset.md5.toUpperCase()})");
        throw DqmInstallationException(
            DqmInstallationError.failedToDownloadAsset);
      }
    }
  }
}

class _CopyRequiredFiles extends Procedure {
  _CopyRequiredFiles(super.installer);

  @override
  String get procedureTitle => "必要なファイルをコピーしています。";

  @override
  Future<void> execute() async {
    super.execute();

    final filesToCopy = {
      path.join(getMinecraftDirectoryPath(), "versions", "1.5.2", "1.5.2.jar"):
          path.join(getMinecraftDirectoryPath(), "versions",
              installer.versionName, "${installer.versionName}.jar"),
      installer.bodyModPath: path.join(getMinecraftDirectoryPath(), "mods",
          path.basename(installer.bodyModPath)),
    };

    // add mod files
    for (var e in installer.additionalMods) {
      var modFileName = path.basename(Uri.decodeComponent(e.mod.url.path));
      filesToCopy[path.join(await getTempPath(), modFileName)] = path.join(
        getMinecraftDirectoryPath(),
        "mods",
        modFileName,
      );

      if (e.coreMod != null) {
        final coreModFileName =
            path.basename(Uri.decodeComponent(e.coreMod!.url.path));
        filesToCopy[path.join(await getTempPath(), coreModFileName)] =
            path.join(
          getMinecraftDirectoryPath(),
          "coremods",
          coreModFileName,
        );
      }
    }

    // copy files
    for (var i = 0; i < filesToCopy.length; i++) {
      var entry = filesToCopy.entries.toList()[i];
      await Directory(path.dirname(entry.value)).create(recursive: true);
      await File(entry.key).copy(entry.value);
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
  }
}

class _ExtractFiles extends Procedure {
  _ExtractFiles(super.installer);

  @override
  String get procedureTitle => "前提MODとForgeを展開しています。";

  @override
  Future<void> execute() async {
    super.execute();
    final mcJarPath = path.join(
      getMinecraftDirectoryPath(),
      "versions",
      installer.versionName,
      "${installer.versionName}.jar",
    );

    final mcJarStream = InputFileStream(mcJarPath);
    final preModStream = InputFileStream(installer.prerequisiteModPath);
    final forgeStream = InputFileStream(installer.forgePath);
    final files = [
      ...ZipDecoder().decodeBuffer(mcJarStream).files,
      ...ZipDecoder().decodeBuffer(forgeStream).files,
      ...ZipDecoder().decodeBuffer(preModStream).files,
    ];

    var fileCount = 0;

    for (var file in files) {
      if (file.isFile) {
        final f = await File(path.join(
          await getTempPath(),
          "extracted",
          "jar",
          file.name.replaceAll("/", path.separator),
        )).create(recursive: true);

        final outputStream = OutputFileStream(f.path);
        file.writeContent(outputStream);
        await outputStream.close();
      }
      fileCount++;
      progress = fileCount / files.length;
      installer.updateProgress();
    }
    await mcJarStream.close();
    await forgeStream.close();
    await preModStream.close();

    final accountsData = json.decode(
      await File(await getLauncherAccountsPath()).readAsString(),
    );
    final accounts = accountsData["accounts"] as Map<String, dynamic>;
    final usernames = accounts.values.map((e) => e["minecraftProfile"]["name"]);

    for (var username in usernames) {
      File(installer.skinPath.isNotEmpty
              ? installer.skinPath
              : path.join(
                  await getTempPath(),
                  "steve.png",
                ))
          .copy(path.join(
        await getTempPath(),
        "extracted",
        "jar",
        "mob",
        "$username.png",
      ));
    }
  }
}

class _CompressFiles extends Procedure {
  _CompressFiles(super.installer);

  @override
  String get procedureTitle => "Minecraft実行ファイルを作成しています";

  @override
  Future<void> execute() async {
    super.execute();

    await Directory(path.join(
      await getTempPath(),
      "extracted",
      "jar",
      "META-INF",
    )).delete(recursive: true);

    final encoder = ZipFileEncoder();
    final dir = Directory(path.join(
      await getTempPath(),
      "extracted",
      "jar",
    ));

    encoder.create(path.join(
      getMinecraftDirectoryPath(),
      "versions",
      installer.versionName,
      "${installer.versionName}.jar",
    ));
    await encoder.addDirectory(dir, includeDirName: false, level: 1);
    encoder.close();

    progress = 1;
    installer.updateProgress();
  }
}

class _ExtractVanillaSe extends Procedure {
  _ExtractVanillaSe(super.installer);

  @override
  String get procedureTitle => "BGM/SEを展開しています。";

  @override
  Future<void> execute() async {
    super.execute();
    final decoder = ZipDecoder();

    final vanillaSeStream =
        InputFileStream(path.join(await getTempPath(), "resources.zip"));

    final bgmStream = InputFileStream(installer.bgmPath);

    final files = [
      ...decoder.decodeBuffer(vanillaSeStream).files,
      ...decoder.decodeBuffer(bgmStream).files,
    ];

    var fileCount = 0;

    for (var file in files) {
      if (file.isFile) {
        final outputStream = OutputFileStream(path.join(
          getMinecraftDirectoryPath(),
          file.name,
        ));
        file.writeContent(outputStream);
        await outputStream.close();
      }
      fileCount++;
      progress = fileCount / files.length;
      installer.updateProgress();
    }
    await vanillaSeStream.close();
    await bgmStream.close();
  }
}

class _ExtractLibs extends Procedure {
  _ExtractLibs(super.installer);

  @override
  String get procedureTitle => "libファイルを展開しています。";

  @override
  Future<void> execute() async {
    super.execute();
    final decoder = ZipDecoder();

    final libStream =
        InputFileStream(path.join(await getTempPath(), "fml_libs15.zip"));

    var fileCount = 0;

    var files = decoder.decodeBuffer(libStream).files;
    for (var file in files) {
      if (file.isFile) {
        final outputStream = OutputFileStream(path.join(
          getMinecraftDirectoryPath(),
          "lib",
          file.name,
        ));
        file.writeContent(outputStream);
        await outputStream.close();
      }
      fileCount++;
      progress = fileCount / files.length;
      installer.updateProgress();
    }
    await libStream.close();

    await File(path.join(
      await getTempPath(),
      "deobfuscation_data_1.5.2.zip",
    )).copy(path.join(
        getMinecraftDirectoryPath(), "lib", "deobfuscation_data_1.5.2.zip"));
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

class DownloadableAsset {
  final Uri url;
  final int size;
  final String md5;

  const DownloadableAsset({
    required this.url,
    required this.size,
    required this.md5,
  });
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
