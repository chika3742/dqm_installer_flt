import 'dart:io';

import 'package:dqm_installer_flt/pages/home.dart';
import 'package:dqm_installer_flt/pages/installation_progress.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

void main()  {
  void saveErrorToFile(Object e, StackTrace? st) {
    // save error to file
    File(path.join(path.dirname(Platform.resolvedExecutable), "error_${DateTime.now().toString().replaceAll(RegExp(":| "), "_")}.txt"))
        .writeAsStringSync("${e.toString()}\n${st.toString()}");
  }

  FlutterError.onError = (details) {
    debugPrintStack(stackTrace: details.stack, label: details.exception.toString());
    saveErrorToFile(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, st) {
    debugPrintStack(stackTrace: st, label: error.toString());
    // save error to file
    saveErrorToFile(error, st);
    return true;
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DQM Installer',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
        )),
        fontFamily: "MPLUS1p",
      ),
      locale: const Locale("ja"),
      initialRoute: "/",
      routes: {
        HomePage.routeName: (_) => const HomePage(),
        InstallationProgressPage.routeName: (ctx) => InstallationProgressPage(
              ModalRoute.of(ctx)!.settings.arguments
                  as InstallationProgressPageArguments,
            ),
      },
    );
  }
}
