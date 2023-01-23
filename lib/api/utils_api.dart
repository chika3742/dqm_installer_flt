import 'package:flutter/services.dart';

class UtilsApi {
  static const baseChannelName = "net.chikach.dqmInstallerFlt.UtilsApi";

  Future<String?> getBundlePath(String resourceName) {
    return const MethodChannel("$baseChannelName.getBundlePath")
        .invokeMethod<String?>("", resourceName);
  }
}
