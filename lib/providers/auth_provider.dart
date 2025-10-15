import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/app_api.dart';

// Auth state
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  bool get isAuthenticated => user != null;
  bool get isCustomer => user?.role == UserRole.customer;
  bool get isSalonOwner => user?.role == UserRole.salonOwner || user?.role == UserRole.owner;
  UserRole? get userRole => user?.role;
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      // Check if user is already logged in via Supabase session
      final session = Supabase.instance.client.auth.currentSession;
      if (session?.user != null) {
        // User is logged in, fetch their profile
        final user = await AppApi.getCurrentUser();
        state = state.copyWith(
          user: user,
          isLoading: false,
          isInitialized: true,
          error: null,
        );
      } else {
        // No active session
        state = state.copyWith(
          user: null,
          isLoading: false,
          isInitialized: true,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: e.toString(),
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await AppApi.login(email, password);
      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await AppApi.signup(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await AppApi.forgotPassword(email);
      state = state.copyWith(
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateProfile(UserModel user) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedUser = await AppApi.updateProfile(user);
      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> uploadProfilePicture(String imageUrl) async {
    if (state.user == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedUser = state.user!.copyWith(
        profileImageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );
      await updateProfile(updatedUser);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void logout() {
    // Sign out from Supabase
    Supabase.instance.client.auth.signOut();
    state = const AuthState(isInitialized: true);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final isCustomerProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isCustomer;
});

final isSalonOwnerProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isSalonOwner;
});
