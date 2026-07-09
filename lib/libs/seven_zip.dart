import 'dart:developer';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dqm_installer_flt/utils/utils.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;

typedef ProgressCallback = void Function(double progress);

/// Returns the file name of the bundled 7-Zip archive for the current platform.
///
/// The archive is shipped inside the app bundle (see `assets/7z/` in
/// pubspec.yaml).
String getSevenZipAssetName() {
  if (Platform.isWindows) {
    return "7z_windows.zip";
  }
  if (Platform.isMacOS) {
    return "7z_mac.zip";
  }
  if (Platform.isLinux) {
    return "7z_linux.zip";
  }

  throw UnsupportedError("Unsupported platform");
}

Future<void> setupSevenZip() async {
  final tempPath = await getTempPath();
  final assetName = getSevenZipAssetName();
  final zipPath = path.join(tempPath, assetName);

  // Copy the bundled 7-Zip archive out of the app bundle into the temp
  // directory, then reuse the existing extract/chmod pipeline.
  final data = await rootBundle.load("assets/7z/$assetName");
  final file = await File(zipPath).create(recursive: true);
  await file.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );

  await extractFileToDisk(zipPath, tempPath);
  if (Platform.isMacOS || Platform.isLinux) {
    await Process.run("chmod", ["u+x", path.join(tempPath, "7z")]);
  }
}

Future<void> runSevenZip(
  List<String> args, {
  String? workingDirectory,
  String? exePath,
  void Function(String output)? onStdout,
}) async {
  exePath ??= path.join(await getTempPath(), "7z");
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

Future<void> extractArchives(
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

Future<void> addFilesToArchive(
  String archive,
  List<String> targets, {
  ProgressCallback? onProgress,
  String? workingDirectory,
}) async {
  for (var i = 0; i < targets.length; i++) {
    final target = targets[i];
    await addToArchive(archive, target, onProgress: (progress) {
      final overallProgress = (i + progress) / targets.length;
      onProgress?.call(overallProgress);
    });
  }
}

Future<void> deleteFromArchive(String archive, String path) {
  return runSevenZip(
    ["d", archive, path],
  );
}
