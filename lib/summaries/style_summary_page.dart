import 'package:flutter/material.dart';

class StyleSummaryPage extends StatelessWidget {
  final String activityId;
  final String courseId;

  const StyleSummaryPage({
    super.key,
    required this.activityId,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Style Summary')),
      body: const Center(child: Text('Resumen de estilo de trabajo')),
    );
  }
}
