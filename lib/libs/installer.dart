import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dqm_installer_flt/libs/profiles.dart';
import 'package:dqm_installer_flt/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class Installer {
  List<Procedure> procedure = [];
  ProgressInfo progress = ProgressInfo();
  Procedure? currentProcedure;

  void Function(ProgressInfo info)? onProgressChanged;
  late DqmType type;
  late String dqmVersion;
  late String versionName;
  final String prerequisiteModPath;
  final String bodyModPath;
  final String bgmPath;
  final String forgePath;
  final String skinPath;

  Installer({
    this.onProgressChanged,
    required this.prerequisiteModPath,
    required this.bodyModPath,
    required this.bgmPath,
    required this.forgePath,
    required this.skinPath,
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
    _parseDqmType();
    _parseDqmVersion();

    for (var item in procedure) {
      await item.execute();
    }
  }

  void _parseDqmType() {
    var modFileName = path.basename(bodyModPath);
    if (modFileName.contains("DQMIV")) {
      type = DqmType.dqm4;
    } else if (modFileName.contains("DQMV")) {
      type = DqmType.dqm5;
    } else if (modFileName.contains("不思議の")) {
      type = DqmType.dqmDungeon;
    } else {
      throw DqmInstallationException(DqmInstallationError.failedToParseDqmType);
    }
  }

  void _parseDqmVersion() {
    var modFileName = path.basename(bodyModPath);
    final match = RegExp("Ver\\.*(\\d+\\.\\d+)").firstMatch(modFileName);
    if (match == null || match.group(1) == null) {
      throw DqmInstallationException(DqmInstallationError.failedToParseDqmType);
    }
    dqmVersion = match.group(1)!;

    versionName = "${type.toNameString()} v$dqmVersion";
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
  _DownloadRequiredFiles(Installer installer) : super(installer);

  @override
  String get procedureTitle => "必要なファイルをダウンロードしています";

  final List<DownloadableAsset> assetsToDownload = [
    DownloadableAsset(
        Uri.parse("https://r2.chikach.net/dqm-assets/dqm4.json"), 0),
    DownloadableAsset(
        Uri.parse("https://r2.chikach.net/dqm-assets/legacy.json"), 0),
    DownloadableAsset(
        Uri.parse("https://r2.chikach.net/dqm-assets/steve.png"), 1284),
    DownloadableAsset(
        Uri.parse(
            "https://r2.chikach.net/dqm-assets/deobfuscation_data_1.5.2.zip"),
        201404),
    DownloadableAsset(
        Uri.parse("https://r2.chikach.net/dqm-assets/fml_libs15.zip"),
        10545276),
    DownloadableAsset(
        Uri.parse("https://r2.chikach.net/dqm-assets/resources.zip"), 46833816),
  ];

  @override
  Future<void> execute() async {
    super.execute();

    var tempPath = await getTempPath();
    final totalBytes = assetsToDownload.fold(
        0, (value, element) => value + element.contentLength);
    var bytesDownloaded = 0;

    for (var i = 0; i < assetsToDownload.length; i++) {
      final asset = assetsToDownload[i];

      // local file sink
      final file = await File(path.join(
        tempPath,
        path.basename(asset.url.path),
      )).create(recursive: true);
      final fileSink = file.openWrite();

      // http client for downloading
      final client = http.Client();
      final response = await client.send(http.Request("GET", asset.url));

      final completer = Completer();
      response.stream.listen((value) {
        fileSink.add(value);

        // update progress
        if (asset.contentLength != 0) {
          bytesDownloaded += value.length;
        }
        progress = bytesDownloaded / totalBytes;
        installer.updateProgress();
      }).onDone(() {
        fileSink.close();
        completer.complete();
      });

      await completer.future;
    }
  }
}

class _CopyRequiredFiles extends Procedure {
  _CopyRequiredFiles(Installer installer) : super(installer);

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
      path.join(await getTempPath(), "legacy.json"): path.join(
          getMinecraftDirectoryPath(), "assets", "indexes", "legacy.json"),
    };

    // copy files
    for (var i = 0; i < filesToCopy.length; i++) {
      var entry = filesToCopy.entries.toList()[i];
      await Directory(path.dirname(entry.value)).create(recursive: true);
      await File(entry.key).copy(entry.value);
      progress = (i + 1) / filesToCopy.length;
      installer.updateProgress();
    }

    // save version json
    var dqmJsonFile = File(path.join(await getTempPath(), "dqm4.json"));
    var decoded = json.decode(await dqmJsonFile.readAsString());
    decoded["id"] = installer.versionName;
    await File(path.join(
      getMinecraftDirectoryPath(),
      "versions",
      installer.versionName,
      "${installer.versionName}.json",
    )).writeAsString(const JsonEncoder.withIndent("  ").convert(decoded));
  }
}

class _ExtractFiles extends Procedure {
  _ExtractFiles(Installer installer) : super(installer);

  @override
  String get procedureTitle => "前提MODとForgeを展開しています。";

  @override
  Future<void> execute() async {
    super.execute();
    final decoder = ZipDecoder();
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
      ...decoder.decodeBuffer(mcJarStream).files,
      ...decoder.decodeBuffer(forgeStream).files,
      ...decoder.decodeBuffer(preModStream).files,
    ];

    var fileCount = 0;

    for (var file in files) {
      if (file.isFile) {
        final outputStream = OutputFileStream(path.join(
          await getTempPath(),
          "extracted",
          "jar",
          file.name,
        ));
        file.writeContent(outputStream);
        await outputStream.close();
      }
      fileCount++;
      progress = fileCount / files.length;
      installer.updateProgress();
    }
    await preModStream.close();
    await forgeStream.close();
    await preModStream.close();

    final accountsData = json.decode(await File(path.join(
      getMinecraftDirectoryPath(),
      "launcher_accounts.json",
    )).readAsString());
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
  _CompressFiles(Installer installer) : super(installer);

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
  _ExtractVanillaSe(Installer installer) : super(installer);

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
  _ExtractLibs(Installer installer) : super(installer);

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
  _CreateDqmProfile(Installer installer) : super(installer);

  @override
  String get procedureTitle => "DQMプロファイルを作成しています。";

  @override
  Future<void> execute() async {
    super.execute();

    final profileData = await MinecraftProfile().parse();
    profileData["profiles"][installer.type.toNameString()] =
        MinecraftProfileEntry(
      created: DateTime.now().toIso8601String(),
      icon: "Carved_Pumpkin",
      lastVersionId: installer.versionName,
      name: installer.versionName,
      type: "custom",
    ).toMap();
    await MinecraftProfile().save(profileData);

    progress = 1;
    installer.updateProgress();
  }
}

class _Cleanup extends Procedure {
  _Cleanup(Installer installer) : super(installer);

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
  final int contentLength;

  const DownloadableAsset(this.url, this.contentLength);
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
