import 'dart:io';

import 'package:dqm_installer_flt/libs/compatibility_checker.dart';
import 'package:dqm_installer_flt/libs/installer.dart';
import 'package:dqm_installer_flt/libs/profiles.dart';
import 'package:dqm_installer_flt/pages/installation_progress.dart';
import 'package:dqm_installer_flt/utils/precondition.dart';
import 'package:dqm_installer_flt/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
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
                            launchUrl(
                                Directory(getMinecraftDirectoryPath()).uri);
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

    if (await checkAllModFilesExist(files, _skinController.text)) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("エラー"),
              content: const Text("指定されたファイルの一部が存在しません。"),
              actions: [
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          });
      return;
    }

    if (!await check152JarExists()) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("エラー"),
              content: const Text("Step 2、Step 3を踏んでから再度お試しください。"),
              actions: [
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ],
            );
          });
      return;
    }

    await checker.check();

    if (checker.hasError) {
      final result = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("確認"),
              content: const Text("Step 1の環境チェックにエラーがあります。続行しますか?"),
              actions: [
                TextButton(
                  child: const Text("キャンセル"),
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                ),
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                ),
              ],
            );
          });
      if (result != true) {
        return;
      }
    }

    if (mounted) {
      Navigator.pushNamed(context, "/install",
          arguments: InstallationProgressPageArguments(
            prerequisiteModPath: _prerequisiteModController.text,
            bodyModPath: _bodyModController.text,
            bgmPath: _bgmController.text,
            forgePath: _forgeController.text,
            skinPath: _skinController.text,
            additionalMods: _additionalMods,
          ));
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
  final List<AdditionalMod> catalog = [
    AdditionalMod(
      "Skin Fixer",
      "ランチャーでアップロードしたスキンをゲーム内に反映させます。"
          "これを導入しなかった場合には、上で指定したスキンが使用されます。"
          "スリムスキンは腕に黒帯が発生します。",
      mod: DownloadableAsset(
        Uri.parse(
            "https://mediafilez.forgecdn.net/files/2571/89/skin-fixer-1.5.2-1.0.1.jar"),
        196880,
      ),
    ),
    AdditionalMod(
        "ChickenChunks",
        "チャンク読み込みMOD。これを使うと、別ディメンションにいるときでも薬草などが育ちます。\n"
            "チャンクローダーをクラフトする必要があります。クラフト方法はCraftGuideで調べてください。",
        mod: DownloadableAsset(
          Uri.parse(
              "https://r2.chikach.net/dqm-assets/recommended-mods/ChickenChunks 1.3.2.14.jar"),
          93761,
        ),
        coreMod: DownloadableAsset(
          Uri.parse(
              "https://r2.chikach.net/dqm-assets/recommended-mods/CodeChickenCore 0.8.7.3-fix1.jar"),
          322443,
        )),
    AdditionalMod(
        "CraftGuide",
        "全アイテムのクラフト方法を確認できます。DQMの攻略を進めるためにはほぼ必須と言っても過言ではありません。"
            "Gキーで開けます。",
        mod: DownloadableAsset(
          Uri.parse(
              "https://r2.chikach.net/dqm-assets/recommended-mods/CraftGuide-1.6.7.3-modloader.zip"),
          287669,
        )),
    AdditionalMod(
      "Inventory Tweaks",
      "インベントリを整理してくれます。Rキーで発動します。",
      mod: DownloadableAsset(
        Uri.parse(
            "https://r2.chikach.net/dqm-assets/recommended-mods/InventoryTweaks-1.54.jar"),
        181890,
      ),
    ),
    AdditionalMod(
      "Multi Page Chest",
      "超大容量チェストを追加するMODです。ダイヤ4個とチェスト4個でクラフトできます。",
      mod: DownloadableAsset(
        Uri.parse(
            "https://r2.chikach.net/dqm-assets/recommended-mods/multiPageChest_1.2.3_Universal.zip"),
        25232,
      ),
    ),
    AdditionalMod(
      "日本語MOD",
      "Minecraft 1.5.2は日本語入力に非対応のため、このMODを導入すると日本語でチャットを打ち込めるようになります。",
      mod: DownloadableAsset(
        Uri.parse(
            "https://r2.chikach.net/dqm-assets/recommended-mods/NihongoMOD_v1.2.2_forMC1.5.2.zip"),
        98764,
      ),
    ),
    AdditionalMod(
      "VoxelMap",
      "地図MODです。最後に死んだ場所を記録したり、マップピンを刺したりできます。",
      mod: DownloadableAsset(
        Uri.parse(
            "https://r2.chikach.net/dqm-assets/recommended-mods/VoxelMap-1.5.2.zip"),
        435242,
      ),
    ),
    AdditionalMod(
      "Damage Indicators",
      "Mobの残り体力を表示できます。",
      mod: DownloadableAsset(
        Uri.parse(
            "https://r2.chikach.net/dqm-assets/recommended-mods/1.5.2 DamageIndicators v2.7.0.1.zip"),
        292208,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: catalog.map((e) => _buildCheckbox(e)).toList(),
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

class AdditionalMod {
  final String title;
  final String description;
  final DownloadableAsset mod;
  final DownloadableAsset? coreMod;

  const AdditionalMod(this.title, this.description,
      {required this.mod, this.coreMod});

  List<DownloadableAsset> toFiles() {
    return [mod, if (coreMod != null) coreMod!];
  }
}
