import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentEnrollmentPage extends StatefulWidget {
  const StudentEnrollmentPage({super.key});

  @override
  _StudentEnrollmentPageState createState() => _StudentEnrollmentPageState();
}

class _StudentEnrollmentPageState extends State<StudentEnrollmentPage> {
  final TextEditingController _codeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _enrollStudent() async {
    final code = _codeController.text;
    try {
      final querySnapshot = await _firestore.collection('codes').where('code', isEqualTo: code).where('active', isEqualTo: true).get();
      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid or inactive code')));
        return;
      }

      final codeDoc = querySnapshot.docs.first;
      final courseId = codeDoc['courseId'];

      await _firestore.collection('courses').doc(courseId).collection('students').add({
        'email': 'student@example.com',  // Get the current student's email
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enrolled successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enroll in Course')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: 'Enter Enrollment Code'),
            ),
            ElevatedButton(
              onPressed: _enrollStudent,
              child: Text('Enroll'),
            ),
          ],
        ),
      ),
    );
  }
}
