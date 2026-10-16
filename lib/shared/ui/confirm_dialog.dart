/// 统一确认对话框（危险操作二次确认）。
library;

import 'package:flutter/material.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool danger = false,
  IconData? icon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        icon: icon == null
            ? null
            : Icon(
                icon,
                color: danger ? scheme.error : scheme.primary,
                size: 26,
              ),
        title: Text(title),
        content: Text(
          message,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel ?? MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            // 首焦落在主行动按钮上：键盘用户回车即确认，不需要先 Tab 一圈
            autofocus: true,
            style: danger
                ? FilledButton.styleFrom(backgroundColor: scheme.error)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel ?? MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
