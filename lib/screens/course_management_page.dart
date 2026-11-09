import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';

import 'widgets/app_drawer.dart'; // Ajusta la ruta si es necesario

class CourseManagementPage extends StatefulWidget {
  const CourseManagementPage({super.key});

  @override
  _CourseManagementPageState createState() => _CourseManagementPageState();
}

class _CourseManagementPageState extends State<CourseManagementPage> {
  String? _editingCourseId;

  Future<String?> _getUniversityIdForUser(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      return data?['universityId'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('course_management_title'.tr()),
      ),
      drawer: const AppDrawer(),
      body: user == null
          ? Center(child: Text('please_log_in_manage_courses'.tr()))
          : FutureBuilder<String?>(
        future: _getUniversityIdForUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final universityId = snapshot.data;
          if (universityId == null || universityId.isEmpty) {
            return Center(child: Text('no_university_associated'.tr()));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .where('createdBy', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('no_courses_available'.tr()));
                }

                final courses = snapshot.data!.docs;

                return ListView.separated(
                  itemCount: courses.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final courseId = course.id;
                    final courseName = course['name'] ?? 'Unnamed';
                    final courseCode = course['code'] ?? 'No code';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
                      title: Text(courseName),
                      //subtitle: Text('${'code_label'.tr()}: $courseCode'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.description),
                            tooltip: 'view_course_detail'.tr(),
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                '/course-detail',
                                arguments: {'courseId': courseId},
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red.shade200),
                            tooltip: 'delete_course'.tr(),
                            onPressed: () => _deleteCourse(courseId),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/course-detail',
                          arguments: {'courseId': courseId},
                        );
                      },
                    );
                  },
                );
              },
            ),

          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightBlue.shade100,
        onPressed: _showAddCourseDialog,
        tooltip: 'add_course'.tr(),
        child: const Icon(Icons.add),
      ),
    );
  }


  Future<String> _generateCourseCode() async {
    const length = 10;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();

    String generateRandomCode() {
      return String.fromCharCodes(Iterable.generate(
        length,
            (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
      ));
    }

    String code;
    bool exists = true;

    do {
      code = generateRandomCode();
      final existing = await FirebaseFirestore.instance
          .collection('courses')
          .where('code', isEqualTo: code)
          .get();
      exists = existing.docs.isNotEmpty;
    } while (exists);

    return code;
  }

  void _showAddCourseDialog() async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    final generatedCode = await _generateCourseCode();
    codeController.text = generatedCode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('add_course'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'course_name'.tr()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: codeController,
              decoration: InputDecoration(labelText: 'course_code'.tr()),
              readOnly: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              final user = FirebaseAuth.instance.currentUser;

              if (name.isEmpty || user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('course_enter_name'.tr())),
                );
                return;
              }

              try {
                final universityId = await _getUniversityIdForUser(user.uid);

                await FirebaseFirestore.instance.collection('courses').add({
                  'name': name,
                  'code': code,
                  'createdAt': FieldValue.serverTimestamp(),
                  'enrollmentOpen': true,
                  'createdBy': user.uid,
                  'universityId': universityId ?? '',
                });


                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('course_added_code'.tr(namedArgs: {'code': code}))),
                );

                Navigator.of(ctx).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('error_msg'.tr(args: [e.toString()]))),
                );
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  void _deleteCourse(String courseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('confirm_delete'.tr()),
        content: Text('confirm_delete_course'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('cancel'.tr())),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('delete'.tr())),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('courses').doc(courseId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('course_deleted'.tr())),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_msg'.tr(args: [e.toString()]))),
      );
    }
  }
}
