import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

import '../main.dart'; // para usar setUserPreferredLocale
import 'widgets/app_drawer.dart'; // Ajusta la ruta según donde tengas tu drawer común

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  String newEmail = '';
  String newPassword = '';

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
  }

  Future<void> _updateEmail() async {
    try {
      if (newEmail.isEmpty || user == null) return;

      // Reautenticación previa
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: newPassword, // ← contraseña actual del usuario
      );

      await user!.reauthenticateWithCredential(credential);

      // Enviar correo de verificación al nuevo email
      await user!.verifyBeforeUpdateEmail(newEmail);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('verification_email_sent'.tr())),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error_label'.tr()}: ${e.message ?? 'Unknown error'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error_label'.tr()}: $e')),
      );
    }
  }


  Future<void> _updatePassword() async {
    try {
      if (newPassword.isEmpty || user == null) return;

      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: newPassword, // ← usa la contraseña actual para reautenticación
      );

      await user!.reauthenticateWithCredential(credential);
      await user!.updatePassword(newPassword);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('password_updated'.tr())),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error_label'.tr()}: ${e.message ?? 'Unknown error'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error_label'.tr()}: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('${'user_label'.tr()}: ${user?.email ?? 'not_logged_in'.tr()}'),
            const SizedBox(height: 20),

            TextField(
              decoration: InputDecoration(labelText: 'new_email'.tr()),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => newEmail = value,
            ),
            const SizedBox(height: 20),

            TextField(
              decoration: InputDecoration(labelText: 'new_password'.tr()),
              obscureText: true,
              onChanged: (value) => newPassword = value,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await _updateEmail();
                await _updatePassword();
              },
              child: Text('update_settings'.tr()),
            ),

            const Divider(height: 40),

            Text('language'.tr(), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),

            DropdownButton<Locale>(
              value: context.locale,
              onChanged: (Locale? locale) async {
                if (locale != null) {
                  await context.setLocale(locale);
                  await setUserPreferredLocale(locale);
                  setState(() {});
                }
              },
              items: const [
                DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
                DropdownMenuItem(value: Locale('bn'), child: Text('বাংলা')),
                DropdownMenuItem(value: Locale('de'), child: Text('Deutsch')),
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
                DropdownMenuItem(value: Locale('es'), child: Text('Español')),
                DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
                DropdownMenuItem(value: Locale('hi'), child: Text('हिन्दी')),
                DropdownMenuItem(value: Locale('it'), child: Text('Italiano')),
                DropdownMenuItem(value: Locale('ja'), child: Text('日本語')),
                DropdownMenuItem(value: Locale('pt'), child: Text('Português')),
                DropdownMenuItem(value: Locale('ru'), child: Text('Русский')),
                DropdownMenuItem(value: Locale('zh'), child: Text('中文')),
              ],

            ),
          ],
        ),
      ),
    );
  }
}
