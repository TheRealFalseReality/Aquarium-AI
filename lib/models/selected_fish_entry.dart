import 'fish.dart';

/// Pairs a [Fish] with an optional specific common name (variety/morph) that
/// the user chose from the fish's [Fish.commonNames] list. When present the
/// common name is forwarded to the AI prompt so it can generate more targeted
/// stocking recommendations.
class SelectedFishEntry {
  final Fish fish;

  /// A specific common name the user selected (e.g. "Blue Ram" for a
  /// Cichlid). `null` means "any / general – use the species name".
  final String? selectedCommonName;

  const SelectedFishEntry({required this.fish, this.selectedCommonName});

  /// Human-readable label: the selected common name when available, otherwise
  /// the species name.
  String get displayName => selectedCommonName ?? fish.name;
}
