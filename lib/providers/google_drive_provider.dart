import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_drive_service.dart';

/// Provider for Google Drive service
final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  return GoogleDriveService();
});

/// State for Google Drive connection
class GoogleDriveState {
  final bool isSignedIn;
  final GoogleSignInAccount? user;
  final bool isLoading;
  final String? error;

  GoogleDriveState({
    this.isSignedIn = false,
    this.user,
    this.isLoading = false,
    this.error,
  });

  GoogleDriveState copyWith({
    bool? isSignedIn,
    GoogleSignInAccount? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GoogleDriveState(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// Notifier for managing Google Drive state
class GoogleDriveNotifier extends StateNotifier<GoogleDriveState> {
  final GoogleDriveService _service;

  GoogleDriveNotifier(this._service) : super(GoogleDriveState()) {
    _initialize();
  }

  /// Initialize the service and check for existing sign-in
  Future<void> _initialize() async {
    try {
      await _service.initialize();
      if (_service.isSignedIn) {
        state = state.copyWith(
          isSignedIn: true,
          user: _service.currentUser,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize: $e');
    }
  }

  /// Sign in to Google Drive
  Future<bool> signIn() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final user = await _service.signIn();
      if (user != null) {
        state = state.copyWith(
          isSignedIn: true,
          user: user,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Sign-in was cancelled or failed. Please ensure Google Sign-In is properly configured.',
        );
        return false;
      }
    } catch (e) {
      // Provide more helpful error message for common configuration issues
      String errorMessage = 'Sign-in error: $e';
      if (e.toString().contains('PlatformException') || 
          e.toString().contains('ApiException') ||
          e.toString().contains('10:') ||
          e.toString().contains('12500')) {
        errorMessage = 'Sign-in failed. Please check that:\n'
            '1. Google Sign-In is configured in Firebase\n'
            '2. SHA-1 fingerprints are added\n'
            '3. google-services.json is up to date\n'
            'Error: $e';
      }
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  /// Sign out from Google Drive
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      await _service.signOut();
      state = state.copyWith(
        isSignedIn: false,
        user: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign-out error: $e',
      );
    }
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for Google Drive state management
final googleDriveProvider = StateNotifierProvider<GoogleDriveNotifier, GoogleDriveState>((ref) {
  final service = ref.watch(googleDriveServiceProvider);
  return GoogleDriveNotifier(service);
});
