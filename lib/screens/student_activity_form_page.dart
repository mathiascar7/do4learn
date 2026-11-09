import 'package:flutter/material.dart';

class StudentActivityFormPage extends StatelessWidget {
  final String courseId;
  final String activityId;
  final String studentId;

  const StudentActivityFormPage({
    super.key,
    required this.courseId,
    required this.activityId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Activity Form')),
      body: Center(
        child: Text('Form for student $studentId\nActivity $activityId\nCourse $courseId'),
      ),
    );
  }
}
