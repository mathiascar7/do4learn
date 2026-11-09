import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'sign_up_page.dart';
import 'forgot_password_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'about_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart'; // ⬅️ Para acceder a MyApp y su remoteVersion

class LoginPage extends StatefulWidget {
  final String? remoteVersion; // ✅ ahora opcional

  const LoginPage({super.key, this.remoteVersion}); // ✅ ya no es required

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const String currentVersion = "1.0.0";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final remoteVersion = widget.remoteVersion ?? "";

      const currentVersion = "1.0.0";
      //print("remoteVersion=$remoteVersion, currentVersion=$currentVersion");
      if (remoteVersion.isNotEmpty && remoteVersion != currentVersion) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('update_available'.tr()),

            content: Text(
              'update_message'.tr(
                namedArgs: {'remote': remoteVersion, 'current': currentVersion},
              ),
            ),

            actions: [
              TextButton(
                onPressed: () async {
                  const url =
                      'https://drive.google.com/file/d/1Bfwi-XjTAG0S9l9EQTec4CiaDmVkL1q0/view?usp=sharing';
                  final uri = Uri.parse(url);

                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('cannot_open_url'.tr())),
                    );
                  }
                },
                child: Text('update_button'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel_button'.tr()),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        //title: Text('login_title'.tr()),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16), // ✅ corregido
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/4learn_logo.png',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    Text(
                      'home_description'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutPage(),
                          ),
                        );
                      },
                      child: Text('info_button'.tr()),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final url = Uri.parse(
                          "https://drive.google.com/uc?export=download&id=1Bfwi-XjTAG0S9l9EQTec4CiaDmVkL1q0",
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('download_started'.tr())),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('download_error'.tr())),
                          );
                        }
                      },
                      child: Text('download_apk'.tr()),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // 🔷 Campos de inicio de sesión
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'login_email'.tr()),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'login_password'.tr()),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: Text('login_forgot_password'.tr()),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();

                  try {
                    final user = await authService.signIn(email, password);
                    await user?.reload();
                    final refreshedUser = FirebaseAuth.instance.currentUser;

                    if (refreshedUser == null) {
                      throw FirebaseAuthException(
                        code: 'user-not-found',
                        message: 'invalid_credentials'.tr(),
                      );
                    }

                    bool isTestDomain(String email) {
                      final testDomains = ['u1.com', 'u2.com', 'u3.com'];
                      final domain = email.split('@').last.toLowerCase();
                      return testDomains.contains(domain);
                    }

                    final isEmailPasswordUser = refreshedUser.providerData.any(
                      (info) => info.providerId == 'password',
                    );
                    final skipVerification = isTestDomain(
                      refreshedUser.email ?? '',
                    );
                    final isVerified =
                        skipVerification ||
                        !isEmailPasswordUser ||
                        refreshedUser.emailVerified;

                    if (!isVerified) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('error_verify_email'.tr())),
                      );
                      return;
                    }

                    final isAllowed = await authService.checkUserAccess(
                      refreshedUser,
                      context,
                    );
                    if (isAllowed) {
                      // 🔹 Leer idioma de Firestore
                      final doc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(refreshedUser.uid)
                          .get();
                      final code = (doc.data()?['preferredLocale'] as String?)
                          ?.trim();
                      if (code != null && code.isNotEmpty) {
                        await context.setLocale(Locale(code));
                        debugPrint("🌍 Idioma aplicado tras login: $code");
                      }

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'login_error'.tr(
                              namedArgs: {
                                'error': e.message ?? 'unknown_error'.tr(),
                              },
                            ),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'login_error'.tr(namedArgs: {'error': e.toString()}),
                        ),
                      ),
                    );
                  }
                },
                child: Text('login_button'.tr()),
              ),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Image.asset(
                  'assets/google_logo.png',
                  height: 20,
                  width: 20,
                ),
                label: Text('login_google'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.grey),
                  textStyle: const TextStyle(fontSize: 14),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(
                    double.infinity,
                    50,
                  ), // ✅ ocupa todo el ancho
                ),
                onPressed: () async {
                  try {
                    final user = await authService.signInWithGoogle();

                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'login_error'.tr(
                              namedArgs: {'error': 'Google sign-in cancelled'},
                            ),
                          ),
                        ),
                      );
                      return;
                    }

                    final isAllowed = await authService.checkGoogleUserAccess(
                      user,
                      context,
                    );
                    if (isAllowed) {
                      final doc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .get();
                      final code = (doc.data()?['preferredLocale'] as String?)
                          ?.trim();
                      if (code != null && code.isNotEmpty) {
                        await context.setLocale(Locale(code));
                        debugPrint(
                          "🌍 Idioma aplicado tras login con Google: $code",
                        );
                      }

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'login_error'.tr(
                            namedArgs: {
                              'error': e.message ?? 'Error desconocido',
                            },
                          ),
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'login_error'.tr(namedArgs: {'error': e.toString()}),
                        ),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                child: Text('login_signup_prompt'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
