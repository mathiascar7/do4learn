import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<String> _getUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        return userDoc['role'] ?? 'Student';
      }
    }
    return 'Student';
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Drawer(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data ?? 'Student';

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'menu'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: Text('home'.tr()),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: Text('profile'.tr()),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/profile');
                },
              ),

              if (role == 'Manager' || role == 'Superadmin')
                ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text('university'.tr()),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/university');
                  },
                ),

              if (role == 'Superadmin' || role == 'Manager' || role == 'Professor')
                ListTile(
                  leading: const Icon(Icons.school),
                  title: Text('courses'.tr()),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/courses');
                  },
                ),

              if (role == 'Student')
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: Text('courses'.tr()),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/courseRegistration');
                  },
                ),

              if (role == 'Superadmin')
                ListTile(
                  leading: const Icon(Icons.assignment),
                  title: Text('activities'.tr()),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/activities');
                  },
                ),

              ListTile(
                leading: const Icon(Icons.settings),
                title: Text('settings'.tr()),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/settings');
                },
              ),

              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text('help'.tr()),
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/chat');
                },
              ),

              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: Text('log_out'.tr()),
                onTap: () => _logout(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
