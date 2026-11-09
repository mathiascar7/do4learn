// C:/flutter projects/four_learn/lib/forms/feedback_form_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../screens/widgets/app_drawer.dart';

class FeedbackFormPage extends StatefulWidget {
  final String activityId;
  final String courseId;
  final String? studentId;
  final bool isReadOnly;

  const FeedbackFormPage({
    super.key,
    required this.activityId,
    required this.courseId,
    this.studentId,
    this.isReadOnly = false,
  });

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  int _mood = 0;
  int _rating = 3;
  bool _recommend = false;
  bool _isSubmitting = false;
  bool _isSuccess = false; // ✅ Nueva bandera
  String _message = '';
  String? _responseDocId;

  @override
  void initState() {
    super.initState();
    _loadExistingResponse();
  }

  Future<void> _loadExistingResponse() async {
    final userId = widget.isReadOnly ? widget.studentId : FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      setState(() {
        _message = 'form_login_required'.tr();
        _isSuccess = false;
      });
      return;
    }

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
          _rating = responses?['rating'] ?? 4;
          _recommend = responses?['recommend'] ?? true;
          _mood = responses?['mood'] ?? 2;
          if (widget.isReadOnly) _message = '';
        });
      } else {
        // ✅ Valores por defecto si no hay respuesta
        setState(() {
          _rating = 4;
          _recommend = true;
          _mood = 2;
          if (widget.isReadOnly) _message = '';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'form_load_error'.tr(args: [e.toString()]);
        _isSuccess = false;
      });
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _isSubmitting = true;
      _message = '';
      _isSuccess = false;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _message = 'form_login_required'.tr();
        _isSubmitting = false;
        _isSuccess = false;
      });
      return;
    }

    final responseData = {
      'activityId': widget.activityId,
      'courseId': widget.courseId,
      'userId': userId,
      'responses': {
        'mood': _mood,
        'rating': _rating,
        'recommend': _recommend,
      },
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      if (_responseDocId != null) {
        await FirebaseFirestore.instance
            .collection('activity_responses')
            .doc(_responseDocId)
            .update(responseData);
      } else {
        final docRef = await FirebaseFirestore.instance
            .collection('activity_responses')
            .add(responseData);
        _responseDocId = docRef.id;
      }

      setState(() {
        _message = 'form_submit_success'.tr();
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _message = 'form_submit_error'.tr(namedArgs: {'error': e.toString()});
        _isSuccess = false;
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('form.feedback.template_name'.tr()),
        automaticallyImplyLeading: true,
      ),
      //drawer: widget.isReadOnly ? null : AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'form.feedback.template_description'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),

            Text('form.feedback.question_mood'.tr()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: widget.isReadOnly ? null : () => setState(() => _mood = 0),
                  child: Opacity(
                    opacity: _mood == 0 ? 1.0 : 0.4,
                    child: const Text('😞', style: TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: widget.isReadOnly ? null : () => setState(() => _mood = 1),
                  child: Opacity(
                    opacity: _mood == 1 ? 1.0 : 0.4,
                    child: const Text('😐', style: TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: widget.isReadOnly ? null : () => setState(() => _mood = 2),
                  child: Opacity(
                    opacity: _mood == 2 ? 1.0 : 0.4,
                    child: const Text('😊', style: TextStyle(fontSize: 40)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('form.feedback.question_rating'.tr()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: widget.isReadOnly ? null : () => setState(() => _rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 20),
            Text('form.feedback.question_recommend'.tr()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.thumb_up, color: _recommend ? Colors.green : Colors.grey),
                  onPressed: widget.isReadOnly ? null : () => setState(() => _recommend = true),
                ),
                IconButton(
                  icon: Icon(Icons.thumb_down, color: !_recommend ? Colors.red : Colors.grey),
                  onPressed: widget.isReadOnly ? null : () => setState(() => _recommend = false),
                ),
              ],
            ),

            const SizedBox(height: 20),
            if (_message.isNotEmpty)
              Center(
                child: Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green.shade600 : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const Spacer(),
            if (!widget.isReadOnly)
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                      : Text(_responseDocId != null ? 'form_update_btn'.tr() : 'form_submit_btn'.tr()),
                ),
              ),

          ],
        ),
      ),
    );
  }
}


