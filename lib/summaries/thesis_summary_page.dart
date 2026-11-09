//Course->Activities

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:flutter/rendering.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:four_learn/utils/file_exporter.dart';
import 'package:four_learn/forms/thesis_form_page.dart';
import 'package:flutter/foundation.dart'; // 👈 necesario para kIsWeb
import 'dart:convert'; // ✅ necesario para usar utf8.encode()



class ThesisSummaryPage extends StatefulWidget {
  final String courseId;
  final String activityId;

  const ThesisSummaryPage({
    super.key,
    required this.courseId,
    required this.activityId,
  });

  @override
  State<ThesisSummaryPage> createState() => _ThesisSummaryPageState();
}

class _ThesisSummaryPageState extends State<ThesisSummaryPage> {
  bool _isLoading = true;
  List<_PhaseRow> _rows = [];
  final List<_StudentProgress> _studentProgressList = [];
  final Map<String, String> _userNames = {};
  final Map<String, DateTime> _actionStart = {};
  final Map<String, DateTime> _actionEnd = {};
  final Map<String, double> _expectedPhaseProgress = {};





  final GlobalKey chartKey = GlobalKey();

  final Map<String, Map<String, List<String>>> _phasesTopicsActions = {
    'Preparación': {
      'Modalidad': ['Elegir la modalidad'],
      'Planificación espacio y tiempo': [
        'Establecer espacio y tiempo',
        'Definir cronograma general'
      ],
      'Bases y búsqueda': [
        'Aprender bases de datos académicas',
        'Revisión bibliográfica y selección de fuentes',
        'Herramienta de gestión de referencias'
      ],
      'Ética y uso IA': ['Uso ético y responsable de la IA'],
      'Publicación y backup': [
        'Identificar medio de publicación',
        'Copia de seguridad y versionamiento'
      ],
    },
    'Planificación y Diseño': {
      'Tema y problema': [
        'Elección del tema',
        'Planteamiento del problema',
        'Justificación del problema',
        'Pregunta de investigación',
        'Objetivo'
      ],
      'Marco y antecedentes': [
        'Antecedentes',
        'Marco teórico',
        'Revisión cobertura / referencias'
      ],
      'Metodología': [
        'Metodología',
        'Procedimiento de recolección',
        'Ética en recolección',
        'Efecto wow',
        'Diseñar procedimiento de recolección'
      ],
    },
    'Recolección de Datos': {
      'Recolección': [
        'Permisos para recolección',
        'Recolección según el plan'
      ],
      'Organización': [
        'Organización y registro de datos',
        'Verificación de calidad y consistencia'
      ],
    },
    'Análisis de Datos': {
      'Análisis': [
        'Uso del software adecuado',
        'Pruebas y análisis',
        'Interpretación de resultados',
        'Limitaciones'
      ],
    },
    'Redacción': {
      'Contenido': [
        'Introducción',
        'Cuerpo / capítulos',
        'Referencias',
        'Redacción clara y lógica',
        'Estructura del documento',
        'Citas y referencias',
        'Corrección gramatical y ortográfica'
      ],
    },
    'Revisión': {
      'Finalización': [
        'Cumplimiento del objetivo y conclusiones',
        'Revisión general'
      ],
    },
    'Presentación': {
      'Defensa': [
        'Preparación de la presentación',
        'Práctica de la defensa'
      ],
    },
    'Fase Final': {
      'Entrega': [
        'Revisión de evaluación final',
        'Entrega de la tesis'
      ],
    },
  };


  final Map<String, String> _actionToPhase = {};


