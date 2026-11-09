import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'activity_detail_page.dart'; // Asegúrate que la ruta esté correcta
import 'widgets/app_drawer.dart';   // Importa tu menú lateral

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  final TextEditingController _activityNameController = TextEditingController();
  final TextEditingController _formPageController = TextEditingController();
  List<DocumentSnapshot> _activities = [];
  bool _isLoading = true;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  @override
  void dispose() {
    _activityNameController.dispose();
    _formPageController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('activities')
          .orderBy('createdAt', descending: true)
          .get();
      setState(() {
        _activities = snap.docs;
      });
    } catch (e) {
      setState(() {
        _message = 'Error loading activities: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addActivity() async {
    final name = _activityNameController.text.trim();
    final formPage = _formPageController.text.trim();

    if (name.isEmpty || formPage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both activity name and form page')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('activities').add({
        'title': name,
        'formPage': formPage,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activity "$name" added')),
      );

      _activityNameController.clear();
      _formPageController.clear();
      _loadActivities(); // refrescar lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding activity: $e')),
      );
    }
  }

  Future<void> _deleteActivity(String activityId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this activity? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('activities').doc(activityId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity deleted')),
      );
      _loadActivities();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting activity: $e')),
      );
    }
  }

  void _openActivityDetail(String activityId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailPage(activityId: activityId),
      ),
    ).then((_) => _loadActivities()); // refrescar al volver
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
          ),
        ],
      ),
      drawer: const AppDrawer(), // Aquí se usa el menú lateral
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Formulario para agregar actividad
            TextField(
              controller: _activityNameController,
              decoration: const InputDecoration(labelText: 'Activity Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _formPageController,
              decoration: const InputDecoration(labelText: 'Form Page'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addActivity,
              child: const Text('Add Activity'),
            ),
            const SizedBox(height: 20),

            if (_message.isNotEmpty)
              Text(_message, style: const TextStyle(color: Colors.red)),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _activities.isEmpty
                  ? const Center(child: Text('No activities found'))
                  : ListView.builder(
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  final activity = _activities[index];
                  final title = (activity.data() as Map<String, dynamic>)['title'] ?? 'No Title';

                  return ListTile(
                    title: Text(title),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openActivityDetail(activity.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteActivity(activity.id),
                        ),
                      ],
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
