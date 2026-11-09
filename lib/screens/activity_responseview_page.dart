import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'widgets/app_drawer.dart';

class ActivityResponseViewPage extends StatelessWidget {
  final String activityId;
  final String courseId;
  final String studentId;

  const ActivityResponseViewPage({
    super.key,
    required this.activityId,
    required this.courseId,
    required this.studentId,
  });

  Map<String, Map<String, List<String>>> get _structure =>
      {
        'preparation': {
          'modality': ['choose_modality'],
          'space_time': ['set_space_time', 'define_schedule'],
          'sources': ['learn_databases'],
          'reference_selection': ['review_sources'],
          'reference_tool': ['reference_tool'],
          'ethics_ai': ['ethical_ai'],
          'publication': ['identify_journal'],
          'backup_versioning': ['backup_versioning'],
        },
        'design': {
          'problem': [
            'select_topic',
            'define_problem',
            'justify_problem',
            'research_question'
          ],
          'objectives': ['define_objectives'],
          'coverage': [
            'coverage_problem_justification_question_objective',
            'coverage_background'
          ],
          'framework': ['review_background', 'build_framework'],
          'references': ['reference_50'],
          'methodology': [
            'methodology_approach',
            'methodology_procedure',
            'methodology_ethics',
            'methodology_wow'
          ],
          'impact': ['results_communication'],
          'budget': ['timeline_budget'],
        },
        'collection': {
          'collection': ['get_permissions', 'execute_collection'],
          'organization': ['organize_data', 'verify_quality'],
        },
        'analysis': {
          'analysis': ['apply_tests', 'interpret_results'],
          'software': ['analysis_software'],
          'interpretation': ['analyze_limitations'],
        },
        'writing': {
          'introduction': ['write_intro'],
          'structure': ['follow_format'],
          'content': ['write_body', 'academic_style'],
          'references': ['complete_bibliography'],
          'grammar': ['check_grammar'],
        },
        'review': {
          'finalization': ['general_review', 'meet_objectives_conclusions'],
        },
        'presentation': {
          'defense': ['prepare_presentation', 'practice_defense'],
        },
        'final': {
          'delivery': ['review_evaluation', 'submit_thesis'],
        },
      };

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('activity_response_view'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'back'.tr(),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: AppDrawer(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadResponseData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'no_response_found'.tr(),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final phaseStart = data['phaseStart'] as Map<String, DateTime>;
          final phaseEnd = data['phaseEnd'] as Map<String, DateTime>;
          final actionStart = data['actionStart'] as Map<String, DateTime>;
          final actionEnd = data['actionEnd'] as Map<String, DateTime>;
          final progressMap = data['progressMap'] as Map<String, double>;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: ListView.builder(
              itemCount: _structure.length,
              itemBuilder: (context, phaseIndex) {
                final phase = _structure.keys.elementAt(phaseIndex);
                final topics = _structure[phase]!;
                final start = phaseStart[phase];
                final end = phaseEnd[phase];
                final phaseColor = _semaphoreColorForPhase(
                  phase,
                  topics,
                  actionStart,
                  actionEnd,
                  progressMap,
                );

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ExpansionTile(
                    initiallyExpanded: phaseIndex == 0,
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: phaseColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      'form.thesis.phase.$phase'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${'form.thesis.start'.tr()}: ${start != null ? dateFormat.format(start) : '-'}  •  ${'form.thesis.end'.tr()}: ${end != null ? dateFormat.format(end) : '-'}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var topic in topics.keys) ...[
                              Text(
                                'form.thesis.topic.$topic'.tr(),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              for (var action in topics[topic]!)
                                _buildReadOnlyActionRow(
                                  context,
                                  phase,
                                  topic,
                                  action,
                                  actionStart,
                                  actionEnd,
                                  progressMap,
                                  dateFormat,
                                ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }


  Future<Map<String, dynamic>> _loadResponseData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('activity_responses')
        .where('activityId', isEqualTo: activityId)
        .where('courseId', isEqualTo: courseId)
        .where('userId', isEqualTo: studentId)
        .limit(1)
        .get();

    final doc = snapshot.docs.firstOrNull;
    if (doc == null) return {};

    final data = doc.data()['responses'] as Map<String, dynamic>;
    final progressMapRaw = data['progress'] as Map<String, dynamic>;
    final progressMap = <String, double>{};
    for (var entry in progressMapRaw.entries) {
      progressMap[entry.key] = (entry.value as num).toDouble();
    }

    final phaseStart = <String, DateTime>{};
    final phaseEnd = <String, DateTime>{};
    final actionStart = <String, DateTime>{};
    final actionEnd = <String, DateTime>{};

    final phasesRaw = data['phases'] as Map<String, dynamic>;
    for (var phase in phasesRaw.keys) {
      final phaseData = phasesRaw[phase] as Map<String, dynamic>;
      final start = phaseData['start'];
      final end = phaseData['end'];
      if (start is Timestamp) phaseStart[phase] = start.toDate();
      if (end is Timestamp) phaseEnd[phase] = end.toDate();

      final topicsRaw = phaseData['topics'] as Map<String, dynamic>;
      for (var topic in topicsRaw.keys) {
        final actionsRaw = topicsRaw[topic] as Map<String, dynamic>;
        for (var action in actionsRaw.keys) {
          final actionData = actionsRaw[action] as Map<String, dynamic>;
          final id = '$phase|$topic|$action';
          final ts = actionData['start'];
          final te = actionData['end'];
          if (ts is Timestamp) actionStart[id] = ts.toDate();
          if (te is Timestamp) actionEnd[id] = te.toDate();
        }
      }
    }

    return {
      'phaseStart': phaseStart,
      'phaseEnd': phaseEnd,
      'actionStart': actionStart,
      'actionEnd': actionEnd,
      'progressMap': progressMap,
    };
  }

  double _expectedPercentForActionId(String actionId,
      Map<String, DateTime> actionStart,
      Map<String, DateTime> actionEnd,) {
    final ts = actionStart[actionId];
    final te = actionEnd[actionId];
    if (ts == null || te == null) return 0.0;
    final totalDays = te
        .difference(ts)
        .inDays;
    if (totalDays <= 0) return 0.0;
    final now = DateTime.now();
    if (now.isBefore(ts)) return 0.0;
    if (now.isAfter(te)) return 100.0;
    final elapsed = now
        .difference(ts)
        .inDays;
    final frac = elapsed / totalDays;
    return (frac * 100).clamp(0.0, 100.0);
  }

  Color _semaphoreColorForAction(String actionId,
      Map<String, DateTime> actionStart,
      Map<String, DateTime> actionEnd,
      Map<String, double> progressMap,) {
    final expected = _expectedPercentForActionId(
        actionId, actionStart, actionEnd);
    final real = progressMap[actionId] ?? 0.0;
    if (expected <= 0) return Colors.grey;
    final ratio = (expected == 0) ? 1.0 : (real / expected);
    if (ratio >= 0.9) return Colors.green;
    if (ratio >= 0.8) return Colors.amber;
    return Colors.red;
  }

  Color _semaphoreColorForPhase(String phase,
      Map<String, List<String>> topics,
      Map<String, DateTime> actionStart,
      Map<String, DateTime> actionEnd,
      Map<String, double> progressMap,) {
    double accRatio = 0;
    int count = 0;

    for (var topic in topics.keys) {
      for (var action in topics[topic]!) {
        final id = '$phase|$topic|$action';
        final expected = _expectedPercentForActionId(
            id, actionStart, actionEnd);
        final real = progressMap[id] ?? 0.0;

        if (expected <= 0) continue;

        final ratio = (expected == 0) ? 1.0 : (real / expected);
        accRatio += ratio;
        count++;
      }
    }

    if (count == 0) return Colors.grey;
    final avg = accRatio / count;
    if (avg >= 0.9) return Colors.green;
    if (avg >= 0.8) return Colors.amber;
    return Colors.red;
  }

  Widget _buildReadOnlyActionRow(
      BuildContext context,
      String phase,
      String topic,
      String actionKey,
      Map<String, DateTime> actionStart,
      Map<String, DateTime> actionEnd,
      Map<String, double> progressMap,
      DateFormat dateFormat,
      ) {
    final id = '$phase|$topic|$actionKey';
    final ts = actionStart[id];
    final te = actionEnd[id];
    final range = (ts != null && te != null)
        ? '${dateFormat.format(ts)} — ${dateFormat.format(te)}'
        : '-';
    final value = progressMap[id] ?? 0.0;
    final color = _semaphoreColorForAction(id, actionStart, actionEnd, progressMap);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('form.thesis.$actionKey'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            IconButton(
              icon: const Icon(Icons.help_outline, size: 20),
              tooltip: 'form.thesis.help'.tr(),
              onPressed: () => _showActionHelp(context, actionKey),
            ),
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(range, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 100,
          label: '${value.toStringAsFixed(0)}%',
          onChanged: null, // 🚫 deshabilitado
        ),
      ],
    );
  }

  void _showActionHelp(BuildContext context, String actionKey) {
    final title = 'form.thesis.$actionKey'.tr();
    final desc = 'form.thesis.${actionKey}_desc'.tr();
    final example = 'form.thesis.${actionKey}_ex'.tr();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${'form.thesis.help_for'.tr()} $title'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(desc),
              const SizedBox(height: 12),
              if (example.isNotEmpty) ...[
                Text('form.thesis.example_label'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(example),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('form.thesis.close'.tr()),
          ),
        ],
      ),
    );
  }


}

