import 'package:flutter/material.dart';

void showAccountActionDialog(
  BuildContext context, {
  required String title,
  required String message,
  Future<void> Function()? onConfirm,
}) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await onConfirm?.call();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
