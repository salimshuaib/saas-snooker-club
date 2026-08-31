import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/features/authentication/data/auth_repository.dart';

/// Provides a singleton [AuthRepository] instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provides the live Firebase auth state as an [AsyncValue<User?>].
/// - AsyncLoading = Firebase is initializing
/// - AsyncData(null) = user is logged out
/// - AsyncData(User) = user is logged in
/// - AsyncError = something went wrong
///
/// CRITICAL FIX: On Android cold start (process killed), Firebase Auth
/// restores the persisted user synchronously during Firebase.initializeApp().
/// However, the authStateChanges()/userChanges() stream can briefly emit
/// null before emitting the restored user, causing the router to flash
/// the login screen.
///
/// We fix this by:
/// 1. Checking currentUser synchronously (available immediately after
///    Firebase.initializeApp() completes in main()).
/// 2. If a user exists, we emit that user FIRST, then listen to the
///    real auth stream for future changes (login/logout).
/// 3. We skip the first event from the real stream since it's the same
///    user we already emitted (avoids duplicate).
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final currentUser = repo.currentUser;

  if (currentUser != null) {
    // User is already persisted — emit immediately, then follow with live stream.
    return _seededAuthStream(currentUser, repo.authStateChanges);
  }

  // No persisted user — just use the raw stream (will emit null).
  return repo.authStateChanges;
});

/// Helper: yields [seed] immediately, then forwards all events from
/// [authStream] after skipping the first one (which duplicates [seed]).
Stream<User?> _seededAuthStream(User seed, Stream<User?> authStream) async* {
  yield seed;
  // Skip(1) drops the initial emission from authStateChanges which would be
  // the same persisted user we already yielded above.
  yield* authStream.skip(1);
}

/// Convenience provider: true if user is currently signed in.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});
