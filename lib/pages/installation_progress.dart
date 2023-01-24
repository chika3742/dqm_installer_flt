import 'package:dqm_installer_flt/libs/installer.dart';
import 'package:flutter/material.dart';

class InstallationProgressPage extends StatefulWidget {
  const InstallationProgressPage(this.arguments, {Key? key}) : super(key: key);

  static const routeName = "/install";

  final InstallationProgressPageArguments arguments;

  @override
  State<InstallationProgressPage> createState() =>
      _InstallationProgressPageState();
}

class InstallationProgressPageArguments {
  final String prerequisiteModPath;
  final String bodyModPath;
  final String bgmPath;
  final String forgePath;

  const InstallationProgressPageArguments({
    required this.prerequisiteModPath,
    required this.bodyModPath,
    required this.bgmPath,
    required this.forgePath,
  });
}

class _InstallationProgressPageState extends State<InstallationProgressPage> {
  late Installer installer;

  @override
  void initState() {
    super.initState();

    installer = Installer(
      onProgressChanged: (progress) {
        setState(() {});
      },
      prerequisiteModPath: widget.arguments.prerequisiteModPath,
      bodyModPath: widget.arguments.bodyModPath,
      bgmPath: widget.arguments.bgmPath,
      forgePath: widget.arguments.forgePath,
    );
    installer.install().then((value) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("完了"),
              content: const Text("インストールが完了しました。"),
              actions: [
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.popUntil(context, ModalRoute.withName("/"));
                  },
                )
              ],
            );
          });
    }).catchError((e, st) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: st);

      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("エラー"),
              content: Text("インストール中にエラーが発生しました。(${e.toString()})"),
              actions: [
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.popUntil(context, ModalRoute.withName("/"));
                  },
                )
              ],
            );
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("インストール中"),
      ),
      body: WillPopScope(
        onWillPop: () async {
          var result = await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("確認"),
                  content: const Text("インストールをキャンセルしますか？"),
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

          return result;
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "インストール中 (${(installer.progress.overallProgress * 100).toStringAsFixed(2)}%)",
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                  value: installer.progress.overallProgress),
              const SizedBox(height: 16),
              Text(
                  "${installer.progress.currentProcedureTitle} (${(installer.progress.currentProcedureProgress * 100).toStringAsFixed(2)}%)"),
              const SizedBox(height: 16),
              SizedBox(
                width: 300,
                child: LinearProgressIndicator(
                    value: installer.progress.currentProcedureProgress),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
