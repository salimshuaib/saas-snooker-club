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
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Convenience provider: true if user is currently signed in.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});
