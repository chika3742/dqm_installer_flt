import 'package:flutter/material.dart';

Future<bool?> showAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  bool showCancel = false,
}) {
  return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (showCancel)
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
}
