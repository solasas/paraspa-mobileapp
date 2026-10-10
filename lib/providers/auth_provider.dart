import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/storage/secure_storage_service.dart';
import 'core_providers.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final int? userId;
  final String? userName;
  final String? userEmail;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.userName,
    this.userEmail,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    int? userId,
    String? userName,
    String? userEmail,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    _bootstrap();
  }

  final Ref _ref;

  Future<void> _bootstrap() async {
    final token = await SecureStorageService.instance.readToken();
    if (token == null || token.isEmpty) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    final id = await SecureStorageService.instance.readUserId();
    final name = await SecureStorageService.instance.readUserName();
    final email = await SecureStorageService.instance.readUserEmail();
    state = AuthState(
      status: AuthStatus.authenticated,
      userId: id,
      userName: name,
      userEmail: email,
    );
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      final result = await repo.login(email: email, password: password);
      await SecureStorageService.instance.saveSession(
        token: result.token,
        userId: result.id,
        name: result.name,
        email: result.email,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        userId: result.id,
        userName: result.name,
        userEmail: result.email,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: e.message);
      return false;
    } catch (e, st) {
      debugPrint('Auth error: $e\n$st');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Could not complete sign in. Please try again.',
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final repo = _ref.read(authRepositoryProvider);
      final result = await repo.register(name: name, email: email, password: password);
      await SecureStorageService.instance.saveSession(
        token: result.token,
        userId: result.id,
        name: result.name,
        email: result.email,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        userId: result.id,
        userName: result.name,
        userEmail: result.email,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: e.message);
      return false;
    } catch (e, st) {
      debugPrint('Auth error: $e\n$st');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Could not complete sign in. Please try again.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorageService.instance.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Called by the Dio 401 interceptor — storage is already cleared there.
  void forceLogout() {
    if (state.status != AuthStatus.unauthenticated) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
