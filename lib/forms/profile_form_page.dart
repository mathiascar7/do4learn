import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfileFormPage extends StatefulWidget {
  final String activityId;
  final String courseId;
  final String? userId;
  final bool isReadOnly;

  const ProfileFormPage({
    super.key,
    required this.activityId,
    required this.courseId,
    this.userId,
    this.isReadOnly = false,
  });

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final Map<String, dynamic> _responses = {};
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String _message = '';
  String? _responseDocId;

  final Map<String, List<String>> _multiKeys = {
    'sources': [],
    'tools': [],
    'styles': [],
    'sharing': [],
    'feedback': [],
  };

  @override
  void initState() {
    super.initState();
    _loadExistingResponse();
  }

  Future<void> _loadExistingResponse() async {
    final userId = widget.isReadOnly ? widget.userId : FirebaseAuth.instance.currentUser?.uid;
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
          _responses.addAll(responses ?? {});
          _multiKeys.forEach((key, _) {
            _multiKeys[key] = List<String>.from(_responses[key] ?? []);
          });
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
        ..._responses,
        ..._multiKeys.map((key, value) => MapEntry(key, value)),
      },
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      if (_responseDocId != null) {
        await FirebaseFirestore.instance
            .collection('activity_responses')
            .doc(_responseDocId!)
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

  Widget _buildSectionTitle(IconData icon, String titleKey, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        titleKey.tr(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSingleChoice(String key, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'form.profile.question_$key'.tr(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        ...options.map((option) {
          return RadioListTile<String>(
            title: Text(
              'form.profile.option_$key.$option'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            value: option,
            groupValue: _responses[key],
            onChanged: widget.isReadOnly ? null : (val) => setState(() => _responses[key] = val),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMultiChoice(String key, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'form.profile.question_$key'.tr(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        ...options.map((option) {
          final selected = _multiKeys[key]?.contains(option) ?? false;
          return CheckboxListTile(
            title: Text(
              'form.profile.option_$key.$option'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            value: selected,
            onChanged: widget.isReadOnly
                ? null
                : (val) {
              setState(() {
                if (val == true) {
                  _multiKeys[key]?.add(option);
                } else {
                  _multiKeys[key]?.remove(option);
                }
              });
            },
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('form.profile.template_name'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'form.profile.template_description'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),

            _buildSectionTitle(Icons.info_outline, 'form.profile.section_about', Colors.blue),
            _buildSingleChoice('importance', ['low', 'medium', 'high', 'very_high']),
            _buildSingleChoice('time', ['<5', '5_10', '10_15', '>15']),
            _buildSingleChoice('autonomy', ['basic', 'essential', 'multimedia', 'advanced']),
            const Divider(),

            _buildSectionTitle(Icons.menu_book, 'form.profile.section_study', Colors.green),
            _buildMultiChoice('sources', ['documents', 'videos', 'blogs', 'ai', 'peers', 'teacher', 'other']),
            _buildMultiChoice('tools', ['highlight', 'tables', 'exercises', 'visual', 'digital', 'other']),
            _buildSingleChoice('group', ['solo', 'small', 'medium', 'large']),
            const Divider(),

            _buildSectionTitle(Icons.lightbulb_outline, 'form.profile.section_learning', Colors.orange),
            _buildMultiChoice('styles', ['reflection', 'creativity', 'practice', 'social', 'digital', 'other']),
            _buildMultiChoice('sharing', ['writing', 'speaking', 'projects', 'group', 'other']),
            _buildMultiChoice('feedback', ['comments', 'dialogue', 'written', 'practical', 'peer', 'other']),
            const Divider(),

            _buildSectionTitle(Icons.flag_outlined, 'form.profile.section_expectations', Colors.purple),
            _buildSingleChoice('difficulty', ['easy', 'medium', 'hard', 'very_hard']),
            _buildSingleChoice('motivation', ['compliance', 'need', 'conviction', 'transformation', 'other']),
            const Divider(),

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

            const SizedBox(height: 20),

            if (!widget.isReadOnly)
              Center(
                child: ElevatedButton(
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
