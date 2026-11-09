//Course->Student->Activities

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:collection/collection.dart';
// ✅ Menú lateral

class ActivityDetailByStudentPage extends StatefulWidget {
  final String courseId;
  final String studentId;

  const ActivityDetailByStudentPage({
    super.key,
    required this.courseId,
    required this.studentId,
  });

  @override
  State<ActivityDetailByStudentPage> createState() => _ActivityDetailByStudentPageState();
}

class _ActivityDetailByStudentPageState extends State<ActivityDetailByStudentPage> {
  List<_ChartData> chartData = [];
  bool _loading = true;
  List<DocumentSnapshot> _activities = [];
  Set<String> _respondedActivityIds = {}; // ✅ Actividades con respuesta

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final assocSnap = await FirebaseFirestore.instance
          .collection('course_activities')
          .where('courseId', isEqualTo: widget.courseId)
          .get();

      final activityIds = assocSnap.docs.map((doc) => doc['activityId'] as String).toList();

      if (activityIds.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final responsesSnap = await FirebaseFirestore.instance
          .collection('activity_responses')
          .where('courseId', isEqualTo: widget.courseId)
          .where('userId', isEqualTo: widget.studentId)
          .where('activityId', whereIn: activityIds)
          .get();

      final respondedActivityIds = responsesSnap.docs
          .map((doc) => doc['activityId'] as String)
          .toSet();

      final activitiesSnap = await FirebaseFirestore.instance
          .collection('activities')
          .where(FieldPath.documentId, whereIn: activityIds)
          .get();

      List<_ChartData> chartList = [];

      for (var doc in responsesSnap.docs) {
        final data = doc.data();
        final activityId = data['activityId'];
        final matchingActivity = activitiesSnap.docs.firstWhereOrNull((a) => a.id == activityId);
        final title = matchingActivity?.data()['title'] ?? 'Sin título';

        final responses = data['responses'];
        if (responses is Map<String, dynamic>) {
          final progressMap = responses['progress'];
          if (progressMap is Map<String, dynamic>) {
            final scores = progressMap.values
                .map((v) => v is num ? v.toDouble() : double.tryParse(v.toString()))
                .whereType<double>()
                .toList();

            final avg = scores.isNotEmpty
                ? scores.reduce((a, b) => a + b) / scores.length
                : 0.0;

            chartList.add(_ChartData(title, avg));
          }
        }
      }

      setState(() {
        chartData = chartList;
        _activities = activitiesSnap.docs;
        _respondedActivityIds = respondedActivityIds;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_loading_data'.tr(args: [e.toString()]))),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('student_activities'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'back'.tr(),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*Text(
              'student_activities'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),*/
            const SizedBox(height: 10),
            Expanded(
              child: _activities.isEmpty
                  ? Text('no_activities_found'.tr())
                  : ListView.builder(
                itemCount: _activities.length,
                  itemBuilder: (ctx, i) {
                    final data = _activities[i].data() as Map<String, dynamic>;
                    final activityId = _activities[i].id;
                    final formPage = data['formPage'];

                    final title = formPage is String
                        ? context.tr(formPage)
                        : (data['title'] ?? context.tr('no_title'));

                    final hasResponse = _respondedActivityIds.contains(activityId);

                    return ListTile(
                      title: Text(title),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_red_eye),
                        color: hasResponse ? Colors.blue : Colors.grey,
                        tooltip: hasResponse
                            ? 'view_form'.tr()
                            : (formPage == null ? 'Página de formulario no definida' : 'no_response_found'.tr()),
                        onPressed: hasResponse && formPage != null
                            ? () {
                          Navigator.pushNamed(
                            context,
                            '/view-activity-response',
                            arguments: {
                              'activityId': activityId,
                              'courseId': widget.courseId,
                              'studentId': widget.studentId,
                              'formPage': formPage,
                            },
                          );
                        }
                            : null,
                      ),
                    );
                  }

              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ChartData {
  final String title;
  final double score;

  _ChartData(this.title, this.score);
}
