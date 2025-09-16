import 'package:flutter/material.dart';
import 'package:flutter_tailwind/flutter_tailwind.dart';

class CustomErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const CustomErrorWidget({required this.error, super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: padding.p32.child(
        column.center.children([
          Icons.error_outline.icon.s64.red.mk,
          h16,
          text('加载失败').mk,
          h8,
          text(error).center.f14.grey.mk,
          if (onRetry != null) ...[
            h24,
            ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: text('重试').mk),
          ],
        ]),
      ),
    );
  }
}
