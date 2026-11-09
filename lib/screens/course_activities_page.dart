import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'widgets/app_drawer.dart'; // Ajusta según la ruta real de tu AppDrawer

class CourseActivitiesPage extends StatefulWidget {
  final String courseId;

  const CourseActivitiesPage({
    super.key,
    required this.courseId,
  });

  @override
  State<CourseActivitiesPage> createState() => _CourseActivitiesPageState();
}

class _CourseActivitiesPageState extends State<CourseActivitiesPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<DocumentSnapshot> _activities = [];
  String? _courseName;


  @override
  void initState() {
    super.initState();
    _loadCourseName();
    _loadActivitiesForCourse();
  }

  Future<void> _loadCourseName() async {
    try {
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .get();

      if (courseDoc.exists) {
        setState(() {
          _courseName = courseDoc['name'] ?? 'unknown_course'.tr();
        });
      } else {
        setState(() {
          _courseName = 'unknown_course'.tr();
        });
      }
    } catch (e) {
      setState(() {
        _courseName = 'course_name_error'.tr(args: [e.toString()]);
      });
    }
  }

  Future<void> _loadActivitiesForCourse() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1) Obtener asociaciones
      final assocSnap = await FirebaseFirestore.instance
          .collection('course_activities')
          .where('courseId', isEqualTo: widget.courseId)
          .get();

      final activityIds = assocSnap.docs
          .map((doc) => doc['activityId'] as String)
          .toList();

      if (activityIds.isEmpty) {
        // No hay actividades asociadas
        setState(() {
          _activities = [];
          _isLoading = false;
        });
        return;
      }

      // 2) Obtener datos de actividades filtradas
      final actSnap = await FirebaseFirestore.instance
          .collection('activities')
          .where(FieldPath.documentId, whereIn: activityIds)
          .get();

      setState(() {
        _activities = actSnap.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'activities_load_error'.tr(args: [e.toString()]);
        _isLoading = false;
      });
    }
  }

  void _goToActivityForm(String activityId, String formPageName) {
    Navigator.pushNamed(
      context,
      '/activity-form',
      arguments: {
        'activityId': activityId,
        'formPage': formPageName,
        'courseId': widget.courseId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('course_activities_title'.tr()),
        automaticallyImplyLeading: true,
      ),
      //drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_courseName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  //'${'course_name_label'.tr()}: $_courseName',
                  _courseName ?? '',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _activities.isEmpty
                  ? Center(child: Text('course_no_activities'.tr()))
                  : ListView.separated(
                itemCount: _activities.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final actDoc = _activities[idx];
                  final data = actDoc.data() as Map<String, dynamic>;
                  final formPage = data['formPage'];
                  final title = formPage is String
                      ? context.tr(formPage)
                      : context.tr('no_title');

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
                    leading: const Icon(Icons.assignment),
                    title: Text(title),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new),
                      tooltip: 'go_to_form'.tr(),
                      onPressed: () {
                        _goToActivityForm(actDoc.id, formPage);
                      },
                    ),
                    onTap: () {
                      _goToActivityForm(actDoc.id, formPage);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


}
