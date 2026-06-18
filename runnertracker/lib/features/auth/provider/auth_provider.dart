import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../model/user_model.dart';
import '../repository/auth_repository.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(secureStorage: ref.watch(secureStorageProvider));

  ref.onDispose(client.close);

  return client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthState {
  const AuthState({
    this.isLoggedIn = false,
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isLoggedIn;
  final UserModel? currentUser;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    bool? isLoggedIn,
    UserModel? currentUser,
    bool clearCurrentUser = false,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      currentUser: clearCurrentUser ? null : currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(username: username, password: password);

      state = AuthState(isLoggedIn: true, currentUser: user);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoggedIn: false,
        clearCurrentUser: true,
        isLoading: false,
        errorMessage: _resolveErrorMessage(error),
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      final user = await ref
          .read(authRepositoryProvider)
          .register(name: name, email: email, password: password);

      state = AuthState(isLoggedIn: true, currentUser: user);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoggedIn: false,
        clearCurrentUser: true,
        isLoading: false,
        errorMessage: _resolveErrorMessage(error),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }

  String _resolveErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return error.toString();
  }
}
