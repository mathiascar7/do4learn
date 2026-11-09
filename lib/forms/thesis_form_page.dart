import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../screens/widgets/app_drawer.dart';

class ThesisFormPage extends StatefulWidget {
  final String activityId;
  final String courseId;
  final String? userId;
  final bool isReadOnly;

  const ThesisFormPage({
    super.key,
    required this.activityId,
    required this.courseId,
    this.userId,
    this.isReadOnly = false,
  });

  @override
  _ThesisFormPageState createState() => _ThesisFormPageState();
}

class _ThesisFormPageState extends State<ThesisFormPage> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  DateTime _globalStart = DateTime.now();
  DateTime _globalEnd = DateTime.now().add(const Duration(days: 180));

  final Map<String, DateTime> _actionStart = {};
  final Map<String, DateTime> _actionEnd = {};
  final Map<String, double> _progressMap = {};
  final Map<String, DateTime> _phaseStart = {};
  final Map<String, DateTime> _phaseEnd = {};

  String _currentlyExpandedPhaseKey = '';

  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _responseDocId;
  String _statusMessage = '';

  final Map<String, Map<String, List<String>>> _phasesTopicsActions = {
    'preparation': { 'modality': ['choose_modality'], 'space_time': ['set_space_time', 'define_schedule'], 'sources': ['learn_databases'], 'reference_selection': ['review_sources'], 'reference_tool': ['reference_tool'], 'ethics_ai': ['ethical_ai'], 'publication': ['identify_journal'], 'backup_versioning': ['backup_versioning'], },
    'design': { 'problem': ['select_topic', 'define_problem', 'justify_problem', 'research_question'], 'objectives': ['define_objectives'], 'coverage': ['coverage_problem_justification_question_objective', 'coverage_background'], 'framework': ['review_background', 'build_framework'], 'references': ['reference_50'], 'methodology': ['methodology_approach', 'methodology_procedure', 'methodology_ethics', 'methodology_wow'], 'impact': ['results_communication'], 'budget': ['timeline_budget'], },
    'collection': { 'collection': ['get_permissions', 'execute_collection'], 'organization': ['organize_data', 'verify_quality'], },
    'analysis': { 'analysis': ['apply_tests', 'interpret_results'], 'software': ['analysis_software'], 'interpretation': ['interpret_results', 'analyze_limitations'], },
    'writing': { 'introduction': ['write_intro'], 'structure': ['follow_format'], 'content': ['write_body', 'academic_style'], 'references': ['complete_bibliography'], 'grammar': ['check_grammar'], },
    'review': { 'finalization': ['general_review', 'meet_objectives_conclusions'], },
    'presentation': { 'defense': ['prepare_presentation', 'practice_defense'], },
    'final': { 'delivery': ['review_evaluation', 'submit_thesis'], },
  };

  final Map<String, double> _actionWeights = {
    'choose_modality': 3.0,
    'set_space_time': 2.0,
    'define_schedule': 3.0,
    'learn_databases': 4.0,
    'review_sources': 5.0,
    'reference_tool': 2.0,
    'ethical_ai': 2.0,
    'identify_journal': 3.0,
    'backup_versioning': 2.0,
    'select_topic': 4.0,
    'define_problem': 4.0,
    'justify_problem': 3.0,
    'research_question': 3.0,
    'define_objectives': 3.0,
    'coverage_problem_justification_question_objective': 2.0,
    'coverage_background': 4.0,
    'review_background': 5.0,
    'build_framework': 5.0,
    'reference_50': 5.0,
    'methodology_approach': 4.0,
    'methodology_procedure': 4.0,
    'methodology_ethics': 3.0,
    'methodology_wow': 2.0,
    'results_communication': 3.0,
    'timeline_budget': 2.0,
    'get_permissions': 2.0,
    'execute_collection': 5.0,
    'organize_data': 4.0,
    'verify_quality': 3.0,
    'apply_tests': 5.0,
    'interpret_results': 4.0,
    'analyze_limitations': 3.0,
    'write_intro': 3.0,
    'follow_format': 2.0,
    'write_body': 6.0,
    'academic_style': 3.0,
    'complete_bibliography': 3.0,
    'check_grammar': 2.0,
    'general_review': 3.0,
    'meet_objectives_conclusions': 3.0,
    'prepare_presentation': 3.0,
    'practice_defense': 3.0,
    'review_evaluation': 2.0,
    'submit_thesis': 1.0,
  };




  @override
  void initState() {
    super.initState();
    _loadFormData().then((_) {
      if (!mounted) return;
      if (_phaseStart.isEmpty || _phaseEnd.isEmpty) {
        _initializePhaseDates();
      }
      setState(() => _isLoading = false);
    });
  }

  // --- LÓGICA DE CARGA CORREGIDA ---
  Future<void> _loadFormData() async {
    final userId = widget.isReadOnly ? widget.userId : FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) setState(() { _isLoading = false; if (!widget.isReadOnly) _statusMessage = 'login_required'.tr(); });
      return;
    }
    try {
      // ✅ SE AÑADIÓ EL FILTRO POR courseId
      final querySnapshot = await FirebaseFirestore.instance
          .collection('activity_responses')
          .where('activityId', isEqualTo: widget.activityId)
          .where('courseId', isEqualTo: widget.courseId) // <-- ¡ESTA ES LA LÍNEA CRÍTICA!
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (!mounted || querySnapshot.docs.isEmpty) return;
      final doc = querySnapshot.docs.first;
      _responseDocId = doc.id;
      final data = doc.data()['responses'];
      if (data == null) return;
      final phasesRaw = data['phases'];
      final Map<String, DateTime> tempPhaseStart = {};
      final Map<String, DateTime> tempPhaseEnd = {};
      if (phasesRaw is Map) {
        for (var phase in phasesRaw.keys) {
          final phaseData = phasesRaw[phase];
          if (phaseData['start'] is Timestamp) tempPhaseStart[phase] = (phaseData['start'] as Timestamp).toDate();
          if (phaseData['end'] is Timestamp) tempPhaseEnd[phase] = (phaseData['end'] as Timestamp).toDate();
          if (phaseData['topics'] is Map) {
            for (var topic in phaseData['topics'].keys) {
              final actions = phaseData['topics'][topic];
              if (actions is Map) {
                for (var action in actions.keys) {
                  final actionData = actions[action];
                  final id = _actionId(phase, topic, action);
                  if (actionData['start'] is Timestamp) _actionStart[id] = (actionData['start'] as Timestamp).toDate();
                  if (actionData['end'] is Timestamp) _actionEnd[id] = (actionData['end'] as Timestamp).toDate();
                  if (actionData['progress'] is num) _progressMap[id] = (actionData['progress'] as num).toDouble();
                }
              }
            }
          }
        }
      }
      setState(() {
        if (data['global_start'] is Timestamp) _globalStart = (data['global_start'] as Timestamp).toDate();
        if (data['global_end'] is Timestamp) _globalEnd = (data['global_end'] as Timestamp).toDate();
        _phaseStart..clear()..addAll(tempPhaseStart);
        _phaseEnd..clear()..addAll(tempPhaseEnd);
        _recalculateActionDates();
        if (!widget.isReadOnly) _statusMessage = 'form_loaded'.tr();
      });
    } catch(e) {
      if (mounted && !widget.isReadOnly) setState(() => _statusMessage = 'form_load_error'.tr(args: [e.toString()]));
    }
  }

  // El resto del archivo permanece exactamente igual
  // ... (Future<void> _submit(), _actionId(), _initializePhaseDates(), etc.)

  Future<void> _submit() async {
    if (widget.isReadOnly) return;
    setState(() { _isSubmitting = true; _statusMessage = ''; });
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted) setState(() { _statusMessage = 'login_required'.tr(); _isSubmitting = false; });
        return;
      }
      final Map<String, dynamic> responses = { 'global_start': Timestamp.fromDate(_globalStart), 'global_end': Timestamp.fromDate(_globalEnd), 'phases': {}, 'progress': {}, };
      _phasesTopicsActions.forEach((phase, topics) {
        final phaseStart = _phaseStart[phase];
        final phaseEnd = _phaseEnd[phase];
        final phaseData = { 'start': phaseStart != null ? Timestamp.fromDate(phaseStart) : null, 'end': phaseEnd != null ? Timestamp.fromDate(phaseEnd) : null, 'topics': <String, dynamic>{}, };
        topics.forEach((topic, actions) {
          final topicData = <String, Map<String, dynamic>>{};
          for (var action in actions) {
            final id = _actionId(phase, topic, action);
            topicData[action] = { 'start': _actionStart[id] != null ? Timestamp.fromDate(_actionStart[id]!) : null, 'end': _actionEnd[id] != null ? Timestamp.fromDate(_actionEnd[id]!) : null, 'progress': _progressMap[id] ?? 0.0, };
            responses['progress'][id] = _progressMap[id] ?? 0.0;
          }
          (phaseData['topics'] as Map<String, dynamic>)[topic] = topicData;
        });
        responses['phases'][phase] = phaseData;
      });
      final payload = { 'responses': responses, 'updatedAt': FieldValue.serverTimestamp(), };
      if (_responseDocId != null) {
        await FirebaseFirestore.instance.collection('activity_responses').doc(_responseDocId).update(payload);
        if(mounted) setState(() => _statusMessage = 'form_submit_success'.tr());
      } else {
        final newDoc = await FirebaseFirestore.instance.collection('activity_responses').add({ 'activityId': widget.activityId, 'courseId': widget.courseId, 'userId': userId, 'createdAt': FieldValue.serverTimestamp(), ...payload });
        if(mounted) setState(() { _responseDocId = newDoc.id; _statusMessage = 'form_submit_success'.tr(); });
      }
    } catch (e) {
      if(mounted) setState(() => _statusMessage = 'form_submit_error'.tr(args: [e.toString()]));
    } finally {
      if(mounted) setState(() => _isSubmitting = false);
    }
  }

  String _actionId(String phase, String topic, String action) => '$phase|$topic|$action';

  void _initializePhaseDates() {
    if (_phasesTopicsActions.isEmpty) return;

    final totalDays = _globalEnd.difference(_globalStart).inDays.toDouble();

    // 🔢 1. Calcula el peso total por fase
    final Map<String, double> phaseWeights = {};
    double totalWeight = 0.0;

    for (var phase in _phasesTopicsActions.keys) {
      double phaseWeight = 0.0;
      final topics = _phasesTopicsActions[phase]!;
      for (var actions in topics.values) {
        for (var action in actions) {
          phaseWeight += _actionWeights[action] ?? 1.0;
        }
      }
      phaseWeights[phase] = phaseWeight;
      totalWeight += phaseWeight;
    }

    // 📆 2. Asigna fechas proporcionales
    DateTime currentStart = _globalStart;
    for (var phase in _phasesTopicsActions.keys) {
      final weight = phaseWeights[phase] ?? 1.0;
      final days = (weight / totalWeight) * totalDays;
      final currentEnd = currentStart.add(Duration(days: days.floor()));
      _phaseStart[phase] = currentStart;
      _phaseEnd[phase] = currentEnd;
      currentStart = currentEnd;
    }

    _recalculateActionDates();
  }

  void _adjustFollowingPhases(String changedPhase) {
    final changedEnd = _phaseEnd[changedPhase];
    if (changedEnd == null) return;

    final phaseKeys = _phasesTopicsActions.keys.toList();
    final changedIndex = phaseKeys.indexOf(changedPhase);
    if (changedIndex == -1 || changedIndex == phaseKeys.length - 1) return;

    final remainingPhases = phaseKeys.sublist(changedIndex + 1);
    final remainingDays = _globalEnd.difference(changedEnd).inDays.toDouble();

    // Recalcular pesos
    double totalRemainingWeight = 0.0;
    final Map<String, double> phaseWeights = {};
    for (var phase in remainingPhases) {
      double weight = 0.0;
      for (var actions in _phasesTopicsActions[phase]!.values) {
        for (var action in actions) {
          weight += _actionWeights[action] ?? 1.0;
        }
      }
      phaseWeights[phase] = weight;
      totalRemainingWeight += weight;
    }

    // Asignar nuevas fechas
    DateTime currentStart = changedEnd;
    for (var phase in remainingPhases) {
      final weight = phaseWeights[phase] ?? 1.0;
      final days = (weight / totalRemainingWeight) * remainingDays;
      final currentEnd = currentStart.add(Duration(days: days.floor()));
      _phaseStart[phase] = currentStart;
      _phaseEnd[phase] = currentEnd;
      currentStart = currentEnd;
    }

    _recalculateActionDates();
  }



  void _recalculateActionDates() {
    for (var phase in _phasesTopicsActions.keys) {
      final topics = _phasesTopicsActions[phase]!;
      final phaseStart = _phaseStart[phase] ?? _globalStart;
      final phaseEnd = _phaseEnd[phase] ?? _globalEnd;

      // 🔢 Calcula el total de peso en la fase
      double totalWeight = 0.0;
      for (var topic in topics.keys) {
        for (var action in topics[topic]!) {
          totalWeight += _actionWeights[action] ?? 1.0;
        }
      }

      if (totalWeight == 0) continue;

      final totalDays = phaseEnd.difference(phaseStart).inDays.toDouble();
      DateTime currentStart = phaseStart;

      for (var topic in topics.keys) {
        for (var action in topics[topic]!) {
          final id = _actionId(phase, topic, action);
          final weight = _actionWeights[action] ?? 1.0;
          final days = (weight / totalWeight) * totalDays;
          final actionEnd = currentStart.add(Duration(days: days.floor()));
          _actionStart[id] = currentStart;
          _actionEnd[id] = actionEnd;
          currentStart = actionEnd.add(const Duration(days: 1));
        }
      }
    }
  }


  Color _getActionColor(String actionId) {
    final now = DateTime.now();
    final startDate = _actionStart[actionId];
    final endDate = _actionEnd[actionId];
    final progress = _progressMap[actionId] ?? 0.0;

    if (startDate == null || endDate == null) return Colors.grey;

    if (now.isBefore(startDate)) return Colors.grey;

    final totalDuration = endDate.difference(startDate).inDays.toDouble();
    final elapsed = now.difference(startDate).inDays.toDouble().clamp(0, totalDuration);
    final expectedProgress = (elapsed / totalDuration) * 100;

    // 🔍 Comparación entre progreso real y esperado
    final delta = progress - expectedProgress;

    if (delta >= 20) return Colors.green;         // Va adelantado
    if (delta >= -10) return Colors.amber;         // Va dentro del rango aceptable
    return Colors.red;                             // Va atrasado
  }



  Color _getTopicColor(String phase, String topic) {
    final actions = _phasesTopicsActions[phase]?[topic] ?? [];
    if (actions.isEmpty) return Colors.grey;

    final actionColors = actions.map((action) {
      final id = _actionId(phase, topic, action);
      return _getActionColor(id);
    }).toList();

    if (actionColors.every((c) => c == Colors.grey)) return Colors.grey;
    if (actionColors.any((c) => c == Colors.red)) return Colors.red;
    if (actionColors.any((c) => c == Colors.amber)) return Colors.amber;
    return Colors.green;
  }


  Color _getPhaseColor(String phase) {
    final topics = _phasesTopicsActions[phase]?.keys ?? [];
    if (topics.isEmpty) return Colors.grey;

    final topicColors = topics.map((topic) => _getTopicColor(phase, topic)).toList();

    if (topicColors.every((c) => c == Colors.grey)) return Colors.grey;
    if (topicColors.any((c) => c == Colors.red)) return Colors.red;
    if (topicColors.any((c) => c == Colors.amber)) return Colors.amber;
    return Colors.green;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('form.thesis.template_name'.tr()),
        automaticallyImplyLeading: true,
      ),

      //drawer: widget.isReadOnly ? null : AppDrawer(),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'form.thesis.template_description'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),

                _buildDatePicker('form.thesis.global_start'.tr(), _globalStart, (date) => setState(() { _globalStart = date; _initializePhaseDates(); })),
                const SizedBox(height: 8),
                _buildDatePicker('form.thesis.global_end'.tr(), _globalEnd, (date) => setState(() { _globalEnd = date; _initializePhaseDates(); })),
                const SizedBox(height: 20),
                _buildPhasesPanel(),
              ],
            ),
          ),
          if (_statusMessage.isNotEmpty) Padding(padding: const EdgeInsets.all(8.0), child: Text(_statusMessage, style: TextStyle(color: _statusMessage.contains('Error') || _statusMessage.contains('error') ? Colors.red : Colors.green.shade800), textAlign: TextAlign.center)),
          if (!widget.isReadOnly)
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : Text(_responseDocId != null ? 'form_update_btn'.tr() : 'form_submit_btn'.tr()),
              ),
            ),



        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: widget.isReadOnly ? null : () async {
        final newDate = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2050));
        if (newDate != null) onSelect(newDate);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
        child: Text(_dateFormat.format(date)),
      ),
    );
  }

  Widget _buildPhasesPanel() {
    return ExpansionPanelList.radio(
      initialOpenPanelValue: _currentlyExpandedPhaseKey,
      expansionCallback: (int index, bool isExpanded) {
        final String phaseKey = _phasesTopicsActions.keys.elementAt(index);
        setState(() {
          _currentlyExpandedPhaseKey = isExpanded ? '' : phaseKey;
        });
      },
      children: _phasesTopicsActions.keys.map<ExpansionPanelRadio>((String phase) {
        return ExpansionPanelRadio(
          value: phase,
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: Row(
                children: [
                  Icon(Icons.circle, color: _getPhaseColor(phase), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('form.thesis.phase.$phase'.tr(), style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            );
          },
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Column(
              children: [
                _buildPhaseDates(phase),
                ...(_phasesTopicsActions[phase] ?? {}).entries.map((topicEntry) => _buildTopicSection(phase, topicEntry.key, topicEntry.value)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhaseDates(String phase) {
    return Row(
      children: [
        Expanded(
          child: _buildDatePicker(
            'form.thesis.start'.tr(),
            _phaseStart[phase] ?? _globalStart,
                (date) => setState(() {
              _phaseStart[phase] = date;
              _recalculateActionDates();
            }),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDatePicker(
            'form.thesis.end'.tr(),
            _phaseEnd[phase] ?? _globalEnd,
                (date) => setState(() {
              _phaseEnd[phase] = date;
              _adjustFollowingPhases(phase); // 👈 Aquí se actualizan las siguientes fases
            }),
          ),
        ),
      ],
    );
  }


  Widget _buildTopicSection(String phase, String topic, List<String> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.circle, color: _getTopicColor(phase, topic), size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text('form.thesis.topic.$topic'.tr(), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blueGrey.shade700))),
          ],
        ),
        ...actions.map((action) => _buildActionSlider(phase, topic, action)),
      ],
    );
  }

  Widget _buildActionSlider(String phase, String topic, String action) {
    final id = _actionId(phase, topic, action);
    final progress = _progressMap[id] ?? 0.0;
    final endDate = _actionEnd[id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
          child: Row(
            children: [
              Expanded(child: Text('form.thesis.action.$action'.tr())),
              IconButton(
                icon: const Icon(Icons.help_outline, size: 20, color: Colors.blueGrey),
                tooltip: 'form.thesis.action.${action}_desc'.tr(),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('form.thesis.action.$action'.tr()),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('form.thesis.action.${action}_desc'.tr(), style: const TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 12),
                            Text('form.thesis.action.${action}_ex'.tr(), style: TextStyle(color: Colors.grey.shade700)),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

            ],
          ),
        ),
        if (endDate != null)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
            child: Text(
              '${'form.thesis.end'.tr()}: ${_dateFormat.format(endDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        Slider(
          value: progress,
          min: 0,
          max: 100,
          divisions: 10,
          label: '${progress.round()}%',
          onChanged: (value) {
            if (widget.isReadOnly) return;
            setState(() => _progressMap[id] = value);
          },
        ),
      ],
    );
  }


}
