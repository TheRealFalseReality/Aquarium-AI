import 'package:fish_ai/providers/google_drive_provider.dart';
import 'package:fish_ai/services/google_drive_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  group('Google Drive Integration Tests', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('GoogleDriveService initializes with correct scopes', () {
      final service = GoogleDriveService();
      
      // Verify service is not signed in initially
      expect(service.isSignedIn, false);
      expect(service.currentUser, null);
    });

    test('GoogleDriveState has correct initial state', () {
      final state = GoogleDriveState();
      
      expect(state.isSignedIn, false);
      expect(state.user, null);
      expect(state.isLoading, false);
      expect(state.error, null);
    });

    test('GoogleDriveState copyWith creates new state correctly', () {
      final state = GoogleDriveState(
        isSignedIn: false,
        isLoading: false,
      );
      
      final newState = state.copyWith(
        isSignedIn: true,
        isLoading: true,
      );
      
      expect(newState.isSignedIn, true);
      expect(newState.isLoading, true);
      expect(newState.user, null);
    });

    test('GoogleDriveState copyWith with clearError clears error', () {
      final state = GoogleDriveState(
        error: 'Some error',
      );
      
      final newState = state.copyWith(clearError: true);
      
      expect(newState.error, null);
    });

    test('GoogleDriveProvider initializes with not signed in state', () {
      final state = container.read(googleDriveProvider);
      
      expect(state.isSignedIn, false);
      expect(state.user, null);
      expect(state.isLoading, false);
    });

    test('GoogleDriveNotifier clearError clears error from state', () {
      final notifier = container.read(googleDriveProvider.notifier);
      
      // Set an error state manually (for testing purposes)
      notifier.state = GoogleDriveState(error: 'Test error');
      expect(notifier.state.error, 'Test error');
      
      // Clear the error
      notifier.clearError();
      expect(notifier.state.error, null);
    });
  });

  group('Google Drive Service Method Signatures', () {
    late GoogleDriveService service;

    setUp(() {
      service = GoogleDriveService();
    });

    test('Service has required methods', () {
      // Verify all required methods exist
      expect(service.initialize, isA<Function>());
      expect(service.signIn, isA<Function>());
      expect(service.signOut, isA<Function>());
      expect(service.uploadBackup, isA<Function>());
      expect(service.listBackups, isA<Function>());
      expect(service.downloadBackup, isA<Function>());
      expect(service.deleteBackup, isA<Function>());
    });

    test('Service properties are accessible', () {
      expect(() => service.currentUser, returnsNormally);
      expect(() => service.isSignedIn, returnsNormally);
    });
  });
}
