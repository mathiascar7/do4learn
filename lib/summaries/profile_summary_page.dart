import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:csv/csv.dart';
import 'package:four_learn/forms/profile_form_page.dart';
import 'package:four_learn/utils/file_exporter.dart';
import 'dart:convert';

class ProfileSummaryPage extends StatefulWidget {
  final String activityId;
  final String courseId;

  const ProfileSummaryPage({
    super.key,
    required this.activityId,
    required this.courseId,
  });

  @override
  State<ProfileSummaryPage> createState() => _ProfileSummaryPageState();
}

class _StudentProfile {
  final String name;
  final String userId;
  _StudentProfile({required this.name, required this.userId});
}

class _ProfileSummaryPageState extends State<ProfileSummaryPage> {
  bool _isLoading = true;
  int _totalResponses = 0;

  final Map<String, Map<String, int>> _singleCounts = {
    'importance': {},
    'time': {},
    'autonomy': {},
    'group': {},
    'difficulty': {},
    'motivation': {},
  };

  final Map<String, Map<String, int>> _multiCounts = {
    'sources': {},
    'tools': {},
    'styles': {},
    'sharing': {},
    'feedback': {},
  };

  final List<_StudentProfile> _studentProfiles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('activity_responses')
          .where('activityId', isEqualTo: widget.activityId)
          .where('courseId', isEqualTo: widget.courseId)
          .get();

      _totalResponses = snapshot.docs.length;
      final Set<String> seenUserIds = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final responses = data['responses'] as Map<String, dynamic>?;
        final userId = data['userId'];

        if (responses != null) {
          for (var key in _singleCounts.keys) {
            final value = responses[key];
            if (value is String) {
              _singleCounts[key]![value] = (_singleCounts[key]![value] ?? 0) + 1;
            }
          }

          for (var key in _multiCounts.keys) {
            final list = responses[key];
            if (list is List) {
              for (var item in list) {
                if (item is String) {
                  _multiCounts[key]![item] = (_multiCounts[key]![item] ?? 0) + 1;
                }
              }
            }
          }

          if (userId is String && !seenUserIds.contains(userId)) {
            final name = await _getStudentName(userId);
            _studentProfiles.add(_StudentProfile(name: name, userId: userId));
            seenUserIds.add(userId);
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading profile summary: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getStudentName(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return doc.data()?['name'] ?? 'Sin nombre';
    } catch (_) {
      return 'Sin nombre';
    }
  }


  Future<void> _exportFullResponsesCSV() async {
    final List<List<String>> rows = [];

    // ✅ Encabezado traducido
    final studentColumn = tr('form.profile.export.column_student');
    final header = [
      studentColumn,
      ..._singleCounts.keys.map((key) => tr('form.profile.question_$key')),
      ..._multiCounts.keys.map((key) => tr('form.profile.question_$key')),
    ];
    rows.add(header);

    final snapshot = await FirebaseFirestore.instance
        .collection('activity_responses')
        .where('activityId', isEqualTo: widget.activityId)
        .where('courseId', isEqualTo: widget.courseId)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final userId = data['userId'];
      final responses = data['responses'] as Map<String, dynamic>?;

      if (userId is String && responses != null) {
        final name = await _getStudentName(userId);
        final row = <String>[name];

        // ✅ Preguntas individuales traducidas
        for (var key in _singleCounts.keys) {
          final value = responses[key];
          if (value is String) {
            final translated = 'form.profile.option_$key.$value'.tr();
            row.add(translated);
          } else {
            row.add('');
          }
        }

        // ✅ Preguntas múltiples traducidas
        for (var key in _multiCounts.keys) {
          final list = responses[key];
          if (list is List) {
            final translatedList = list
                .whereType<String>()
                .map((item) => 'form.profile.option_$key.$item'.tr())
                .toList();
            row.add(translatedList.join(', '));
          } else {
            row.add('');
          }
        }

        rows.add(row);
      }
    }

    // ✅ Codificación UTF-8 con BOM
    final csvData = const ListToCsvConverter().convert(rows);
    final bom = [0xEF, 0xBB, 0xBF];
    final utf8Bytes = bom + utf8.encode(csvData);

    await FileExporter.saveBinaryFile(
      context: context,
      filename: '${'form.profile.export.filename'.tr()}.csv',
      bytes: utf8Bytes,
      successMessage: 'form.profile.export.success',
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('form.profile.summary.title'.tr())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('form.profile.summary.overview'.tr(),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('${'form.profile.summary.total_responses'.tr()}: $_totalResponses'),
            const SizedBox(height: 24),

            _buildSection('form.profile.section_about'.tr(), [
              _buildBarGroup('importance'),
              _buildBarGroup('time'),
              _buildBarGroup('autonomy'),
            ]),
            _buildSection('form.profile.section_study'.tr(), [
              _buildBarGroup('sources'),
              _buildBarGroup('tools'),
              _buildBarGroup('group'),
            ]),
            _buildSection('form.profile.section_learning'.tr(), [
              _buildBarGroup('styles'),
              _buildBarGroup('sharing'),
              _buildBarGroup('feedback'),
            ]),
            _buildSection('form.profile.section_expectations'.tr(), [
              _buildBarGroup('difficulty'),
              _buildBarGroup('motivation'),
            ]),

            Text('form.profile.summary.student_table'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                headingRowHeight: 40,
                dataRowHeight: 48,
                columns: [
                  DataColumn(label: Text('Estudiante')),
                ],
                rows: _studentProfiles.map((student) {
                  return DataRow(cells: [
                    DataCell(Row(
                      children: [
                        Text(student.name),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 20),
                          tooltip: 'Ver formulario',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileFormPage(
                                  userId: student.userId,
                                  courseId: widget.courseId,
                                  activityId: widget.activityId,
                                  isReadOnly: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: Text('form.profile.exportFullResponsesCsv'.tr()),
              onPressed: _exportFullResponsesCSV,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBarGroup(String key) {
    final Map<String, int> rawData =
        _singleCounts[key] ?? _multiCounts[key] ?? {};
    if (rawData.isEmpty || _totalResponses == 0) return const SizedBox.shrink();

    final entries = rawData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
    Text('form.profile.question_$key'.tr(),
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    ...entries.map((e) {
    final label = 'form.profile.option_$key.${e.key}'.tr();
    final percent = (e.value / _totalResponses) * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 160, child: Text(label)),
          Expanded(
            child: Stack(
              children: [
                Container(height: 20, color: Colors.grey[300]),
                Container(height: 20, width: percent * 2, color: Colors.blue),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${percent.toStringAsFixed(1)}%'),
        ],
      ),
    );
    }),
          const SizedBox(height: 16),
        ],
    );
  }
}

