import 'dart:io';

import 'package:dqm_installer_flt/libs/compatibility_checker.dart';
import 'package:dqm_installer_flt/libs/installer.dart';
import 'package:dqm_installer_flt/libs/possible_error.dart';
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
  const HomePage({Key? key}) : super(key: key);

  static const routeName = "/";

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool creating152Profile = false;
  CompatibilityChecker checker = CompatibilityChecker();
  final _prerequisiteModController = TextEditingController();
  final _bodyModController = TextEditingController();
  final _bgmController = TextEditingController();
  final _forgeController = TextEditingController();
  final _skinController = TextEditingController();
  final _additionalMods = <AdditionalMod>[];

  @override
  void initState() {
    super.initState();
    checkWhetherCanBeInstalled();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DQM Installer"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _FlowTimeline([
            _InstallationFlow(
              "インストール可能な環境かチェックする",
              contents: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    !checker.hasError ? "インストール可能です。" : "インストール前に準備が必要です",
                    style: TextStyle(
                      color: !checker.hasError ? null : Colors.red,
                    ),
                  ),
                  if (checker.hasError)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, top: 8.0, bottom: 8.0),
                      child: Text(checker.errorMessage),
                    ),
                  if (checker.hasError)
                    const Text("これらのエラーは無視することも可能ですが、動作は保証しません。"),
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
                      onPressed: !creating152Profile ? create152Profile : null,
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
                child: Text("作成したプロファイルを選択して起動し、閉じてください。"),
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
                      launchUrlString("http://dqm4mod.wixsite.com/home/");
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    child: const Text("Forge 1.5.2-7.8.1.738 Universal"),
                    onPressed: () {
                      launchUrlString(
                          "http://adfoc.us/serve/?id=27122854926913");
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
                              _prerequisiteModController.text = event.path;
                            } else if (fileName.contains("DQM") &&
                                fileName.contains("mods")) {
                              _bodyModController.text = event.path;
                            } else if (fileName.contains("DQM") &&
                                fileName.contains("音声")) {
                              _bgmController.text = event.path;
                            } else if (fileName ==
                                "forge-1.5.2-7.8.1.738-universal") {
                              _forgeController.text = event.path;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _FileFormField(
                      label: "DQM 前提MOD",
                      controller: _prerequisiteModController,
                    ),
                    const SizedBox(height: 16),
                    _FileFormField(
                      label: "DQM 本体MOD",
                      controller: _bodyModController,
                    ),
                    const SizedBox(height: 16),
                    _FileFormField(
                      label: "DQM 音声・BGM",
                      controller: _bgmController,
                    ),
                    const SizedBox(height: 16),
                    _FileFormField(
                      label: "Forge",
                      controller: _forgeController,
                    ),
                    const SizedBox(height: 16),
                    _FileFormField(
                      label: "スキン (任意)",
                      hint: "デフォルト (Steve)",
                      skin: true,
                      controller: _skinController,
                    ),
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
    );
  }

  void checkWhetherCanBeInstalled() async {
    await checker.check();
    setState(() {});
  }

  Future<void> beginInstallation() async {
    final files = [
      _prerequisiteModController.text,
      _bodyModController.text,
      _bgmController.text,
      _forgeController.text,
    ];

    final errors = [
      PossibleError("指定されたファイルの一部が存在しません。", () {
        return checkAllModFilesExist(files, _skinController.text);
      }),
      const PossibleError("Step 2、Step 3を踏んでから再度お試しください。", check152JarExists),
    ];

    final checkResult = await checkErrors(errors);

    if (!checkResult) {
      return;
    }

    final installer = Installer(
      prerequisiteModPath: _prerequisiteModController.text,
      bodyModPath: _bodyModController.text,
      bgmPath: _bgmController.text,
      forgePath: _forgeController.text,
      skinPath: _skinController.text,
      additionalMods: _additionalMods,
    );

    try {
      installer.parseDqmFileName();
    } catch (e, st) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: st);

      if (!mounted) return;
      await showAlertDialog(
        context: context,
        title: "DQMの種類の判別に失敗しました。",
        message: "ファイル名が正しくない可能性があります。ダウンロードしたファイルのファイル名は絶対に変更しないでください。",
      );
    }

    if (await isDqmAlreadyInstalled(installer.versionName)) {
      if (!mounted) return;
      final result = await showAlertDialog(
        context: context,
        title: "上書き確認",
        message: "既にこのバージョンのDQMがインストールされています。上書きしますか？",
        showCancel: true,
      );
      if (result != true) {
        return;
      }
    }

    await checker.check();

    if (checker.hasError) {
      if (!mounted) return;
      final result = await showAlertDialog(
        context: context,
        title: "環境チェックを無視しますか？",
        message: "Step 1の環境チェックにエラーがあります。続行しますか？",
        showCancel: true,
      );
      if (result != true) {
        return;
      }
    }

    if (mounted) {
      Navigator.pushNamed(
        context,
        "/install",
        arguments: InstallationProgressPageArguments(
          installer: installer,
        ),
      );
    }
  }

  Future<bool> checkErrors(List<PossibleError> errors) async {
    for (final error in errors) {
      final result = await error.check().then((value) {
        if (!value) {
          showAlertDialog(
              context: context, title: "エラー", message: error.errorMessage);
          return false;
        }
        return true;
      }).catchError((e, stackTrace) {
        debugPrint(e.toString());
        debugPrintStack(stackTrace: stackTrace);

        return false;
      });

      if (!result) {
        return false;
      }
    }

    // no error
    return true;
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
  const _FlowTimeline(this.flow, {Key? key}) : super(key: key);

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
  const _FileFormField(
      {Key? key,
      required this.label,
      this.hint,
      required this.controller,
      this.skin = false})
      : super(key: key);

  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool skin;

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
                allowedExtensions: skin ? ["png"] : ["jar", "zip"]);
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
  const _ModCheckboxList({Key? key, required this.selected}) : super(key: key);

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