  final Map<String, double> _actionWeights = {
    'Elegir la modalidad': 3.0,
    'Establecer espacio y tiempo': 2.0,
    'Definir cronograma general': 3.0,
    'Aprender bases de datos académicas': 4.0,
    'Revisión bibliográfica y selección de fuentes': 5.0,
    'Herramienta de gestión de referencias': 2.0,
    'Uso ético y responsable de la IA': 2.0,
    'Identificar medio de publicación': 3.0,
    'Copia de seguridad y versionamiento': 2.0,
    'Elección del tema': 4.0,
    'Planteamiento del problema': 4.0,
    'Justificación del problema': 3.0,
    'Pregunta de investigación': 3.0,
    'Objetivo': 3.0,
    'Antecedentes': 5.0,
    'Marco teórico': 5.0,
    'Revisión cobertura / referencias': 5.0,
    'Metodología': 4.0,
    'Procedimiento de recolección': 4.0,
    'Ética en recolección': 3.0,
    'Efecto wow': 2.0,
    'Diseñar procedimiento de recolección': 2.0,
    'Permisos para recolección': 2.0,
    'Recolección según el plan': 5.0,
    'Organización y registro de datos': 4.0,
    'Verificación de calidad y consistencia': 3.0,
    'Uso del software adecuado': 3.0,
    'Pruebas y análisis': 5.0,
    'Interpretación de resultados': 4.0,
    'Limitaciones': 3.0,
    'Introducción': 3.0,
    'Cuerpo / capítulos': 6.0,
    'Referencias': 3.0,
    'Redacción clara y lógica': 3.0,
    'Estructura del documento': 2.0,
    'Citas y referencias': 3.0,
    'Corrección gramatical y ortográfica': 2.0,
    'Cumplimiento del objetivo y conclusiones': 3.0,
    'Revisión general': 3.0,
    'Preparación de la presentación': 3.0,
    'Práctica de la defensa': 3.0,
    'Revisión de evaluación final': 2.0,
    'Entrega de la tesis': 1.0,
  };



  @override
  void initState() {
    super.initState();
    _mapActions();
    _loadResponses();
  }

  void _mapActions() {
    _phasesTopicsActions.forEach((phase, topics) {
      topics.forEach((_, actions) {
        for (var action in actions) {
          _actionToPhase[action] = phase;
        }
      });
    });
  }

  String _mapPhaseKeyToLabel(String key) {
    return 'form.thesis.phase.$key'.tr();
  }


  final List<String> _orderedPhases = [
    'Preparación',
    'Planificación y Diseño',
    'Recolección de Datos',
    'Análisis de Datos',
    'Redacción',
    'Revisión',
    'Presentación',
    'Fase Final',
  ];


