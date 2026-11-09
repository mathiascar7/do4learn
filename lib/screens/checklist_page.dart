import 'package:flutter/material.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  _ChecklistPageState createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  final List<String> _checklistItems = [
    'Complete the first assignment',
    'Attend the course orientation',
    'Read the course materials',
    // Add more items as necessary
  ];

  final List<bool> _checklistStatus = List.generate(4, (index) => false);

  void _toggleChecklistStatus(int index) {
    setState(() {
      _checklistStatus[index] = !_checklistStatus[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Course Checklist')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: _checklistItems.length,
          itemBuilder: (context, index) {
            return CheckboxListTile(
              title: Text(_checklistItems[index]),
              value: _checklistStatus[index],
              onChanged: (value) => _toggleChecklistStatus(index),
            );
          },
        ),
      ),
    );
  }
}
