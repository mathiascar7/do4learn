import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/app_drawer.dart';
import 'package:easy_localization/easy_localization.dart';


class CourseDetailPage extends StatefulWidget {
  final String courseId;

  const CourseDetailPage({super.key, required this.courseId});

  @override
  _CourseDetailPageState createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final TextEditingController _nameController = TextEditingController();
  bool _enrollmentOpen = true;
  bool _isLoading = false;
  String? _errorMessage;
  String _courseCode = '';

  List<DocumentSnapshot> _allActivities = [];
  Set<String> _associatedActivityIds = {};
  bool _loadingActivities = true;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
    _loadCourseActivities();
  }

  Future<void> _loadCourseData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .get();

      if (!doc.exists) {
        setState(() {
          _errorMessage = 'course_not_found'.tr();
          _isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      _nameController.text = data['name'] ?? '';
      _enrollmentOpen = data['enrollmentOpen'] ?? true;
      _courseCode = data['code'] ?? '';

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'course_load_error'.tr(args: [e.toString()]);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCourseActivities() async {
    setState(() {
      _loadingActivities = true;
    });

    try {
      final allActivitiesSnap = await FirebaseFirestore.instance
          .collection('activities')
          .orderBy('title')
          .get();

      final assocSnap = await FirebaseFirestore.instance
          .collection('course_activities')
          .where('courseId', isEqualTo: widget.courseId)
          .get();

      setState(() {
        _allActivities = allActivitiesSnap.docs;
        _associatedActivityIds =
            assocSnap.docs.map((doc) => doc['activityId'] as String).toSet();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('activities_load_error'.tr(args: [e.toString()]))),
      );
    } finally {
      setState(() {
        _loadingActivities = false;
      });
    }
  }

  //confirmar desasiciacion de actividad
  void _confirmDisassociation(BuildContext context, String activityId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirmDisassociationTitle'.tr()),
        content: Text('confirmDisassociationMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleActivityAssociation(activityId);
            },
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );
  }


  Future<void> _toggleActivityAssociation(String activityId) async {
    final ref = FirebaseFirestore.instance.collection('course_activities');

    try {
      if (_associatedActivityIds.contains(activityId)) {
        final snap = await ref
            .where('courseId', isEqualTo: widget.courseId)
            .where('activityId', isEqualTo: activityId)
            .limit(1)
            .get();

        if (snap.docs.isNotEmpty) {
          await ref.doc(snap.docs.first.id).delete();
          setState(() {
            _associatedActivityIds.remove(activityId);
          });
        }
      } else {
        await ref.add({
          'courseId': widget.courseId,
          'activityId': activityId,
        });

        setState(() {
          _associatedActivityIds.add(activityId);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('activity_assoc_error'.tr(args: [e.toString()]))),
      );
    }
  }

  Future<void> _updateCourse() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('course_name_empty'.tr())));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .update({
        'name': name,
        'enrollmentOpen': _enrollmentOpen,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('course_updated'.tr())));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('course_update_error'.tr(args: [e.toString()]))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEnrollment(String enrollmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('enrollments')
          .doc(enrollmentId)
          .delete();

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('student_unregistered'.tr())));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text('student_unregister_error'.tr(args: [e.toString()]))),
      );
    }
  }

  Future<void> _registerStudentManually() async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('register_student'.tr()),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'student_email'.tr(),
              hintText: 'student_email_hint'.tr(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim().toLowerCase();
                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('enter_valid_email'.tr())),
                  );
                  return;
                }

                final userQuery = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: email)
                    .limit(1)
                    .get();

                if (userQuery.docs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('no_user_with_email'.tr())),
                  );
                  return;
                }

                final userDoc = userQuery.docs.first;
                final userId = userDoc.id;

                final existing = await FirebaseFirestore.instance
                    .collection('enrollments')
                    .where('courseId', isEqualTo: widget.courseId)
                    .where('userId', isEqualTo: userId)
                    .limit(1)
                    .get();

                if (existing.docs.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('student_already_registered'.tr())),
                  );
                  return;
                }

                await FirebaseFirestore.instance.collection('enrollments').add({
                  'userId': userId,
                  'email': email,
                  'courseId': widget.courseId,
                  'courseName': _nameController.text,
                  'registeredAt': FieldValue.serverTimestamp(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('student_registered_manually'.tr())),
                );

                Navigator.of(ctx).pop();
              },
              child: Text('register'.tr()),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('course_details_title'.tr()),
        automaticallyImplyLeading: true,
          actions: [
            IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'save_changes'.tr(),
            onPressed: _updateCourse,
            ),
          ],
      ),

      //drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del curso
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                  labelText: 'course_name_label'.tr()),
            ),
            const SizedBox(height: 20),
            // Código del curso
            if (_courseCode.isNotEmpty)
              Row(
                children: [
                  Flexible(
                    flex: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        _courseCode,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'copy_code'.tr(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _courseCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('code_copied'.tr())),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Transform.scale(
                    scale: 0.8,
                    child: Text('enrollment_open'.tr()),
                  ),
                  Transform.scale(
                    scale: 0.6,
                    child: Switch(
                      value: _enrollmentOpen,
                      onChanged: (val) => setState(() => _enrollmentOpen = val),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 15),

            // Actividades asociadas
            Text(
              'associated_activities'.tr(),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _loadingActivities
                ? const Center(child: CircularProgressIndicator())
                : _allActivities.isEmpty
                ? Text('no_activities_found'.tr())
                : Column(
              children: _allActivities.map((activityDoc) {
                final data =
                activityDoc.data() as Map<String, dynamic>;
                final activityId = activityDoc.id;
                final formKey = data['formPage'] ?? '';
                final title = (formKey is String && formKey.isNotEmpty)
                    ? formKey.tr()
                    : 'no_title'.tr();

                final isAssociated =
                _associatedActivityIds.contains(activityId);

                return ListTile(
                  title: Text(title),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAssociated)
                        IconButton(
                          icon: const Icon(Icons.bar_chart),
                          tooltip: 'view_activity_summary'.tr(),
                          onPressed: () async {
                            final activityDoc = await FirebaseFirestore.instance
                                .collection('activities')
                                .doc(activityId)
                                .get();

                            final formPage = activityDoc.data()?['formPage'] ?? 'thesis_form_page';

                            Navigator.pushNamed(
                              context,
                              '/summary',
                              arguments: {
                                'activityId': activityId,
                                'courseId': widget.courseId,
                                'userId': FirebaseAuth.instance.currentUser?.uid,
                                'formPage': formPage,
                              },
                            );
                          },

                        ),
                      IconButton(
                        icon: Icon(
                          isAssociated ? Icons.remove_circle_outline : Icons.add_circle_outline,
                          color: isAssociated ? Colors.orange.shade400 : Colors.green.shade400,
                        ),
                        tooltip: isAssociated ? 'remove'.tr() : 'add_to_course'.tr(),
                        onPressed: () {
                          if (isAssociated) {
                            _confirmDisassociation(context, activityId);
                          } else {
                            _toggleActivityAssociation(activityId);
                          }
                        },
                      ),

                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            // Estudiantes inscritos
            Text(
              'enrolled_students'.tr(),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('enrollments')
                    .where('courseId', isEqualTo: widget.courseId)
                    .orderBy('registeredAt', descending: true)
                    .snapshots(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                        child: Text('no_students_enrolled'.tr()));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final data =
                      docs[i].data() as Map<String, dynamic>;
                      final email = data['email'] ?? '';
                      final studentId = data['userId'];
                      final enrollmentId = docs[i].id;

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
                        builder: (context, userSnapshot) {
                          final userData = userSnapshot.data?.data() as Map<String, dynamic>?;

                          final name = userData?['name'] ?? 'Sin nombre';
                          final email = data['email'] ?? '';
                          final enrollmentId = docs[i].id;

                          return ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name),
                                Text(email, style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.list_alt),
                                  tooltip: 'view_student_activities'.tr(),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/activity-detail-by-student',
                                      arguments: {
                                        'courseId': widget.courseId,
                                        'studentId': studentId,
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red.shade200),
                                  onPressed: () => _deleteEnrollment(enrollmentId),
                                ),
                              ],
                            ),
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
        onPressed: _registerStudentManually,
        tooltip: 'register_student'.tr(),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
