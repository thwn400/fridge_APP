import 'package:flutter/material.dart';

class CustomDialog {
  static Future<void> todo(context) async {
    show(context: context, title: '미구현');
  }

  static Future<void> show({
    required BuildContext context,
    required String title,
    String? content,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: content != null ? Text(content) : null,
          actions: [
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
