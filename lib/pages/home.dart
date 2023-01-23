import 'dart:io';

import 'package:dqm_installer_flt/libs/compatibility_checker.dart';
import 'package:dqm_installer_flt/libs/profiles.dart';
import 'package:dqm_installer_flt/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _FlowTimeline([
          _InstallationFlow(
            "インストール可能な環境かチェックする",
            contents: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(!checker.hasError ? "インストール可能です。" : "インストール前に準備が必要です"),
                if (checker.hasError) Text(checker.errorMessage),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        splashRadius: 24,
                        onPressed: () {
                          checkWhetherCanBeInstalled();
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: ButtonStyle(
                          foregroundColor:
                              MaterialStatePropertyAll(Colors.amber.shade800),
                        ),
                        onPressed: () {
                          launchUrl(Directory(getMinecraftDirectoryPath()).uri);
                        },
                        child: const Text("minecraftフォルダーを開く"),
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
                    onPressed: !creating152Profile
                        ? () async {
                            setState(() {
                              creating152Profile = true;
                            });

                            try {
                              await MinecraftProfile().create152Profile();

                              if (mounted) {
                                showSnackBar(
                                    context, "Minecraft 1.5.2のプロファイルを作成しました");
                              }
                            } on FileSystemException catch (e) {
                              debugPrint(e.toString());
                              if (mounted) {
                                showErrorSnackBar(context,
                                    "プロファイルデータが見つかりません。ランチャーを起動してから再度お試しください。");
                              }
                            } on FormatException catch (e) {
                              debugPrint(e.toString());
                              if (mounted) {
                                showErrorSnackBar(
                                    context, "プロファイルリストの読み取りに失敗しました");
                              }
                            } finally {
                              setState(() {
                                creating152Profile = false;
                              });
                            }
                          }
                        : null,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 100),
                      child: creating152Profile
                          ? Container(
                              width: 30,
                              height: 30,
                              padding: const EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                  strokeWidth: 3, color: Colors.amber.shade700),
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
                    launchUrlString("http://adfoc.us/serve/?id=27122854926913");
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
                children: [
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
                ],
              ),
            ),
          ),
          _InstallationFlow("インストールする",
              contents: Center(
                child: SizedBox(
                  height: 40,
                  width: 200,
                  child: ElevatedButton(
                    child: const Text("インストール開始"),
                    onPressed: () {},
                  ),
                ),
              )),
          _InstallationFlow(
            "必要に応じて追加でMODを導入する",
            contents: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  child: const Text("導入推奨MOD一覧"),
                  onPressed: () {
                    launchUrlString(
                        "https://www.chikach.net/category/info/dqm-recommended-mods/");
                  },
                ),
                const SizedBox(height: 8),
                const Text("上記リンク先に導入方法の説明も記載されています。"),
              ],
            ),
          )
        ]),
      ),
    );
  }

  void checkWhetherCanBeInstalled() async {
    await checker.check();
    setState(() {});
  }
}

class _FlowTimeline extends StatelessWidget {
  const _FlowTimeline(this.flow, {Key? key}) : super(key: key);

  final List<_InstallationFlow> flow;

  @override
  Widget build(BuildContext context) {
    return Timeline.tileBuilder(
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
      {Key? key, required this.label, required this.controller})
      : super(key: key);

  final String label;
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
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.file_open),
          splashRadius: 24,
          onPressed: () async {
            var result = await FilePicker.platform.pickFiles(
                type: FileType.custom, allowedExtensions: ["jar", "zip"]);
            if (result != null) {
              controller.text = result.files.single.path!;
            }
          },
        )
      ],
    );
  }
}
