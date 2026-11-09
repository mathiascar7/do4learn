// C:/flutter projects/four_learn/lib/forms/style_form_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../screens/widgets/app_drawer.dart';

class StyleFormPage extends StatefulWidget {
  final String activityId;
  final String courseId;
  // 🔽 1. Añadir parámetros
  final String? studentId;
  final bool isReadOnly;

  const StyleFormPage({
    super.key,
    required this.activityId,
    required this.courseId,
    this.studentId,
    this.isReadOnly = false,
  });

  @override
  State<StyleFormPage> createState() => _StyleFormPageState();
}

class _StyleFormPageState extends State<StyleFormPage> {
  int _rating = 3;
  bool _recommend = false;
  bool _isSubmitting = false;
  String _message = '';
  String? _responseDocId; // Para saber si actualizar o crear

  @override
  void initState() {
    super.initState();
    _loadExistingResponse();
  }

  // 🔽 2. Función para cargar datos (NUEVA)
  Future<void> _loadExistingResponse() async {
    final userId = widget.isReadOnly ? widget.studentId : FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('activity_responses')
          .where('activityId', isEqualTo: widget.activityId)
          .where('courseId', isEqualTo: widget.courseId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        final responses = data['responses'] as Map<String, dynamic>?;

        setState(() {
          _responseDocId = doc.id;
          _rating = responses?['rating'] ?? 3;
          _recommend = responses?['recommend'] ?? false;
        });
      }
    } catch (e) {
      setState(() => _message = 'Error al cargar: $e');
    }
  }

  // 🔽 3. Función de envío actualizada
  Future<void> _submitForm() async {
    setState(() {
      _isSubmitting = true;
      _message = '';
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      //... (manejo de error)
      return;
    }

    try {
      final payload = {
        'responses': {'rating': _rating, 'recommend': _recommend},
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_responseDocId != null) {
        await FirebaseFirestore.instance
            .collection('activity_responses')
            .doc(_responseDocId)
            .update(payload);
        setState(() => _message = '¡Evaluación actualizada!');
      } else {
        await FirebaseFirestore.instance.collection('activity_responses').add({
          'activityId': widget.activityId,
          'courseId': widget.courseId,
          'userId': currentUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
          ...payload
        });
        setState(() => _message = '¡Gracias por tu evaluación!');
      }
    } catch (e) {
      //... (manejo de error)
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 🔽 4. Título dinámico
        title: Text('form.style.template_name'.tr()),
        automaticallyImplyLeading: true,
      ),
      //drawer: widget.isReadOnly ? null : AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Valora el curso (1 a 5):'),
            Slider(
              value: _rating.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _rating.toString(),
              // 🔽 5. Deshabilitar interacción
              onChanged: widget.isReadOnly ? null : (value) {
                setState(() => _rating = value.toInt());
              },
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('¿Recomendarías el curso?'),
              value: _recommend,
              // 🔽 6. Deshabilitar interacción
              onChanged: widget.isReadOnly ? null : (value) {
                setState(() => _recommend = value);
              },
            ),
            const SizedBox(height: 20),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(/* ... */),
              ),
            const Spacer(),
            // 🔽 7. Ocultar el botón de envío
            if (!widget.isReadOnly)
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_responseDocId != null ? 'Actualizar' : 'Enviar'),
              ),
          ],
        ),
      ),
    );
  }
}
