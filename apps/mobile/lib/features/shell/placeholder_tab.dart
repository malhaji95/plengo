import 'package:flutter/material.dart';

/// Stand-in for sections delivered in later phases (spec §39).
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('هذا القسم قيد الإعداد', style: Theme.of(context).textTheme.bodyLarge),
        ),
      ),
    );
  }
}
