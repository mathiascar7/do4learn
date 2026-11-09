import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class CodeGenerationPage extends StatefulWidget {
  final String courseId;

  const CodeGenerationPage({super.key, required this.courseId});

  @override
  _CodeGenerationPageState createState() => _CodeGenerationPageState();
}

class _CodeGenerationPageState extends State<CodeGenerationPage> {
  final Random _random = Random();

  String _generateCode() {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (index) => charset[_random.nextInt(charset.length)]).join();
  }

  void _generateAndSaveCode() async {
    final code = _generateCode();
    try {
      await FirebaseFirestore.instance.collection('codes').add({
        'courseId': widget.courseId,
        'code': code,
        'role': 'student', // o 'admin'
        'active': true,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Code generated')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Generate Code')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _generateAndSaveCode,
              child: Text('Generate Code'),
            ),
          ],
        ),
      ),
    );
  }
}