  Future<String> _getStudentName(String userId) async {
    if (_userNames.containsKey(userId)) return _userNames[userId]!;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final name = doc.data()?['name'] ?? 'Sin nombre';
      _userNames[userId] = name;
      return name;
    } catch (e) {
      print('Error fetching user name for $userId: $e');
      return 'Sin nombre';
    }
  }


  Future<void> _loadResponses() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('activity_responses')
          .where('activityId', isEqualTo: widget.activityId)
          .where('courseId', isEqualTo: widget.courseId)
          .get();

      final responses = snapshot.docs
          .map((doc) => doc.data())
          .where((data) => data['responses'] is Map<String, dynamic>)
          .toList();

      final Map<String, double> phaseWeightedSum = {};
      final Map<String, double> phaseTotalWeight = {};
      _studentProgressList.clear();
      _actionStart.clear();
      _actionEnd.clear();
      _expectedPhaseProgress.clear();

      for (var r in responses) {
        final responsesMap = r['responses'] as Map<String, dynamic>;
        final progressMap = responsesMap['progress'];
        final userId = r['userId'];
        final studentName = userId is String
            ? await _getStudentName(userId)
            : 'Sin nombre';

        // 🧠 Calcular progreso esperado por fase
        final now = DateTime.now();
        responsesMap['phases']?.forEach((phaseKey, phaseData) {
          final phaseLabel = _mapPhaseKeyToLabel(phaseKey);
          if (phaseData is Map<String, dynamic>) {
            final start = phaseData['start'] is Timestamp ? (phaseData['start'] as Timestamp).toDate() : null;
            final end = phaseData['end'] is Timestamp ? (phaseData['end'] as Timestamp).toDate() : null;
            if (start != null && end != null && now.isAfter(start)) {
              final total = end.difference(start).inDays.toDouble();
              final elapsed = now.difference(start).inDays.toDouble().clamp(0, total);
              _expectedPhaseProgress[phaseLabel] = (elapsed / total) * 100;
            }
          }
        });

        double weightedSum = 0.0;
        double totalWeight = 0.0;
        List<Color> studentColors = [];

        if (progressMap is Map<String, dynamic>) {
          progressMap.forEach((actionId, value) {
            final parts = actionId.split('|');
            if (parts.length != 3) return;

            final phaseKey = parts[0];
            final topic = parts[1];
            final action = parts[2];
            final score = value is num ? value.toDouble() : double.tryParse(value.toString());
            if (score == null) return;

            final weight = _actionWeights[action] ?? 1.0;
            final phaseLabel = _mapPhaseKeyToLabel(phaseKey);

            // 🧮 Promedio ponderado por fase
            phaseWeightedSum[phaseLabel] = (phaseWeightedSum[phaseLabel] ?? 0.0) + score * weight;
            phaseTotalWeight[phaseLabel] = (phaseTotalWeight[phaseLabel] ?? 0.0) + weight;

            // 🕓 Extraer fechas
            final actionData = responsesMap['phases']?[phaseKey]?['topics']?[topic]?[action];
            if (actionData is Map<String, dynamic>) {
              if (actionData['start'] is Timestamp) {
                _actionStart[actionId] = (actionData['start'] as Timestamp).toDate();
              }
              if (actionData['end'] is Timestamp) {
                _actionEnd[actionId] = (actionData['end'] as Timestamp).toDate();
              }
            }

            // 🎨 Color inteligente
            final color = _getColorForProgress(actionId, score);
            studentColors.add(color);

            // 📊 Promedio ponderado por estudiante
            weightedSum += score * weight;
            totalWeight += weight;
          });
        }

        if (totalWeight > 0) {
          final avg = weightedSum / totalWeight;
          final color = studentColors.contains(Colors.red)
              ? Colors.red
              : studentColors.contains(Colors.orange)
              ? Colors.orange
              : Colors.green;

          _studentProgressList.add(_StudentProgress(
            name: studentName,
            progress: avg,
            color: color,
            userId: userId,
          ));
        }
      }

      // 🧮 Construir _rows con promedio ponderado por fase
      _rows = phaseWeightedSum.entries.map((entry) {
        final phase = entry.key;
        final totalWeight = phaseTotalWeight[phase] ?? 1.0;
        final avg = entry.value / totalWeight;
        return _PhaseRow(phase: phase, average: avg.toStringAsFixed(1));
      }).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading responses: $e');
    }
  }





  Future<void> _exportCSV() async {
    final headers = [
      'form.thesis.phasetxt'.tr(),
      'form.thesis.average'.tr()
    ];
    final rows = _rows.map((r) => [r.phase, r.average]).toList();
    final csvData = const ListToCsvConverter().convert([headers, ...rows]);

    await FileExporter.saveTextFile(
      context: context,
      filename: '${'form.thesis.exportPhaseFilename'.tr()}.csv',
      content: csvData,
      //successMessage: 'form.thesis.exportPhaseSuccess'.tr(),
      successMessage: 'form.thesis.exportPhaseSuccess',
    );
  }


  Future<void> _exportChartAsImage() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('form.thesis.imageExportNotAvailable'.tr())),
      );
      return;
    }

    try {
      RenderRepaintBoundary boundary = chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        print('form.thesis.chartExportError'.tr(args: ['ByteData is null']));
        return;
      }

      final buffer = byteData.buffer;

      await FileExporter.saveBinaryFile(
        context: context,
        filename: '${'form.thesis.chartFileName'.tr()}.jpg',
        bytes: buffer.asUint8List(),
        //successMessage: 'form.thesis.chartExportSuccess'.tr(),
        successMessage: 'form.thesis.chartExportSuccess',
      );
    } catch (e) {
      print('form.thesis.chartExportError'.tr(args: [e.toString()]));
    }
  }





  String _colorLabel(Color color) {
    if (color == Colors.green) return 'Verde';
    if (color == Colors.amber || color == Colors.orange) return 'Amarillo'; // o 'Naranja'
    if (color == Colors.grey || color.value == const Color(0xFF9E9E9E).value) return 'Gris';
    return 'Rojo';
  }





  Widget _buildBarChart() {
    final sorted = _rows.where((r) => double.tryParse(r.average)! > 0).toList();
    sorted.sort((a, b) => double.parse(b.average).compareTo(double.parse(a.average)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sorted.map((r) {
        final value = double.parse(r.average);
        final expected = _expectedPhaseProgress[r.phase] ?? 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 160,
                child: Text(r.phase, style: const TextStyle(fontSize: 14)),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 24, color: Colors.grey[300]),
                    Container(height: 24, width: value * 2, color: Colors.blue),
                    Positioned(
                      left: expected * 2,
                      child: Container(width: 2, height: 24, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${value.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 14)),
                  Text('→ ${expected.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


  Future<void> _exportStudentCSV() async {
    final headers = [
      'form.thesis.student'.tr(),
      'form.thesis.progress'.tr(),
      'form.thesis.semaphore'.tr()
    ];

    final rows = _studentProgressList.map((s) => [
      s.name,
      s.progress.toStringAsFixed(1),
      _colorLabel(s.color),
    ]).toList();

    final csvData = const ListToCsvConverter().convert([headers, ...rows]);

    await FileExporter.saveTextFile(
      context: context,
      filename: '${'form.thesis.exportStudentFilename'.tr()}.csv',
      content: csvData,
      //successMessage: 'form.thesis.exportStudentSuccess'.tr(),
      successMessage: 'form.thesis.exportStudentSuccess',
    );
  }


  Future<void> _exportDetailedFormsCSV() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('activity_responses')
          .where('activityId', isEqualTo: widget.activityId)
          .where('courseId', isEqualTo: widget.courseId)
          .get();

      final responses = snapshot.docs
          .map((doc) => doc.data())
          .where((data) => data['responses'] is Map<String, dynamic>)
          .toList();

      final List<List<String>> rows = [
        [
          'form.thesis.formHeaderStudent'.tr(),
          'form.thesis.formHeaderPhase'.tr(),
          'form.thesis.formHeaderTopic'.tr(),
          'form.thesis.formHeaderAction'.tr(),
          'form.thesis.formHeaderProgress'.tr(),
          'form.thesis.formHeaderSemaphore'.tr()
        ]
      ];

      for (var r in responses) {
        final responsesMap = r['responses'] as Map<String, dynamic>;
        final progressMap = responsesMap['progress'];
        final userId = r['userId'];
        final studentName = userId is String
            ? await _getStudentName(userId)
            : 'formFallbackName'.tr();

        progressMap.forEach((actionId, value) {
          final parts = actionId.split('|');
          if (parts.length != 3) return;

          final phaseKey = parts[0];
          final topic = parts[1];
          final action = parts[2];
          final score = value is num ? value.toDouble() : double.tryParse(value.toString());
          if (score == null) return;

          final phaseLabel = _mapPhaseKeyToLabel(phaseKey);
          final topicLabel = 'form.thesis.topic.${_normalizeKey(topic)}'.tr();
          final actionLabel = 'form.thesis.action.${_normalizeKey(action)}'.tr();
          
          // ✅ Ahora sí se puede calcular el color correctamente
          final color = _getColorForProgress(actionId, score);

          final semaforo = _colorLabel(color);

          rows.add([
            studentName,
            phaseLabel,
            topicLabel,
            actionLabel,
            score.toStringAsFixed(1),
            semaforo,
          ]);
        });

      }

      final csvData = const ListToCsvConverter().convert(rows);
      final bom = [0xEF, 0xBB, 0xBF]; // marca UTF-8 para Excel
      final utf8Bytes = bom + utf8.encode(csvData);

      await FileExporter.saveBinaryFile(
        context: context,
        filename: '${'form.thesis.exportDetailedFilename'.tr()}.csv',
        bytes: utf8Bytes,
        //successMessage: 'form.thesis.exportDetailedSuccess'.tr(namedArgs: {'path': 'Descargas'}),
        successMessage: 'form.thesis.exportDetailedSuccess',
      );

    } catch (e) {
      print('form.thesis.exportDetailedError'.tr(args: [e.toString()]));
    }
  }


  String _normalizeKey(String raw) {
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w]+'), '_') // reemplaza espacios y símbolos por "_"
        .replaceAll(RegExp(r'_+'), '_')     // colapsa múltiples "_"
        .trim();
  }


  @override
  Widget build(BuildContext context) {
    _rows.sort((a, b) {
      final ai = _orderedPhases.indexOf(a.phase);
      final bi = _orderedPhases.indexOf(b.phase);
      return ai.compareTo(bi);
    });

    _studentProgressList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: Text('form.thesis.template_name'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'back'.tr(),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔷 Gráfico de promedio por fase
            Text('form.thesis.chartTitle'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            RepaintBoundary(
              key: chartKey,
              child: _buildBarChart(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: Text('form.thesis.exportChart'.tr()),
              onPressed: _exportChartAsImage,
            ),

            const SizedBox(height: 32),
            // 🔷 Tabla de promedio por fase
            _rows.isEmpty
                ? Text('noDataAvailable'.tr())
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                headingRowHeight: 40,
                dataRowHeight: 48,
                columns: [
                  DataColumn(label: Text('form.thesis.phasetxt'.tr())),
                  DataColumn(label: Text('form.thesis.average'.tr())),
                ],
                rows: _rows.map((row) {
                  return DataRow(cells: [
                    DataCell(SizedBox(
                      width: 200,
                      child: Text(
                        row.phase,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(Text(row.average)),
                  ]);
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: Text('form.thesis.exportCsv'.tr()),
              onPressed: _exportCSV,
            ),

            const SizedBox(height: 32),
            // 🔷 Tabla de progreso por estudiante
            Text('form.thesis.studentProgressTableTitle'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                headingRowHeight: 40,
                dataRowHeight: 48,
                columns: [
                  DataColumn(label: Text('form.thesis.student'.tr())),
                  DataColumn(label: Text('form.thesis.progress'.tr())),
                  DataColumn(label: Text('form.thesis.semaphore'.tr())),
                ],
                rows: _studentProgressList.map<DataRow>((student) {
                  return DataRow(cells: [
                    DataCell(Row(
                      children: [
                        Text(student.name),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.visibility, size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ThesisFormPage(
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
                    DataCell(Text('${student.progress.toStringAsFixed(1)}%')),
                    DataCell(Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: student.color,
                        shape: BoxShape.circle,
                      ),
                    )),
                  ]);
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: Text('form.thesis.exportStudentCsv'.tr()),
              onPressed: _exportStudentCSV,
            ),

            const SizedBox(height: 32),
            // 🔷 Exportar formularios detallados
            Text('form.thesis.detailedFormsTitle'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: Text('form.thesis.exportDetailedForms'.tr()),
              onPressed: _exportDetailedFormsCSV,
            ),

          ],
        ),
      ),
    );
  }



  Color _getColorForProgress(String actionId, double progress) {
    final now = DateTime.now();
    final startDate = _actionStart[actionId];
    final endDate = _actionEnd[actionId];

    if (startDate == null || endDate == null) return Colors.grey;

    // 🔧 Normaliza fechas a día sin hora
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    if (today.isBefore(start)) return Colors.grey;

    final totalDuration = end.difference(start).inDays.toDouble();
    final elapsed = today.difference(start).inDays.toDouble().clamp(0, totalDuration);
    final expectedProgress = (elapsed / totalDuration) * 100;
    final delta = progress - expectedProgress;

    if (delta >= 20) return Colors.green;       // Adelantado
    if (delta >= -10) return Colors.amber;      // Dentro del rango aceptable
    return Colors.red;                          // Atrasado
  }



}

class _PhaseRow {
  final String phase;
  final String average;
  _PhaseRow({required this.phase, required this.average});
}

class _StudentProgress {
  final String name;
  final double progress;
  final Color color;
  final String userId;

  _StudentProgress({
    required this.name,
    required this.progress,
    required this.color,
    required this.userId,
  });
}


