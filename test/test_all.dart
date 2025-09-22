// This file imports all test files to run them together
// Run with: flutter test test/test_all.dart

import 'calculators/calculator_test.dart' as calculator_test;
import 'calculators/tank_volume_calculator_logic_test.dart' as tank_volume_logic_test;

import 'screens/about_screen_test.dart' as about_screen_test;
import 'screens/analysis_result_screen_test.dart' as analysis_result_screen_test;
import 'screens/aquarium_stocking_screen_test.dart' as aquarium_stocking_screen_test;
import 'screens/automation_script_result_screen_test.dart' as automation_script_result_screen_test;
import 'screens/automation_script_screen_test.dart' as automation_script_screen_test;
import 'screens/calculator_screen_test.dart' as calculator_screen_test;
import 'screens/chatbot_screen_test.dart' as chatbot_screen_test;
import 'screens/compatibility_report_test.dart' as compatibility_report_test;
import 'screens/fish_compatibility_screen_test.dart' as fish_compatibility_screen_test;
import 'screens/photo_analysis_result_screen_test.dart' as photo_analysis_result_screen_test;
import 'screens/photo_analysis_screen_test.dart' as photo_analysis_screen_test;
import 'screens/settings_screen_test.dart' as settings_screen_test;
import 'screens/stocking_report_screen_test.dart' as stocking_report_screen_test;
import 'screens/tank_creation_screen_test.dart' as tank_creation_screen_test;
import 'screens/tank_management_test.dart' as tank_management_test;
import 'screens/tank_volume_calculator_test.dart' as tank_volume_calculator_test;
import 'screens/water_parameter_analysis_screen_test.dart' as water_parameter_analysis_screen_test;
import 'screens/welcome_screen_test.dart' as welcome_screen_test;

import 'widgets/app_drawer_test.dart' as app_drawer_test;
import 'widgets/fish_card_test.dart' as fish_card_test;
import 'widgets/modern_chip_test.dart' as modern_chip_test;

import 'models/fish_test.dart' as fish_test;
import 'models/tank_test.dart' as tank_test;

import 'providers/tank_provider_test.dart' as tank_provider_test;

import 'utils/tank_harmony_calculator_test.dart' as tank_harmony_calculator_test;

void main() {
  // Calculator Tests
  calculator_test.main();
  tank_volume_logic_test.main();

  // Screen Tests
  about_screen_test.main();
  analysis_result_screen_test.main();
  aquarium_stocking_screen_test.main();
  automation_script_result_screen_test.main();
  automation_script_screen_test.main();
  calculator_screen_test.main();
  chatbot_screen_test.main();
  compatibility_report_test.main();
  fish_compatibility_screen_test.main();
  photo_analysis_result_screen_test.main();
  photo_analysis_screen_test.main();
  settings_screen_test.main();
  stocking_report_screen_test.main();
  tank_creation_screen_test.main();
  tank_management_test.main();
  tank_volume_calculator_test.main();
  water_parameter_analysis_screen_test.main();
  welcome_screen_test.main();

  // Widget Tests
  app_drawer_test.main();
  fish_card_test.main();
  modern_chip_test.main();

  // Model Tests
  fish_test.main();
  tank_test.main();

  // Provider Tests
  tank_provider_test.main();

  // Utility Tests
  tank_harmony_calculator_test.main();
}