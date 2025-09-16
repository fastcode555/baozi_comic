import 'package:flutter/material.dart';
import 'package:flutter_tailwind/flutter_tailwind.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: column.center.children([
        const CircularProgressIndicator(),
        if (message != null) ...[h16, text(message).f14.grey.mk],
      ]),
    );
  }
}
