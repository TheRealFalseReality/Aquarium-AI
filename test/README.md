# Aquarium AI Test Suite

This directory contains comprehensive tests for the Aquarium AI Flutter application.

## Test Structure

### Calculator Tests (`test/calculators/`)
- `calculator_test.dart` - Tests for salinity, CO2, alkalinity, and temperature calculators
- `tank_volume_calculator_logic_test.dart` - Tests for tank volume calculation logic

### Screen Tests (`test/screens/`)
- `about_screen_test.dart` - About screen UI tests
- `analysis_result_screen_test.dart` - Water analysis result display tests
- `aquarium_stocking_screen_test.dart` - Stocking assistant form tests
- `automation_script_result_screen_test.dart` - Automation script results display tests
- `automation_script_screen_test.dart` - Script generator form tests
- `calculator_screen_test.dart` - Calculator screen navigation and functionality tests
- `chatbot_screen_test.dart` - AI chatbot interface tests
- `compatibility_report_test.dart` - Fish compatibility report display tests
- `fish_compatibility_screen_test.dart` - Fish compatibility tool tests
- `photo_analysis_result_screen_test.dart` - Photo analysis results display tests
- `photo_analysis_screen_test.dart` - Photo capture/selection interface tests
- `settings_screen_test.dart` - App settings and configuration tests
- `stocking_report_screen_test.dart` - Stocking recommendation display tests
- `tank_creation_screen_test.dart` - Tank creation form tests
- `tank_management_test.dart` - Tank management interface and harmony calculator tests
- `tank_volume_calculator_test.dart` - Tank volume calculator UI tests
- `water_parameter_analysis_screen_test.dart` - Water parameter input form tests
- `welcome_screen_test.dart` - Welcome screen navigation tests

### Widget Tests (`test/widgets/`)
- `app_drawer_test.dart` - Navigation drawer tests
- `fish_card_test.dart` - Fish information display widget tests
- `modern_chip_test.dart` - Custom chip widget tests

### Model Tests (`test/models/`)
- `fish_test.dart` - Fish data model tests
- `tank_test.dart` - Tank data model tests

### Provider Tests (`test/providers/`)
- `tank_provider_test.dart` - Tank state management tests

### Utility Tests (`test/utils/`)
- `tank_harmony_calculator_test.dart` - Fish compatibility calculation logic tests

### Integration Tests (`test/integration/`)
- `app_integration_test.dart` - End-to-end app flow tests

## Running Tests

### Run All Tests
```bash
flutter test test/test_all.dart
```

### Run Specific Test Categories
```bash
# Screen tests only
flutter test test/screens/

# Widget tests only
flutter test test/widgets/

# Model tests only
flutter test test/models/

# Integration tests only
flutter test test/integration/
```

### Run Individual Test Files
```bash
flutter test test/screens/chatbot_screen_test.dart
```

### Run Integration Tests
```bash
flutter test integration_test/
```

## Test Coverage

The test suite covers:

- **UI Testing**: All major screens and widgets
- **Unit Testing**: Business logic, calculations, and data models
- **Integration Testing**: Complete user flows and navigation
- **State Management**: Provider-based state management logic
- **Form Validation**: Input validation and error handling
- **Navigation**: Screen transitions and drawer functionality

## Test Patterns

All tests follow consistent patterns:
- Use `ProviderScope` for widget tests that need state management
- Mock data creation with helper functions
- Comprehensive assertions for UI elements and functionality
- Error case testing where applicable
- Loading state verification

## Dependencies

The test suite requires:
- `flutter_test` (built-in)
- `flutter_riverpod` (for state management tests)
- `integration_test` (for integration tests)

## Contributing

When adding new features:
1. Add corresponding unit tests for any new business logic
2. Add widget tests for new UI components
3. Add screen tests for new screens
4. Update integration tests if new navigation flows are added
5. Ensure all tests pass before submitting PRs

## Coverage Goals

- **Screen Coverage**: 100% of screens have basic UI tests
- **Widget Coverage**: All custom widgets have tests
- **Model Coverage**: All data models have serialization/validation tests
- **Provider Coverage**: All state management logic has tests
- **Integration Coverage**: All major user flows are tested