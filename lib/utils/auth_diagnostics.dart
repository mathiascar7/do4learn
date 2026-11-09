import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthDiagnostics {
  static Future<void> checkStatus() async {
    try {
      await Firebase.initializeApp();
      print("✅ Firebase inicializado correctamente");

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print("👤 Usuario autenticado:");
        print("UID: ${user.uid}");
        print("Email: ${user.email}");
      } else {
        print("⚠️ No hay usuario autenticado actualmente");
      }
    } catch (e) {
      print("❌ Error al inicializar Firebase o acceder a Auth: $e");
    }
  }
}
