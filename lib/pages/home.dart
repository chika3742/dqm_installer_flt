import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  static const routeName = "/";

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text("Execute"),
          onPressed: () async {
            var bundlePath = await const MethodChannel("net.chikach.dqmInstallerFlt.UtilsApi.getBundlePath")
                .invokeMethod("", "7zz");
            print((await Process.run(bundlePath, ["b"])).stdout);
          },
        ),
      ),
    );
  }
}
