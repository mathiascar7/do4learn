import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

import '../services/auth_service.dart';
import 'home_page.dart';
import 'login_page.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  // Cambia esto a false si no quieres requerir verificación de correo
  static const bool requireEmailVerification = true;

  bool isTestDomain(String email) {
    final testDomains = ['u1.com', 'u2.com', 'u3.com'];
    final domain = email.split('@').last.toLowerCase();
    return testDomains.contains(domain);
  }


  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(title: Text('signup_title'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'email_label'.tr()),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'password_label'.tr()),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();

                if (email.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('enter_email_password'.tr())),
                  );
                  return;
                }

                try {
                  final user = await authService.signUp(email, password);

                  if (user != null) {
                    // Verifica si el proveedor es correo/contraseña
                    final isEmailPasswordUser = user.providerData.any(
                          (info) => info.providerId == 'password',
                    );

                    if (requireEmailVerification && isEmailPasswordUser && !isTestDomain(email)) {
                      await user.sendEmailVerification();
                    }
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                      'name': '',
                      'email': user.email,
                      'role': 'Student',
                      'approved': true,
                      'universityId': '',
                    }, SetOptions(merge: true));

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          (requireEmailVerification && isEmailPasswordUser)
                              ? 'verification_email_sent'.tr()
                              : 'registration_successful'.tr(),
                        ),
                      ),
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => (requireEmailVerification && isEmailPasswordUser)
                            ? const LoginPage()
                            : const HomePage(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('registration_failed'.tr())),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('firebase_error'.tr(args: [e.message ?? 'Unknown']))),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('generic_error'.tr(args: [e.toString()]))),
                  );
                }
              },
              child: Text('signup_button'.tr()),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: Text('already_have_account'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
