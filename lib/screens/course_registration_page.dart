import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'widgets/app_drawer.dart'; // Ajusta la ruta si es necesario

class CourseRegistrationPage extends StatefulWidget {
  const CourseRegistrationPage({super.key});

  @override
  _CourseRegistrationPageState createState() => _CourseRegistrationPageState();
}

class _CourseRegistrationPageState extends State<CourseRegistrationPage> {
  bool _isLoading = false;
  String _message = '';

  Future<void> _registerToCourse(String courseCode) async {
    final user = FirebaseAuth.instance.currentUser;

    if (courseCode.isEmpty) {
      setState(() {
        _message = 'course_enter_code'.tr();
      });
      return;
    }

    if (user == null) {
      setState(() {
        _message = 'user_not_authenticated'.tr();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('code', isEqualTo: courseCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _message = 'course_not_found_code'.tr();
          _isLoading = false;
        });
        return;
      }

      final courseDoc = querySnapshot.docs.first;
      final courseId = courseDoc.id;

      final enrollmentOpen = courseDoc['enrollmentOpen'] ?? true;
      if (!enrollmentOpen) {
        setState(() {
          _message = 'registrations_closed'.tr();
          _isLoading = false;
        });
        return;
      }

      final enrollmentQuery = await FirebaseFirestore.instance
          .collection('enrollments')
          .where('userId', isEqualTo: user.uid)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (enrollmentQuery.docs.isNotEmpty) {
        setState(() {
          _message = 'already_registered'.tr();
          _isLoading = false;
        });
        return;
      }

      await FirebaseFirestore.instance.collection('enrollments').add({
        'userId': user.uid,
        'email': user.email,
        'courseId': courseId,
        'courseName': courseDoc['name'],
        'registeredAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _message = 'registered_success'.tr();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'error_msg'.tr(args: [e.toString()]);
        _isLoading = false;
      });
    }
  }

  Future<void> _unregisterFromCourse(String enrollmentId) async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await FirebaseFirestore.instance.collection('enrollments').doc(enrollmentId).delete();
      setState(() {
        _message = 'unregistered_success'.tr();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'error_msg'.tr(args: [e.toString()]);
        _isLoading = false;
      });
    }
  }

  void _goToCourseActivities(String courseId) {
    Navigator.pushNamed(context, '/course_activities', arguments: {'courseId': courseId});
  }

  void _showRegisterCourseDialog() {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('register_new_course_title'.tr()),
          content: TextField(
            controller: codeController,
            decoration: InputDecoration(
              labelText: 'course_code_label'.tr(),
              hintText: 'course_code_hint'.tr(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = codeController.text.trim();
                if (code.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _registerToCourse(code);
                }
              },
              child: Text('register'.tr()),
            ),
          ],
        );
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('course_registration_title'.tr()),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.toLowerCase().contains('success') ||
                        _message.toLowerCase().contains(tr('registered_success').toLowerCase())
                        ? Colors.green
                        : Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),
            Expanded(
              child: user == null
                  ? Center(child: Text('user_not_authenticated'.tr()))
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('enrollments')
                    .where('userId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('no_registered_courses'.tr()));
                  }

                  final enrollments = snapshot.data!.docs;

                  return ListView.separated(
                    itemCount: enrollments.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final enrollment = enrollments[index];
                      final courseId = enrollment['courseId'];
                      final registeredAt = enrollment['registeredAt'];

                      final enrolledDate = registeredAt != null
                          ? (registeredAt as Timestamp).toDate().toLocal()
                          : null;
                      final dateStr = enrolledDate != null
                          ? DateFormat.yMMMd(context.locale.toString()).format(enrolledDate)
                          : 'n_a'.tr();

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('courses').doc(courseId).get(),
                        builder: (context, courseSnapshot) {
                          if (courseSnapshot.connectionState == ConnectionState.waiting) {
                            return const ListTile(title: Text('...'));
                          }

                          if (!courseSnapshot.hasData || !courseSnapshot.data!.exists) {
                            return ListTile(
                              title: Text('unknown_course'.tr()),
                              subtitle: Text('enrolled_on'.tr(namedArgs: {'date': dateStr})),
                            );
                          }

                          final courseName = courseSnapshot.data!['name'] ?? 'unknown_course'.tr();

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
                            title: Text(courseName),
                            subtitle: Text('enrolled_on'.tr(namedArgs: {'date': dateStr})),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.list_alt_outlined),
                                  tooltip: 'view_activities'.tr(),
                                  onPressed: () => _goToCourseActivities(courseId),
                                ),
                                IconButton(
                                  icon:  Icon(Icons.delete, color: Colors.red.shade200),
                                  tooltip: 'unregister_from_course'.tr(),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text('unregister_title'.tr()),
                                        content: Text('unregister_confirm'.tr(namedArgs: {
                                          'course': courseName,
                                        })),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(),
                                            child: Text('cancel'.tr()),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(ctx).pop();
                                              _unregisterFromCourse(enrollment.id);
                                            },
                                            child: Text('yes'.tr()),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () => _goToCourseActivities(courseId),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightBlue.shade100,
        onPressed: _showRegisterCourseDialog,
        tooltip: 'register_new_course_btn'.tr(),
        child: const Icon(Icons.add),
      ),
    );
  }

}
