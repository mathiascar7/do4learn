import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/app_drawer.dart'; // Ajusta la ruta según tu proyecto

class ActivityDetailPage extends StatefulWidget {
  final String activityId;

  const ActivityDetailPage({super.key, required this.activityId});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  final _titleController = TextEditingController();
  final _formPageController = TextEditingController();

  List<DocumentSnapshot> _courses = [];
  Set<String> _associatedCourseIds = {};
  bool _isLoading = true;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadActivityAndCourses();
  }

  Future<void> _loadActivityAndCourses() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      // Load activity data
      final activityDoc = await FirebaseFirestore.instance
          .collection('activities')
          .doc(widget.activityId)
          .get();

      if (activityDoc.exists) {
        final data = activityDoc.data()!;
        _titleController.text = data['title'] ?? '';
        _formPageController.text = data['formPage'] ?? '';
      }

      // Load courses and associations
      final coursesSnap = await FirebaseFirestore.instance.collection('courses').get();
      final assocSnap = await FirebaseFirestore.instance
          .collection('course_activities')
          .where('activityId', isEqualTo: widget.activityId)
          .get();

      setState(() {
        _courses = coursesSnap.docs;
        _associatedCourseIds =
            assocSnap.docs.map((doc) => doc['courseId'] as String).toSet();
      });
    } catch (e) {
      setState(() {
        _message = 'Error loading data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveActivityChanges() async {
    final newTitle = _titleController.text.trim();
    final newFormPage = _formPageController.text.trim();

    if (newTitle.isEmpty || newFormPage.isEmpty) {
      setState(() {
        _message = 'All fields are required';
      });
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('activities')
          .doc(widget.activityId)
          .update({
        'title': newTitle,
        'formPage': newFormPage,
      });

      setState(() {
        _message = 'Activity updated successfully';
      });
    } catch (e) {
      setState(() {
        _message = 'Error saving data: $e';
      });
    }
  }

  Future<void> _toggleCourseAssociation(String courseId) async {
    final ref = FirebaseFirestore.instance.collection('course_activities');

    try {
      if (_associatedCourseIds.contains(courseId)) {
        // Remove association
        final snapshot = await ref
            .where('activityId', isEqualTo: widget.activityId)
            .where('courseId', isEqualTo: courseId)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          await ref.doc(snapshot.docs.first.id).delete();
          setState(() {
            _associatedCourseIds.remove(courseId);
          });
        }
      } else {
        // Add association
        await ref.add({
          'activityId': widget.activityId,
          'courseId': courseId,
        });
        setState(() {
          _associatedCourseIds.add(courseId);
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error updating association: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Activity'),
      ),
      drawer: const AppDrawer(), // Menú lateral agregado
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.startsWith('Error') ? Colors.red : Colors.green,
                  ),
                ),
              ),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Activity Title'),
            ),
            TextField(
              controller: _formPageController,
              decoration: const InputDecoration(labelText: 'Form Page Name'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saveActivityChanges,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
            ),
            const Divider(height: 32),
            const Text(
              'Associate Courses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  final courseName =
                      (course.data() as Map<String, dynamic>)['name'] ?? 'Unnamed';

                  final isAssociated = _associatedCourseIds.contains(course.id);

                  return ListTile(
                    title: Text(courseName),
                    trailing: IconButton(
                      icon: Icon(
                        isAssociated ? Icons.remove_circle : Icons.add_circle,
                      ),
                      color: isAssociated ? Colors.red : Colors.green,
                      onPressed: () => _toggleCourseAssociation(course.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
