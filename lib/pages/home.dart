import 'dart:async';
import 'dart:io';

import 'package:dqm_installer_flt/libs/compatibility_checker.dart';
import 'package:dqm_installer_flt/libs/installer.dart';
import 'package:dqm_installer_flt/libs/profiles.dart';
import 'package:dqm_installer_flt/pages/installation_progress.dart';
import 'package:dqm_installer_flt/utils/precondition.dart';
import 'package:dqm_installer_flt/utils/ui.dart';
import 'package:dqm_installer_flt/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:timelines/timelines.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../data.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const routeName = "/";

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool creating152Profile = false;
  CompatibilityChecker checker = CompatibilityChecker();
  final _files = <String, LoadableFile>{
    "pre": LoadableFile(
      title: "DQM 前提MOD",
      pickerAllowedExtensions: ["zip", "jar"],
    ),
    "body": LoadableFile(
      title: "DQM 本体MOD",
      pickerAllowedExtensions: ["zip", "jar"],
    ),
    "sound": LoadableFile(
      title: "DQM 音声・BGM",
      pickerAllowedExtensions: ["zip", "jar"],
    ),
    "forge": LoadableFile(
      title: "Forge",
      pickerAllowedExtensions: ["zip", "jar"],
    ),
    "skin": LoadableFile(
      title: "スキン",
      formFieldHint: "デフォルト（Steve）",
      optional: true,
      pickerAllowedExtensions: ["png"],
    ),
  };
  final _additionalMods = <AdditionalMod>[];

  final _scrollController = ScrollController();
  bool _showBlur = true;

  @override
  void initState() {
    super.initState();
    checkWhetherCanBeInstalled();
    _scrollController.addListener(() {
      final showBlur = _scrollController.position.pixels <
          _scrollController.position.maxScrollExtent;
      if (showBlur != _showBlur) {
        setState(() {
          _showBlur = showBlur;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DQM Installer"),
      ),
      body: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.05),
            ],
            stops: [_showBlur ? 0.9 : 1, 1],
          ).createShader(bounds);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _FlowTimeline([
              _InstallationFlow(
                "インストール可能な環境かチェックする",
                contents: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (checker.hasError)
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 4),
                          Text("インストール前に準備が必要です",
                              style: TextStyle(color: Colors.red)),
                        ],
                      )
                    else
                      const Row(
                        children: [
                          Icon(Icons.check, color: Colors.green, size: 20),
                          SizedBox(width: 4),
                          Text("インストール可能です。"),
                        ],
                      ),
                    if (checker.hasError)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final error in checker.errorMessage)
                              Card(
                                color: Colors.red.shade100,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  child: error,
                                ),
                              )
                          ],
                        ),
                      ),
                    if (checker.hasError)
                      const Text("これらのエラーは無視することもできますが、動作は保証しません。"),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              checkWhetherCanBeInstalled();
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.refresh),
                                SizedBox(width: 8),
                                Text("再チェックする"),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              launchUrl(
                                  Directory(getMinecraftDirectoryPath()).uri);
                            },
                            child: const Text(".minecraftフォルダーを開く"),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              if (Platform.isMacOS)
                _InstallationFlow(
                  "macOSにおける表示問題について",
                  contents: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Apple M1シリーズ (M2以降も含む) のMacをお使いの場合、"
                          "Minecraft 1.5.2におけるゲーム画面が正常に表示されません。\n"
                          "必ず以下のページをご覧になってからインストールを進めてください。"),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          launchUrlString(
                              "https://github.com/chika3742/dqm_installer_flt?tab=readme-ov-file#apple-silicon-mac%E3%81%A7%E3%81%AE%E8%A1%A8%E7%A4%BA%E3%81%AE%E4%BF%AE%E6%AD%A3");
                        },
                        child: const Text("Apple Silicon Macでの表示の修正について"),
                      )
                    ],
                  ),
                ),
              _InstallationFlow(
                "Minecraft 1.5.2を起動するプロファイルを作成する",
                contents: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "下のボタンをクリックして Minecraft 1.5.2 のプロファイルを作成します。",
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed:
                            !creating152Profile ? create152Profile : null,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 100),
                          child: creating152Profile
                              ? Container(
                                  width: 30,
                                  height: 30,
                                  padding: const EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.amber.shade700),
                                )
                              : const Text("プロファイルを作成する"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const _InstallationFlow(
                "Minecraft 1.5.2を起動させる",
                contents: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("ランチャーを再起動し、作成したプロファイルを選択して起動して閉じてください。"
                      "この地点でクラッシュする場合がありますが、問題ありません (インストールの過程で修正されます)。"),
                ),
              ),
              _InstallationFlow(
                "必要なファイルをダウンロードする",
                contents: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      child: const Text("DQM MOD本体/前提MOD/SE・BGM"),
                      onPressed: () {
                        launchUrlString("https://dqm4mod.wixsite.com/home/");
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      child: const Text("Forge 1.5.2-7.8.1.738 Universal"),
                      onPressed: () {
                        launchUrlString(
                            "https://adfoc.us/serve/?id=27122878887873");
                      },
                    ),
                  ],
                ),
              ),
              _InstallationFlow(
                "ダウンロードしたファイルを読み込む",
                contents: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        child: const Text("フォルダーから自動的に認識"),
                        onPressed: () async {
                          var result =
                              await FilePicker.platform.getDirectoryPath();

                          if (result != null) {
                            Directory(result).list().listen((event) {
                              var fileName =
                                  path.basenameWithoutExtension(event.path);
                              if (fileName.contains("DQM") &&
                                  fileName.contains("jar")) {
                                _files["pre"]!.pathController.text = event.path;
                              } else if (fileName.contains("DQM") &&
                                  fileName.contains("mods")) {
                                _files["body"]!.pathController.text = event.path;
                              } else if (fileName.contains("DQM") &&
                                  fileName.contains("音声")) {
                                _files["sound"]!.pathController.text = event.path;
                              } else if (fileName ==
                                  "forge-1.5.2-7.8.1.738-universal") {
                                _files["forge"]!.pathController.text = event.path;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      for (final file in _files.values)
                        ...[
                          _FileFormField(
                            label: file.title + (file.optional ? "（任意）" : ""),
                            hint: file.formFieldHint,
                            pickerAllowedExtensions: file.pickerAllowedExtensions,
                            controller: file.pathController,
                          ),
                          const SizedBox(height: 16),
                        ],
                    ],
                  ),
                ),
              ),
              _InstallationFlow(
                "導入推奨MODの選択",
                contents: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ModCheckboxList(selected: _additionalMods),
                  ],
                ),
              ),
              _InstallationFlow(
                "インストールする",
                contents: Center(
                  child: SizedBox(
                    height: 40,
                    width: 200,
                    child: ElevatedButton(
                      onPressed: beginInstallation,
                      child: const Text("インストール開始"),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void checkWhetherCanBeInstalled() async {
    await checker.check();
    setState(() {});
  }

  Future<void> beginInstallation({List<String> skipIds = const []}) async {
    try {
      final error = await _checkPrerequisites(skipIds: skipIds);

      if (!mounted) return;
      if (error != null) {
        final result = await showAlertDialog(
          context: context,
          title: error.errorDialogTitle,
          message: error.errorMessage,
          showCancel: error.skipId != null,
        );
        if (error.skipId != null && result == true) {
          beginInstallation(skipIds: [...skipIds, error.skipId!]);
        }
        return;
      }

      if (mounted) {
        final installer = Installer(
          prerequisiteModPath: _files["pre"]!.pathController.text,
          bodyModPath: _files["body"]!.pathController.text,
          bgmPath: _files["sound"]!.pathController.text,
          forgePath: _files["forge"]!.pathController.text,
          skinPath: _files["skin"]!.pathController.text,
          additionalMods: _additionalMods,
        );

        Navigator.pushNamed(
          context,
          "/install",
          arguments: InstallationProgressPageArguments(
            installer: installer,
          ),
        );
      }
    } on DqmInstallationException catch (e) {
      if (e.code == DqmInstallationError.failedToParseDqmType) {
        if (mounted) {
          showAlertDialog(
            context: context,
            title: "DQMの種類の判別に失敗しました。",
            message: "ファイル名が正しくない可能性があります。ダウンロードしたファイルのファイル名は絶対に変更しないでください。",
          );
        }
        return;
      }
      rethrow;
    }
  }

  Future<Prerequisite?> _checkPrerequisites({required List<String> skipIds}) async {
    final prerequisites = <Prerequisite>[
      // every file exists
      FilePrerequisite(files: _files.values),
      const Prerequisite(
        test: check152JarExists,
        errorDialogTitle: "エラー",
        errorMessage: "Minecraft 1.5.2が一度も起動されていません。当該の手順を踏んでから再度お試しください。",
      ),
      Prerequisite(
        test: () async {
          final modFileName = path.basename(_files["body"]!.pathController.text);
          final versionName = Installer.toVersionName(
            Installer.parseDqmType(modFileName),
            Installer.parseDqmVersion(modFileName),
          );
          return !await isDqmAlreadyInstalled(versionName); // returns true if not installed
        },
        errorDialogTitle: "上書き確認",
        errorMessage: "既にこのバージョンのDQMがインストールされています。再度インストールを行いますか？",
        skipId: "dqm_overwrite",
      ),
      Prerequisite(
        test: () async {
          await checker.check();
          return !checker.hasError;
        },
        errorDialogTitle: "環境チェックを無視しますか？",
        errorMessage: "Step 1の環境チェックにエラーがあります。インストールを行うこと自体は可能ですが、インストール後に正しく動作しない可能性があります。続行しますか？",
        skipId: "env_check_not_successful",
      ),
    ];

    return Prerequisite.executeTests(prerequisites, skipIds);
  }

  Future<void> create152Profile() async {
    setState(() {
      creating152Profile = true;
    });

    try {
      await MinecraftProfile().create152Profile();

      if (mounted) {
        showSnackBar(context, "Minecraft 1.5.2のプロファイルを作成しました");
      }
    } on FileSystemException catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        showErrorSnackBar(context, "プロファイルデータが見つかりません。ランチャーを起動してから再度お試しください。");
      }
    } on FormatException catch (e) {
      debugPrint(e.toString());
      if (mounted) {
        showErrorSnackBar(context, "プロファイルリストの読み取りに失敗しました");
      }
    } finally {
      setState(() {
        creating152Profile = false;
      });
    }
  }
}

class _FlowTimeline extends StatelessWidget {
  const _FlowTimeline(this.flow);

  final List<_InstallationFlow> flow;

  @override
  Widget build(BuildContext context) {
    return FixedTimeline.tileBuilder(
      theme: TimelineThemeData(
        nodePosition: 0,
        indicatorTheme: const IndicatorThemeData(
          position: 0,
          size: 36,
        ),
      ),
      builder: TimelineTileBuilder.connected(
        itemCount: flow.length,
        indicatorBuilder: (_, index) {
          return OutlinedDotIndicator(
            child: Center(
              child: Text(
                (index + 1).toString(),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          );
        },
        connectorBuilder: (_, __, ___) {
          return const SolidLineConnector();
        },
        contentsBuilder: (_, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 36,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    flow[index].title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                flow[index].contents,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InstallationFlow {
  const _InstallationFlow(this.title, {required this.contents});

  final String title;
  final Widget contents;
}

class _FileFormField extends StatelessWidget {
  const _FileFormField({
    required this.label,
    this.hint,
    required this.pickerAllowedExtensions,
    required this.controller,
  });

  final String label;
  final String? hint;
  final List<String> pickerAllowedExtensions;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              label: Text(label),
              hintText: hint,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.file_open),
          splashRadius: 24,
          onPressed: () async {
            var result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: pickerAllowedExtensions);
            if (result != null) {
              controller.text = result.files.single.path!;
            }
          },
        )
      ],
    );
  }
}

class _ModCheckboxList extends StatefulWidget {
  const _ModCheckboxList({required this.selected});

  final List<AdditionalMod> selected;

  @override
  State<_ModCheckboxList> createState() => _ModCheckboxListState();
}

class _ModCheckboxListState extends State<_ModCheckboxList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: additionalMods.map((e) => _buildCheckbox(e)).toList(),
    );
  }

  Widget _buildCheckbox(AdditionalMod mod) {
    void toggle() {
      setState(() {
        if (!widget.selected.contains(mod)) {
          widget.selected.add(mod);
        } else {
          widget.selected.remove(mod);
        }
      });
    }

    return GestureDetector(
      onTap: toggle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: widget.selected.contains(mod),
                onChanged: (value) {
                  toggle();
                },
              ),
              Text(
                mod.title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32.0, bottom: 16.0),
            child: Text(mod.description),
          ),
        ],
      ),
    );
  }
}

