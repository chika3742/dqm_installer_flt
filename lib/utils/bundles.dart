import 'package:dqm_installer_flt/api/utils_api.dart';

Future<String> get7zPath() async {
  var bundlePath = await UtilsApi().getBundlePath("7zz");
  if (bundlePath == null) {
    throw Exception("Failed to get bundle path");
  }
  return bundlePath;
}
