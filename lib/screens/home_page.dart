import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

import 'profile_page.dart';
import 'widgets/app_drawer.dart';
import '../utils/form_template_uploader.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showAdminButton = false;
  bool showProfileButton = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkUserStatus();
  }

  Future<void> checkUserStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        showAdminButton = false;
        showProfileButton = false;
        isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();

      final role = data?['role']?.toString().trim();
      final name = data?['name']?.toString().trim();
      final universityId = data?['universityId']?.toString().trim();

      final isComplete = name != null && name.isNotEmpty && universityId != null && universityId.isNotEmpty;

      setState(() {
        showAdminButton = role == 'Superadmin';
        showProfileButton = !isComplete;
        isLoading = false;
      });
    } catch (e) {
      print('Error al verificar estado del usuario: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('home_title'.tr())),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'home_welcome_message'.tr(),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 12),
              Text(
                'home_description'.tr(),
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (showProfileButton)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  },
                  child: Text('home_complete_profile'.tr()),
                ),

              if (showAdminButton)
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await uploadThesisFormTemplate();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('home_template_uploaded'.tr())),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${'home_upload_error'.tr()}: $e')),
                      );
                    }
                  },
                  child: Text('home_upload_template'.tr()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
