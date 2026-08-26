import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:snooker_club/core/error/app_exception.dart';
import 'package:snooker_club/core/utils/logger.dart';

/// Repository that wraps Firebase Authentication.
/// All Firebase-specific code is isolated here.
/// The rest of the app only sees [AuthException] — never raw Firebase errors.
class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Stream of auth state changes (null = logged out, User = logged in).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password.
  /// Throws [AuthException] with a friendly message on failure.
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Attempting login for: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      AppLogger.info('Login successful for: $email');
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      AppLogger.warning('FirebaseAuthException: ${e.code}');
      throw _mapFirebaseError(e);
    } catch (e) {
      AppLogger.error('Unexpected login error: $e');
      throw const AuthException(
        message: 'An unexpected error occurred. Please try again.',
        code: 'unknown',
      );
    }
  }

  /// Sign in with Google.
  Future<User> signInWithGoogle() async {
    try {
      AppLogger.info('Attempting Google Sign-In');
      
      if (kIsWeb) {
        // On web, use Firebase's native popup which avoids needing a meta tag client ID
        final authProvider = GoogleAuthProvider();
        final UserCredential userCredential = await _auth.signInWithPopup(authProvider);
        AppLogger.info('Google Sign-In successful for: ${userCredential.user?.email}');
        return userCredential.user!;
      } else {
        // Mobile uses the google_sign_in package
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          AppLogger.warning('Google Sign-In aborted by user');
          throw const AuthException(
            message: 'Sign in aborted by user.',
            code: 'aborted',
          );
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        AppLogger.info('Google Sign-In successful for: ${userCredential.user?.email}');
        return userCredential.user!;
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.warning('FirebaseAuthException during Google Sign-In: ${e.code}');
      throw _mapFirebaseError(e);
    } catch (e) {
      AppLogger.error('Unexpected Google Sign-In error: $e');
      throw const AuthException(
        message: 'An unexpected error occurred during Google Sign-In. Please try again.',
        code: 'unknown',
      );
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    AppLogger.info('Signing out user: ${_auth.currentUser?.email}');
    // GoogleSignIn signOut may fail on web — catch silently so Firebase signOut always runs
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await _auth.signOut();
      AppLogger.info('Sign out successful');
    } catch (e) {
      AppLogger.error('Sign out error: $e');
      throw const AuthException(
        message: 'Failed to sign out. Please try again.',
        code: 'sign-out-failed',
      );
    }
  }

  /// Maps Firebase error codes to user-friendly [AuthException] messages.
  AuthException _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthException(
          message: 'No account found with this email address.',
          code: 'user-not-found',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException(
          message: 'Incorrect email or password. Please try again.',
          code: 'wrong-password',
        );
      case 'invalid-email':
        return const AuthException(
          message: 'The email address is not valid.',
          code: 'invalid-email',
        );
      case 'user-disabled':
        return const AuthException(
          message: 'This account has been disabled. Contact the administrator.',
          code: 'user-disabled',
        );
      case 'too-many-requests':
        return const AuthException(
          message: 'Too many failed attempts. Please wait a few minutes and try again.',
          code: 'too-many-requests',
        );
      case 'network-request-failed':
        return const AuthException(
          message: 'No internet connection. Please check your network.',
          code: 'network-request-failed',
        );
      case 'operation-not-allowed':
        return const AuthException(
          message: 'Email/password sign-in is not enabled. Contact the administrator.',
          code: 'operation-not-allowed',
        );
      default:
        return AuthException(
          message: 'Sign in failed (${e.code}). Please try again.',
          code: e.code,
        );
    }
  }
}
