import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'services/auth_service.dart';

// Pantallas principales
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/about_page.dart';
import 'screens/sign_up_page.dart';
import 'screens/profile_page.dart';
import 'screens/course_management_page.dart';
import 'screens/course_detail_page.dart';
import 'screens/university_management_page.dart';
import 'screens/settings_page.dart';
import 'screens/course_registration_page.dart';
import 'screens/activities_page.dart';
import 'screens/activity_detail_page.dart';
import 'screens/course_activities_page.dart';
import 'screens/activity_detailbystudent_page.dart';
import 'screens/activity_responseview_page.dart';
import 'screens/chat_screen.dart';

// Formularios
import 'forms/profile_form_page.dart';
import 'forms/thesis_form_page.dart';
import 'forms/style_form_page.dart';
import 'forms/feedback_form_page.dart';

//Resumenes
import 'summaries/thesis_summary_page.dart';
import 'summaries/feedback_summary_page.dart';
import 'summaries/profile_summary_page.dart';
import 'summaries/style_summary_page.dart';

import 'package:flutter/material.dart';
import '/utils/auth_diagnostics.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:url_launcher/url_launcher.dart';

Future<Locale?> _loadPreferredLocale() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    //print('Current user: $user');
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      //print('User document exists: ${doc.exists}');
      //print('User preferredLocale: ${doc.data()?['preferredLocale']}');
      if (doc.exists) {
        final data = doc.data();
        final code = (data?['preferredLocale'] as String?)?.trim();
        if (code != null && code.isNotEmpty) {
          return Locale(code);
        }
      }
    }
  } catch (_) {}
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('preferredLocale');
    if (code != null && code.isNotEmpty) return Locale(code);
  } catch (_) {}
  return null;
}

