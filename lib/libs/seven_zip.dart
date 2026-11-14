import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart' as path;

typedef ProgressCallback = void Function(double progress);

/// Returns the path to the bundled 7-Zip executable for the current platform.
String getSevenZipExecutablePath() {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  if (Platform.isWindows) {
    return path.join(exeDir, "data", "flutter_assets", "assets", "7z", "windows", "7za.exe");
  }
  if (Platform.isMacOS) {
    return path.join(exeDir, "..", "Frameworks", "App.framework", "Resources", "flutter_assets", "assets", "7z", "macos", "7zz");
  }
  if (Platform.isLinux) {
    return path.join(exeDir, "data", "flutter_assets", "assets", "7z", "linux", "7zz");
  }

  throw UnsupportedError("Unsupported platform");
}

Future<void> runSevenZip(
  List<String> args, {
  String? workingDirectory,
  void Function(String output)? onStdout,
}) async {
  final exePath = getSevenZipExecutablePath();
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
}) {
  return runSevenZip(
    ["-bso0", "-bsp1", ...args],
    workingDirectory: workingDirectory,
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
