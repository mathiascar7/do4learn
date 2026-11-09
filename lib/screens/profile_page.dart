import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';  // Importa HomePage correctamente
// Importa LoginPage correctamente
import 'widgets/app_drawer.dart'; // Importa tu menú lateral común (ajusta la ruta según tu proyecto)
import 'package:easy_localization/easy_localization.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  String _selectedRole = 'Student'; // Valor por defecto
  String _ownerEmail = '';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerEmailController.dispose();
    super.dispose();
  }

  Future<String?> _getOwnerEmailByUniversityId(String universityId) async {
    if (universityId.isEmpty) return '';
    try {
      final doc = await FirebaseFirestore.instance.collection('universities').doc(universityId).get();
      return doc.data()?['createdBy'] ?? '';
    } catch (e) {
      print('Error fetching owner email: $e');
      return '';
    }
  }


  Future<void> _loadProfileData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
      try {
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          final role = data['role'] ?? 'Student';
          final universityId = data['universityId'] ?? '';

          String ownerEmail = '';
          if (role != 'Manager' && universityId.isNotEmpty) {
            final universityDoc = await FirebaseFirestore.instance
                .collection('universities')
                .doc(universityId)
                .get();
            ownerEmail = universityDoc.data()?['createdBy'] ?? '';
          }

          setState(() {
            _nameController.text = data['name'] ?? '';
            _selectedRole = role;
            _ownerEmail = ownerEmail;
            _ownerEmailController.text = ownerEmail;
            _isLoading = false;
          });
        } else {
          await docRef.set({
            'name': '',
            'role': 'Student',
            'approved': false,
            'email': '',
            'universityId': '',
          });
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('profileCreated'.tr())),
          );
        }
      } catch (e) {
        print('profileLoadError'.tr(args: [e.toString()]));
        setState(() {
          _isLoading = false;
          _errorMessage = 'profileLoadError'.tr(args: [e.toString()]);
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'noUserFound'.tr();
      });
    }
  }



  Future<String?> _getUniversityIdByEmail(String ownerEmail) async {
    final query = await FirebaseFirestore.instance
        .collection('universities')
        .where('createdBy', isEqualTo: ownerEmail.trim().toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }
    return '';
  }



  Future<bool> _validateOwnerEmail(String enteredEmail) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('universities')
        .where('createdBy', isEqualTo: enteredEmail.trim().toLowerCase())
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> _saveProfile() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final email = FirebaseAuth.instance.currentUser?.email;

    if (userId != null && email != null) {
      setState(() {
        _errorMessage = '';
      });

      final enteredOwnerEmail = _ownerEmail.trim().toLowerCase();

      final isValidEmail = (_selectedRole == 'Student' || _selectedRole == 'Professor')
          ? await _validateOwnerEmail(enteredOwnerEmail)
          : true;

      if (!isValidEmail) {
        setState(() {
          _errorMessage = 'The owner email does not match the university owner email.';
        });
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'name': _nameController.text.trim(),
          'role': _selectedRole,
          'email': email.toLowerCase(),
          'universityId': _selectedRole == 'Manager' ? '' : await _getUniversityIdByEmail(enteredOwnerEmail),
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile.')),
        );
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr()),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'edit_profile'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'name'.tr()),
            ),
            const SizedBox(height: 10),

            DropdownButton<String>(
              value: _selectedRole,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRole = newValue!;
                });
              },
              items: <String>['Student', 'Professor', 'Manager']
                  .map((value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value.tr()),
              ))
                  .toList(),
            ),
            const SizedBox(height: 20),

            if (_selectedRole != 'Manager') ...[
              TextField(
                controller: _ownerEmailController,
                decoration: InputDecoration(labelText: 'university_owner_email'.tr()),
                onChanged: (value) {
                  setState(() {
                    _ownerEmail = value;
                  });
                },
              ),
              const SizedBox(height: 20),
            ],

            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),

            ElevatedButton(
              onPressed: _saveProfile,
              child: Text('save_profile'.tr()),
            ),
          ],
        ),
      ),
    );
  }

}