Future<void> setUserPreferredLocale(Locale locale) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferredLocale', locale.languageCode);
  } catch (_) {}
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'preferredLocale': locale.languageCode,
      }, SetOptions(merge: true));
    }
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setUrlStrategy(PathUrlStrategy());

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await EasyLocalization.ensureInitialized();

  // 🔹 Configuración de Remote Config
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ),
  );
  await remoteConfig.fetchAndActivate();

  // 🔹 Obtén la versión remota
  final remoteVersion = remoteConfig.getString('apkversion');
  //print('🔥 Versión remota obtenida: $remoteVersion');

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ar'),
        Locale('bn'),
        Locale('de'),
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('hi'),
        Locale('it'),
        Locale('ja'),
        Locale('pt'),
        Locale('ru'),
        Locale('zh'),
      ],
      path: 'assets/langs',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: MyApp(remoteVersion: remoteVersion),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String remoteVersion;
  const MyApp({super.key, required this.remoteVersion});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return MaterialApp(
      title: '4Learn',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routes: {
        '/home': (context) => const HomePage(),
        '/about': (context) => const AboutPage(),
        '/profile': (context) => const ProfilePage(),
        '/courses': (context) => const CourseManagementPage(),
        '/courseRegistration': (context) => const CourseRegistrationPage(),
        '/university': (context) => const UniversityManagementPage(),
        '/settings': (context) => const SettingsPage(),
        '/login': (context) => LoginPage(remoteVersion: remoteVersion),
        '/sign_up': (context) => const SignUpPage(),
        '/activities': (context) => const ActivitiesPage(),
        '/chat': (context) => const ChatScreen(),
      },
      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/course-detail':
            if (args != null && args.containsKey('courseId')) {
              return MaterialPageRoute(
                builder: (context) =>
                    CourseDetailPage(courseId: args['courseId']),
              );
            }
            break;

          case '/activity-detail':
            if (args != null && args.containsKey('activityId')) {
              return MaterialPageRoute(
                builder: (context) =>
                    ActivityDetailPage(activityId: args['activityId']),
              );
            }
            break;

          case '/activity-detail-by-student':
            if (args != null &&
                args.containsKey('courseId') &&
                args.containsKey('studentId')) {
              return MaterialPageRoute(
                builder: (context) => ActivityDetailByStudentPage(
                  courseId: args['courseId'],
                  studentId: args['studentId'],
                ),
              );
            }
            break;

          case '/course_activities':
            if (args != null && args.containsKey('courseId')) {
              return MaterialPageRoute(
                builder: (context) =>
                    CourseActivitiesPage(courseId: args['courseId']),
              );
            }
            break;

          case '/activity-form':
            if (args != null &&
                args.containsKey('activityId') &&
                args.containsKey('courseId') &&
                args.containsKey('formPage')) {
              final String activityId = args['activityId'];
              final String courseId = args['courseId'];
              final String formPage = args['formPage'];

              Widget formWidget;

              switch (formPage) {
                case 'profile_form_page':
                  formWidget = ProfileFormPage(
                    activityId: activityId,
                    courseId: courseId,
                  );
                  break;
                case 'thesis_form_page':
                  formWidget = ThesisFormPage(
                    activityId: activityId,
                    courseId: courseId,
                  );
                  break;
                case 'style_form_page':
                  formWidget = StyleFormPage(
                    activityId: activityId,
                    courseId: courseId,
                  );
                  break;
                case 'feedback_form_page':
                  formWidget = FeedbackFormPage(
                    activityId: activityId,
                    courseId: courseId,
                  );
                  break;
                default:
                  formWidget = Scaffold(
                    body: Center(child: Text('form_not_recognized'.tr())),
                  );
              }

              return MaterialPageRoute(builder: (_) => formWidget);
            }
            break;

          //resumenes
          case '/summary':
            if (args != null &&
                args.containsKey('activityId') &&
                args.containsKey('courseId') &&
                args.containsKey('userId') &&
                args.containsKey('formPage')) {
              final String activityId = args['activityId'];
              final String courseId = args['courseId'];
              final String userId = args['userId'];
              final String formPage = args['formPage'];

              final summaryPageName = formPage.replaceFirst('form', 'summary');

              Widget summaryWidget;

              switch (summaryPageName) {
                case 'thesis_summary_page':
                  summaryWidget = ThesisSummaryPage(
                    activityId: activityId,
                    courseId: courseId,
                  );
                  break;
                case 'feedback_summary_page':
                  summaryWidget = FeedbackSummaryPage(
                    activityId: activityId,
                    courseId: courseId,
                  );
                  break;
                case 'profile_summary_page':
                  summaryWidget = ProfileSummaryPage(
                    activityId: activityId,
                    courseId: courseId,
                  );
                  break;
                case 'style_summary_page':
                  summaryWidget = StyleSummaryPage(
                    activityId: activityId,
                    courseId: courseId,
                  );
                  break;
                default:
                  summaryWidget = const Scaffold(
                    body: Center(child: Text('Resumen no disponible')),
                  );
              }

              return MaterialPageRoute(builder: (_) => summaryWidget);
            }
            break;

          case '/view-activity-response':
            if (args != null &&
                args.containsKey('activityId') &&
                args.containsKey('courseId') &&
                args.containsKey('studentId') &&
                args.containsKey('formPage')) {
              final String activityId = args['activityId'];
              final String courseId = args['courseId'];
              final String studentId = args['studentId'];
              final String formPage = args['formPage'];

              Widget formWidget;

              // Este switch decide qué formulario mostrar basado en 'formPage'
              switch (formPage) {
                case 'profile_form_page':
                  formWidget = ProfileFormPage(
                    activityId: activityId,
                    courseId: courseId,
                    userId: studentId, // ⬅️ Pasa el ID del estudiante
                    isReadOnly: true, // ⬅️ Activa el modo solo lectura
                  );
                  break;
                case 'thesis_form_page':
                  formWidget = ThesisFormPage(
                    activityId: activityId,
                    courseId: courseId,
                    userId: studentId,
                    isReadOnly: true,
                  );
                  break;
                case 'style_form_page':
                  formWidget = StyleFormPage(
                    activityId: activityId,
                    courseId: courseId,
                    studentId: studentId,
                    isReadOnly: true,
                  );
                  break;
                case 'feedback_form_page':
                  formWidget = FeedbackFormPage(
                    activityId: activityId,
                    courseId: courseId,
                    studentId: studentId,
                    isReadOnly: true,
                  );
                  break;
                default:
                  // Página de error si 'formPage' no coincide con ningún caso
                  formWidget = Scaffold(
                    appBar: AppBar(title: Text('Error')),
                    body: Center(
                      child: Text('Formulario no reconocido: $formPage'),
                    ),
                  );
              }
              return MaterialPageRoute(builder: (_) => formWidget);
            }
            break;

          case '/activity-response-view':
            if (args != null &&
                args.containsKey('activityId') &&
                args.containsKey('courseId') &&
                args.containsKey('studentId')) {
              return MaterialPageRoute(
                builder: (context) => ActivityResponseViewPage(
                  activityId: args['activityId'],
                  courseId: args['courseId'],
                  studentId: args['studentId'],
                ),
              );
            }
            break;
        }

        return MaterialPageRoute(
          builder: (_) =>
              Scaffold(body: Center(child: Text('route_not_found'.tr()))),
        );
      },
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const HomePage();
          }
          return LoginPage(
            remoteVersion: remoteVersion,
          ); // ✅ aquí pasas la versión
        },
      ),
    );
  }
}
