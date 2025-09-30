import 'dart:developer';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dqm_installer_flt/libs/installer.dart';
import 'package:dqm_installer_flt/utils/utils.dart';
import 'package:path/path.dart' as path;

typedef ProgressCallback = void Function(double progress);

DownloadableAsset getSevenZipDownloadableAsset() {
  if (Platform.isWindows) {
    return DownloadableAsset(
      url: Uri.parse("https://r2.chikach.net/dqm-assets/7z_windows.zip"),
      size: 623004,
      md5: "97dd07c0b259ecc0dd6e88bc5ff477b4",
    );
  }
  if (Platform.isMacOS) {
    return DownloadableAsset(
      url: Uri.parse("https://r2.chikach.net/dqm-assets/7z_mac.zip"),
      size: 2629603,
      md5: "d3eb38d8ae19398fd2b5fffb704ac418",
    );
  }
  if (Platform.isLinux) {
    return DownloadableAsset(
      url: Uri.parse("https://r2.chikach.net/dqm-assets/7z_linux.zip"),
      size: 1693456,
      md5: "aad773c3dde60811c8c873831cef0bca",
    );
  }

  throw UnsupportedError("Unsupported platform");
}

Future<void> setupSevenZip() async {
  var tempPath = await getTempPath();
  return await extractFileToDisk(
    path.join(
      tempPath,
      getSevenZipDownloadableAsset().url.pathSegments.last,
    ),
    tempPath,
  );
}

Future<void> runSevenZip(
  List<String> args, {
  String? workingDirectory,
  String? exePath,
  void Function(String output)? onStdout,
}) async {
  exePath ??= "${await getTempPath()}/7z${Platform.isWindows ? ".exe" : ""}";
  log("Running: $exePath ${args.join(" ")}", level: 1);
  final process = await Process.start(
    exePath,
    args,
    workingDirectory: workingDirectory,
  );


  await Future.wait([
    process.stdout.listen((event) {
      onStdout?.call(String.fromCharCodes(event));
    }).asFuture(),
    stderr.addStream(process.stderr),
  ]);

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw Exception("7-Zip exited with code $exitCode");
  }
}

Future<void> runSevenZipWithProgress(
  List<String> args, {
  required ProgressCallback onProgress,
  String? workingDirectory,
  String? exePath,
}) {
  return runSevenZip(
    ["-bso0", "-bsp1", ...args],
    workingDirectory: workingDirectory,
    exePath: exePath,
    onStdout: (output) {
      // parse output for progress
      final regex = RegExp(r'(\d+)%');
      final match = regex.firstMatch(output);
      if (match != null) {
        final progress = int.parse(match.group(1)!) / 100.0;
        onProgress(progress);
      }
    },
  );
}

Future<void> extractArchive(
  String archive,
  String destination, {
  ProgressCallback? onProgress,
}) {
  return runSevenZipWithProgress(
    ["x", "-o$destination", "-aoa", archive], // -aoa to overwrite all
    onProgress: (progress) {
      onProgress?.call(progress);
    },
  );
}

Future<void> extractArchivesToSingleDirectory(
  Map<String, String> archives, {
  ProgressCallback? onProgress,
}) async {
  var entries = archives.entries.toList();

  for (var i = 0; i < entries.length; i++) {
    final archive = entries[i].key;
    final destination = entries[i].value;
    await extractArchive(archive, destination, onProgress: (progress) {
      final overallProgress = (i + progress) / archives.length;
      onProgress?.call(overallProgress);
    });
  }
}

Future<void> addToArchive(
  String archive,
  String fileOrDirectory, {
  ProgressCallback? onProgress,
  String? workingDirectory,
}) {
  return runSevenZipWithProgress(
    ["a", archive, fileOrDirectory],
    onProgress: (progress) {
      onProgress?.call(progress);
    },
    workingDirectory: workingDirectory,
  );
}