class Prerequisite {
  const Prerequisite({
    required this.test,
    required this.errorDialogTitle,
    required this.errorMessage,
    this.skipId,
  });

  final FutureOr<bool> Function() test;
  final String errorDialogTitle;
  final String errorMessage;
  /// If specified, this error treated as "ignorable", can be ignored by the
  /// user and skip the dialog.
  final String? skipId;

  static Future<Prerequisite?> executeTests(
    List<Prerequisite> items,
    List<String> skipIds,
  ) async {
    for (final item in items) {
      if (!skipIds.contains(item.skipId) && !await item.test()) {
        return item;
      }
    }
    return null;
  }
}

class FilePrerequisite implements Prerequisite {
  FilePrerequisite({required this.files});

  final Iterable<LoadableFile> files;

  List<LoadableFile> missingFiles = [];

  @override
  String get errorDialogTitle => "指定されたファイルが見つかりません";

  @override
  String get errorMessage => "「${missingFiles.map((e) => e.title).join("」「")}」に指定されているファイルは存在しません。";

  @override
  FutureOr<bool> Function() get test => () {
    missingFiles.clear();
    for (final file in files) {
      if (file.pathController.text.isEmpty && file.optional) {
        continue;
      }
      if (!File(file.pathController.text).existsSync()) {
        missingFiles.add(file);
      }
    }
    return missingFiles.isEmpty;
  };

  @override
  String? get skipId => null;
}

class LoadableFile {
  LoadableFile({
    required this.title,
    this.formFieldHint,
    this.optional = false,
    required this.pickerAllowedExtensions
  }) : pathController = TextEditingController();

  final String title;
  final String? formFieldHint;
  final TextEditingController pathController;
  final bool optional;
  final List<String> pickerAllowedExtensions;
}
