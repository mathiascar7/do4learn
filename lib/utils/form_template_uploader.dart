import 'package:cloud_firestore/cloud_firestore.dart';

/// Script para subir la plantilla de tesis a Firestore.
/// Ejecutar una vez desde un entorno con permisos de Superadmin.
/// Guarda en: form_templates/thesis_form

Future<void> uploadThesisFormTemplate() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> orderedPhases = [];
  int weightCounter = 1;

  Map<String, dynamic> buildAction(String titleKey, String descKey, String exampleKey) {
    return {
      'title': titleKey,
      'description': descKey,
      'example': exampleKey,
      'weight': weightCounter++,
    };
  }

  Map<String, dynamic> buildTopic(String topicKey, List<Map<String, dynamic>> actions) {
    return {
      'name': topicKey,
      'actions': actions,
    };
  }

  void addPhase(String phaseKey, List<Map<String, dynamic>> topics) {
    orderedPhases.add({
      'name': phaseKey,
      'topics': topics,
    });
  }

  // Fase: Preparación
  addPhase('form.thesis.phase.preparation', [
    buildTopic('form.thesis.topic.modality', [
      buildAction('form.thesis.choose_modality', 'form.thesis.choose_modality_desc', 'form.thesis.choose_modality_ex'),
    ]),
    buildTopic('form.thesis.topic.space_time', [
      buildAction('form.thesis.set_space_time', 'form.thesis.set_space_time_desc', 'form.thesis.set_space_time_ex'),
      buildAction('form.thesis.define_schedule', 'form.thesis.define_schedule_desc', 'form.thesis.define_schedule_ex'),
    ]),
    buildTopic('form.thesis.topic.sources', [
      buildAction('form.thesis.learn_databases', 'form.thesis.learn_databases_desc', 'form.thesis.learn_databases_ex'),
      buildAction('form.thesis.review_sources', 'form.thesis.review_sources_desc', 'form.thesis.review_sources_ex'),
      buildAction('form.thesis.reference_tool', 'form.thesis.reference_tool_desc', 'form.thesis.reference_tool_ex'),
    ]),
    buildTopic('form.thesis.topic.ethics_ai', [
      buildAction('form.thesis.ethical_ai', 'form.thesis.ethical_ai_desc', 'form.thesis.ethical_ai_ex'),
    ]),
    buildTopic('form.thesis.topic.publication_backup', [
      buildAction('form.thesis.identify_journal', 'form.thesis.identify_journal_desc', 'form.thesis.identify_journal_ex'),
      buildAction('form.thesis.backup_versioning', 'form.thesis.backup_versioning_desc', 'form.thesis.backup_versioning_ex'),
    ]),
  ]);

  // Fase: Planificación y Diseño
  addPhase('form.thesis.phase.design', [
    buildTopic('form.thesis.topic.problem', [
      buildAction('form.thesis.select_topic', 'form.thesis.select_topic_desc', 'form.thesis.select_topic_ex'),
      buildAction('form.thesis.define_problem', 'form.thesis.define_problem_desc', 'form.thesis.define_problem_ex'),
      buildAction('form.thesis.justify_problem', 'form.thesis.justify_problem_desc', 'form.thesis.justify_problem_ex'),
      buildAction('form.thesis.research_question', 'form.thesis.research_question_desc', 'form.thesis.research_question_ex'),
    ]),
    buildTopic('form.thesis.topic.framework', [
      buildAction('form.thesis.review_background', 'form.thesis.review_background_desc', 'form.thesis.review_background_ex'),
      buildAction('form.thesis.build_framework', 'form.thesis.build_framework_desc', 'form.thesis.build_framework_ex'),
    ]),
    buildTopic('form.thesis.topic.methodology', [
      buildAction('form.thesis.describe_methodology', 'form.thesis.describe_methodology_desc', 'form.thesis.describe_methodology_ex'),
      buildAction('form.thesis.design_collection', 'form.thesis.design_collection_desc', 'form.thesis.design_collection_ex'),
    ]),
  ]);

  // Fase: Recolección de Datos
  addPhase('form.thesis.phase.collection', [
    buildTopic('form.thesis.topic.collection', [
      buildAction('form.thesis.get_permissions', 'form.thesis.get_permissions_desc', 'form.thesis.get_permissions_ex'),
      buildAction('form.thesis.execute_collection', 'form.thesis.execute_collection_desc', 'form.thesis.execute_collection_ex'),
    ]),
    buildTopic('form.thesis.topic.organization', [
      buildAction('form.thesis.organize_data', 'form.thesis.organize_data_desc', 'form.thesis.organize_data_ex'),
      buildAction('form.thesis.verify_quality', 'form.thesis.verify_quality_desc', 'form.thesis.verify_quality_ex'),
    ]),
  ]);

  // Fase: Análisis de Datos
  addPhase('form.thesis.phase.analysis', [
    buildTopic('form.thesis.topic.analysis', [
      buildAction('form.thesis.apply_tests', 'form.thesis.apply_tests_desc', 'form.thesis.apply_tests_ex'),
      buildAction('form.thesis.interpret_results', 'form.thesis.interpret_results_desc', 'form.thesis.interpret_results_ex'),
    ]),
  ]);

  // Fase: Redacción
  addPhase('form.thesis.phase.writing', [
    buildTopic('form.thesis.topic.content', [
      buildAction('form.thesis.write_intro', 'form.thesis.write_intro_desc', 'form.thesis.write_intro_ex'),
      buildAction('form.thesis.write_body', 'form.thesis.write_body_desc', 'form.thesis.write_body_ex'),
      buildAction('form.thesis.write_references', 'form.thesis.write_references_desc', 'form.thesis.write_references_ex'),
    ]),
  ]);

  // Fase: Revisión
  addPhase('form.thesis.phase.review', [
    buildTopic('form.thesis.topic.finalization', [
      buildAction('form.thesis.general_review', 'form.thesis.general_review_desc', 'form.thesis.general_review_ex'),
    ]),
  ]);

  // Fase: Presentación
  addPhase('form.thesis.phase.presentation', [
    buildTopic('form.thesis.topic.defense', [
      buildAction('form.thesis.prepare_presentation', 'form.thesis.prepare_presentation_desc', 'form.thesis.prepare_presentation_ex'),
      buildAction('form.thesis.practice_defense', 'form.thesis.practice_defense_desc', 'form.thesis.practice_defense_ex'),
    ]),
  ]);

  // Fase: Fase Final
  addPhase('form.thesis.phase.final', [
    buildTopic('form.thesis.topic.delivery', [
      buildAction('form.thesis.review_evaluation', 'form.thesis.review_evaluation_desc', 'form.thesis.review_evaluation_ex'),
      buildAction('form.thesis.submit_thesis', 'form.thesis.submit_thesis_desc', 'form.thesis.submit_thesis_ex'),
    ]),
  ]);

  final Map<String, dynamic> template = {
    'name': 'form.thesis.template_name',
    'description': 'form.thesis.template_description',
    'phases': orderedPhases,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  try {
    await firestore.collection('form_templates').doc('thesis_form').set(template);
    print('✅ Plantilla thesis_form subida correctamente.');
  } catch (e) {
    print('❌ Error al subir la plantilla: $e');
  }
}
