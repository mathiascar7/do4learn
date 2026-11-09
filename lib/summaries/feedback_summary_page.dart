import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class FeedbackSummaryPage extends StatefulWidget {
  final String activityId;
  final String courseId;

  const FeedbackSummaryPage({
    super.key,
    required this.activityId,
    required this.courseId,
  });

  @override
  State<FeedbackSummaryPage> createState() => _FeedbackSummaryPageState();
}

class _FeedbackSummaryPageState extends State<FeedbackSummaryPage> {
  bool _isLoading = true;
  int _totalResponses = 0;
  double _averageRating = 0.0;
  int _moodHappy = 0;
  int _moodNeutral = 0;
  int _moodSad = 0;
  int _recommendYes = 0;

  @override
  void initState() {
    super.initState();
    _loadFeedbackData();
  }

  Future<void> _loadFeedbackData() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('activity_responses')
          .where('activityId', isEqualTo: widget.activityId)
          .where('courseId', isEqualTo: widget.courseId)
          .get();

      final docs = snapshot.docs;
      _totalResponses = docs.length;

      double ratingSum = 0.0;

      for (var doc in docs) {
        final data = doc.data();
        final responses = data['responses'] as Map<String, dynamic>?;

        if (responses != null) {
          final rating = responses['rating'] ?? 0;
          final mood = responses['mood'] ?? 0;
          final recommend = responses['recommend'] ?? false;

          ratingSum += rating;

          if (mood == 2) _moodHappy++;
          else if (mood == 1) _moodNeutral++;
          else _moodSad++;

          if (recommend == true) _recommendYes++;
        }
      }

      if (_totalResponses > 0) {
        _averageRating = ratingSum / _totalResponses;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading feedback summary: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('form.feedback.summary.title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'back'.tr(),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('form.feedback.summary.overview'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('${'form.feedback.summary.total_responses'.tr()}: $_totalResponses'),
            Text('${'form.feedback.summary.average_rating'.tr()}: ${_averageRating.toStringAsFixed(1)} ⭐'),
            Text('${'form.feedback.summary.recommend_percent'.tr()}: ${((_recommendYes / _totalResponses) * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 24),
            Text('form.feedback.summary.mood_distribution'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMoodBox('😊', _moodHappy),
                _buildMoodBox('😐', _moodNeutral),
                _buildMoodBox('😞', _moodSad),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodBox(String emoji, int count) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text('$count', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
