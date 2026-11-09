import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

import 'widgets/app_drawer.dart';

class UniversityManagementPage extends StatefulWidget {
  const UniversityManagementPage({super.key});

  @override
  _UniversityManagementPageState createState() => _UniversityManagementPageState();
}

class _UniversityManagementPageState extends State<UniversityManagementPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _universityId;
  String? _universityCode;

  @override
  void initState() {
    super.initState();
    _checkUniversityExistence();
  }

  void _checkUniversityExistence() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('universities')
          .where('createdBy', isEqualTo: user.email?.toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var universityData = snapshot.docs.first;
        setState(() {
          _universityId = universityData.id;
          _nameController.text = universityData['name'];
          _locationController.text = universityData['location'];
          _universityCode = universityData['code'];
        });
      }
    }
  }

  Future<String> _generateUniqueCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();

    String generateCode() => String.fromCharCodes(
        Iterable.generate(10, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

    String code;
    bool exists;

    do {
      code = generateCode();
      final query = await FirebaseFirestore.instance
          .collection('universities')
          .where('code', isEqualTo: code)
          .get();
      exists = query.docs.isNotEmpty;
    } while (exists);

    return code;
  }

  void _addUniversity() async {
    if (_nameController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('university_fill_all'.tr())),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && _universityId == null) {
      try {
        final code = await _generateUniqueCode();

        final doc = await FirebaseFirestore.instance.collection('universities').add({
          'name': _nameController.text,
          'location': _locationController.text,
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': user.email,
          'code': code,
        });

        final universityId = doc.id;

        setState(() {
          _universityId = universityId;
          _universityCode = code;
        });

        // ✅ Actualiza el perfil del usuario con el universityId real
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'universityId': universityId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('university_added_success'.tr())),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('university_error'.tr(args: [e.toString()]))),
        );
      }
    }
  }


  void _updateUniversity() async {
    if (_nameController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('university_fill_all'.tr())),
      );
      return;
    }

    if (_universityId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('universities')
            .doc(_universityId)
            .update({
          'name': _nameController.text,
          'location': _locationController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('university_updated_success'.tr())),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('university_error'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  void _desassociateProfessor(String professorId, String professorName) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('university_confirm_desassociate'.tr()),
        content: Text('university_desassociate_question'.tr(args: [professorName])),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await FirebaseFirestore.instance
                    .collection('users') // ✅ colección correcta
                    .doc(professorId)
                    .update({'universityId': null}); // ✅ campo correcto

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('professor_desassociated'.tr())),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('university_error'.tr(args: [e.toString()]))),
                );
              }
            },
            child: Text('desassociate'.tr()),
          ),

        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }
  Future<void> _registerProfessorManually() async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('register_professor'.tr()),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'professor_email'.tr(),
              hintText: 'professor_email_hint'.tr(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim().toLowerCase();
                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('enter_valid_email'.tr())),
                  );
                  return;
                }

                final userQuery = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: email)
                    .limit(1)
                    .get();

                if (userQuery.docs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('no_user_with_email'.tr())),
                  );
                  return;
                }

                final userDoc = userQuery.docs.first;
                final userId = userDoc.id;

                await FirebaseFirestore.instance.collection('users').doc(userId).set({
                  'universityId': _universityId,
                  'role': 'Professor',
                  'name': userDoc['name'] ?? '',
                  'email': email,
                }, SetOptions(merge: true));

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('professor_registered'.tr())),
                );

                Navigator.of(ctx).pop();
              },
              child: Text('register'.tr()),
            ),

          ],
        );
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('university_title'.tr())),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'university_info'.tr(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'university_name'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'university_location'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_universityCode != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'university_code'.tr(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Flexible(
                                flex: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: SelectableText(
                                    _universityCode!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                tooltip: 'copy_code'.tr(),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _universityCode!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('copy_code_success'.tr())),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    Center(
                      child: ElevatedButton(
                        onPressed: _universityId == null ? _addUniversity : _updateUniversity,
                        child: Text(_universityId == null
                            ? 'add_university'.tr()
                            : 'update_university'.tr()),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'professors_title'.tr(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 250, // Ajusta según tu diseño
              child: _universityId == null
                  ? Center(child: Text('professors_no_university'.tr()))
                  : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('universityId', isEqualTo: _universityId)
                    .where('role', isEqualTo: 'Professor')
                    .orderBy('name')
                    .snapshots(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('professors_none'.tr()));
                  }

                  final professors = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: professors.length,
                    itemBuilder: (ctx, index) {
                      final prof = professors[index];
                      final profId = prof.id;
                      final profName = prof['name'] ?? '';
                      final profEmail = prof['email'] ?? '';

                      return ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profName),
                            Text(profEmail, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red.shade200),
                          tooltip: 'desassociate'.tr(),
                          onPressed: () => _desassociateProfessor(profId, profName),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightBlue.shade100,
        onPressed: _registerProfessorManually,
        tooltip: 'register_professor'.tr(),
        child: const Icon(Icons.person_add),
      ),
    );
  }

}
