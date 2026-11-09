import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream para escuchar cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();


  bool isTestDomain(String email) {
    final testDomains = ['u1.com', 'u2.com', 'u3.com'];
    final domain = email.split('@').last.toLowerCase();
    return testDomains.contains(domain);
  }


  // Registro con email y password
  Future<User?> signUp(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user == null) {
        print('Error: user is null after signUp');
        return null;
      }

      await _assignRole(user.uid, 'student');
      return user;
    } catch (e) {
      print('Error en signUp: $e');
      return null;
    }
  }


  // Login con email y password
  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error en signIn: $e');
      return null;
    }
  }

  // Login con Google
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // ✅ Login para Web
        final provider = GoogleAuthProvider();
        final userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
        final user = userCredential.user;

        if (user == null) {
          print('Google sign-in failed: user is null');
          return null;
        }

        // Verifica si el documento del usuario ya existe en Firestore
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final doc = await docRef.get();

        if (!doc.exists) {
          await docRef.set({
            'name': user.displayName ?? '',
            'email': user.email,
            'role': 'Student',
            'approved': true,
            'universityId': '',
          }, SetOptions(merge: true));
        }

        return user;
      } else {
        // ✅ Login para Android/iOS
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          print('Google sign-in cancelled by user');
          return null;
        }

        final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
        final accessToken = googleAuth?.accessToken;
        final idToken = googleAuth?.idToken;

        if (accessToken == null || idToken == null) {
          print('Missing Google authentication tokens');
          return null;
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: accessToken,
          idToken: idToken,
        );

        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        final user = userCredential.user;

        if (user == null) {
          print('Google sign-in failed: user is null');
          return null;
        }

        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final doc = await docRef.get();

        if (!doc.exists) {
          await docRef.set({
            'name': user.displayName ?? '',
            'email': user.email,
            'role': 'Student',
            'approved': true,
            'universityId': '',
          }, SetOptions(merge: true));
        }

        return user;
      }
    } catch (e) {
      print('Error en signInWithGoogle: $e');
      return null;
    }
  }




  // Asignar rol en Firestore
  Future<void> _assignRole(String uid, String role) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': role,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error asignando el rol: $e");
    }
  }

  // Obtener rol del usuario actual
  Future<String> _getUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc['role'] ?? 'student';
      }
    }
    return 'student';
  }

  // Logout
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // Validación para usuarios con email/password
  Future<bool> checkUserAccess(User user, BuildContext context) async {
    try {
      final isEmailPasswordUser = user.providerData.any((info) => info.providerId == 'password');
      final skipVerification = isTestDomain(user.email ?? '');
      final isVerified = skipVerification || !isEmailPasswordUser || user.emailVerified;

      if (!isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_verify_email'.tr())),
        );
        return false;
      }


      final uid = user.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();

      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_user_not_registered'.tr())),
        );
        return false;
      }

      final isApproved = data['approved'] == true;
      if (!isApproved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_user_not_approved'.tr())),
        );
        return false;
      }

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_generic'.tr(namedArgs: {
          'error': e.toString()
        }))),
      );
      return false;
    }
  }



// Validación para usuarios con Google
  Future<bool> checkGoogleUserAccess(User user, BuildContext context) async {
    try {
      final uid = user.uid;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();

      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('login_error'.tr(namedArgs: {
            'error': 'Usuario no registrado. Por favor crea una cuenta primero.'
          }))),
        );
        return false;
      }

      final isApproved = data['approved'] == true;
      if (!isApproved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('login_error'.tr(namedArgs: {
            'error': 'Tu cuenta aún no ha sido aprobada por el administrador.'
          }))),
        );
        return false;
      }

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('login_error'.tr(namedArgs: {
          'error': e.toString()
        }))),
      );
      return false;
    }
  }

}


