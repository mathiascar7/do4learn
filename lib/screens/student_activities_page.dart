//Course-> Course detail -> Students-> Detail

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class StudentActivitiesPage extends StatefulWidget {
  final String courseId;
  final String studentId;

  const StudentActivitiesPage({
    super.key,
    required this.courseId,
    required this.studentId,
  });

  @override
  _StudentActivitiesPageState createState() => _StudentActivitiesPageState();
}

class _StudentActivitiesPageState extends State<StudentActivitiesPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<DocumentSnapshot> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadStudentActivities();
  }

  Future<bool> _hasResponse(String activityId) async {
    try {
      //print('🔍 Verificando respuesta para actividad: $activityId');

      final snapshot = await FirebaseFirestore.instance
          .collection('activity_responses')
          .where('activityId', isEqualTo: activityId)
          .where('courseId', isEqualTo: widget.courseId)
          .where('userId', isEqualTo: widget.studentId)
          .limit(1)
          .get();

      final found = snapshot.docs.isNotEmpty;
      //print('📦 Resultado: ${found ? "Sí hay respuesta" : "No hay respuesta"}');

      return found;
    } catch (e) {
      //print('⚠️ Error al verificar respuesta: $e');
      return false;
    }
  }

  Future<void> _loadStudentActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1) Obtener las actividades asociadas al curso
      final assocSnap = await FirebaseFirestore.instance
          .collection('course_activities')
          .where('courseId', isEqualTo: widget.courseId)
          .get();

      final activityIds = assocSnap.docs
          .map((doc) => doc['activityId'] as String)
          .toList();

      if (activityIds.isEmpty) {
        setState(() {
          _activities = [];
          _isLoading = false;
        });
        return;
      }

      // 2) Obtener datos de actividades
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
        _errorMessage = 'Error loading activities: $e';
        _isLoading = false;
      });
    }
  }

  void _goToStudentActivityForm(String activityId) {
    Navigator.pushNamed(
      context,
      '/activity-form',
      arguments: {
        'activityId': activityId,
        'courseId': widget.courseId,
        'studentId': widget.studentId,
        'formPage':
            'student_form', // Ajusta según tu lógica de formulario individual
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('student_activities_title'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : _activities.isEmpty
            ? Center(child: Text('no_activities_found'.tr()))
            : ListView.builder(
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  final doc = _activities[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'No title';
                  final activityId = doc.id;

                  return FutureBuilder<bool>(
                    future: _hasResponse(activityId),
                    builder: (context, snapshot) {
                      //print('📡 Estado del FutureBuilder para $activityId: ${snapshot.connectionState}');
                      //print('📊 snapshot.data = ${snapshot.data}');

                      if (snapshot.connectionState != ConnectionState.done) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(title),
                            trailing: const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final hasResponse = snapshot.data == true;
                      //print('🎯 hasResponse final = $hasResponse');

                      final iconColor = hasResponse
                          ? Colors.blue
                          : Colors.grey.shade400;
                      final tooltip = hasResponse
                          ? 'view_form'.tr()
                          : 'no_response_found'.tr();

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(title),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_red_eye, color: iconColor),
                            tooltip: tooltip,
                            onPressed: () =>
                                _goToStudentActivityForm(activityId),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
