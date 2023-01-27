import 'package:dqm_installer_flt/pages/home.dart';
import 'package:dqm_installer_flt/pages/installation_progress.dart';
import 'package:flutter/material.dart';

void main() {
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
