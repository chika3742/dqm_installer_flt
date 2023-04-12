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
  final Installer installer;

  const InstallationProgressPageArguments({required this.installer});
}

class _InstallationProgressPageState extends State<InstallationProgressPage> {
  late Installer installer;

  @override
  void initState() {
    super.initState();

    installer = widget.arguments.installer;
    installer.onProgressChanged = (_) {
      setState(() {});
    };
    installer.install().then((value) {
      showDialog(
        context: context,
        barrierDismissible: false,
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
        },
      );
    }).catchError((e, st) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: st);

      final String errorMessage;

      if (e is DqmInstallationException) {
        switch(e.code) {
          case DqmInstallationError.failedToParseDqmType:
            errorMessage = "DQMの種類またはバージョンの認識に失敗しました。MODファイル名を変更していませんか？";
            break;
          case DqmInstallationError.failedToDownloadAsset:
            errorMessage = "必要なファイルのダウンロードに失敗しました。ネットワーク接続をご確認ください。";
            break;
        }
      } else {
        errorMessage = "インストール中にエラーが発生しました。(${e.toString()})";
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text("エラー"),
            content: Text(errorMessage),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.popUntil(context, ModalRoute.withName("/"));
                },
              )
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("インストール中"),
        automaticallyImplyLeading: false,
      ),
      body: WillPopScope(
        onWillPop: () async {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text("インストール中"),
                content: const Text("インストールはキャンセルできません"),
                actions: [
                  TextButton(
                    child: const Text("OK"),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  ),
                ],
              );
            },
          );

          return false;
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
