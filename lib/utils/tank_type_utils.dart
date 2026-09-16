import '../l10n/app_localizations.dart';
import '../models/tank.dart';

const String customTankTypeId = 'custom';

class TankTypeOption {
  final String id;
  final String? category;
  final String emoji;
  final String aiLabel;
  final String aiDescription;

  const TankTypeOption({
    required this.id,
    required this.emoji,
    required this.aiLabel,
    required this.aiDescription,
    this.category,
  });

  bool supportsCategory(String tankCategory) =>
      category == null || category == tankCategory;
}

const List<TankTypeOption> tankTypeOptions = [
  TankTypeOption(
    id: 'community',
    category: 'freshwater',
    emoji: '🐠',
    aiLabel: 'community',
    aiDescription:
        'a peaceful mixed-species freshwater community aquarium',
  ),
  TankTypeOption(
    id: 'planted',
    category: 'freshwater',
    emoji: '🌿',
    aiLabel: 'planted',
    aiDescription: 'a planted freshwater aquarium with live plants',
  ),
  TankTypeOption(
    id: 'blackwater',
    category: 'freshwater',
    emoji: '🍂',
    aiLabel: 'blackwater',
    aiDescription:
        'a blackwater freshwater aquarium with tannins, softer water, and subdued lighting',
  ),
  TankTypeOption(
    id: 'brackish',
    category: 'freshwater',
    emoji: '🦀',
    aiLabel: 'brackish',
    aiDescription:
        'a brackish aquarium with mildly saline water between freshwater and marine conditions',
  ),
  TankTypeOption(
    id: 'cichlid',
    category: 'freshwater',
    emoji: '🐡',
    aiLabel: 'cichlid',
    aiDescription:
        'a cichlid-focused freshwater aquarium with territorial stocking considerations',
  ),
  TankTypeOption(
    id: 'shrimp',
    category: 'freshwater',
    emoji: '🦐',
    aiLabel: 'shrimp',
    aiDescription:
        'a shrimp-focused freshwater aquarium that prioritizes invertebrate-safe tank mates',
  ),
  TankTypeOption(
    id: 'nano',
    category: 'freshwater',
    emoji: '🫧',
    aiLabel: 'nano',
    aiDescription:
        'a nano freshwater aquarium with limited water volume and tight stocking limits',
  ),
  TankTypeOption(
    id: 'fish_only',
    category: 'marine',
    emoji: '🌊',
    aiLabel: 'fish-only',
    aiDescription: 'a marine fish-only aquarium without corals',
  ),
  TankTypeOption(
    id: 'fowlr',
    category: 'marine',
    emoji: '🪨',
    aiLabel: 'FOWLR',
    aiDescription: 'a marine FOWLR aquarium with fish and live rock',
  ),
  TankTypeOption(
    id: 'reef',
    category: 'marine',
    emoji: '🪸',
    aiLabel: 'reef',
    aiDescription: 'a marine reef aquarium with corals and reef-safe livestock',
  ),
  TankTypeOption(
    id: 'nano_reef',
    category: 'marine',
    emoji: '🪸',
    aiLabel: 'nano reef',
    aiDescription:
        'a small marine reef aquarium with corals and stricter stocking limits',
  ),
  TankTypeOption(
    id: 'lagoon',
    category: 'marine',
    emoji: '🏝️',
    aiLabel: 'lagoon',
    aiDescription:
        'a lagoon-style marine aquarium with calmer flow and mixed reef or seagrass conditions',
  ),
  TankTypeOption(
    id: 'invert_only',
    category: 'marine',
    emoji: '🦀',
    aiLabel: 'invert-only',
    aiDescription:
        'a marine invertebrate-focused aquarium centered on shrimp, crabs, snails, and other inverts',
  ),
  TankTypeOption(
    id: 'seahorse',
    category: 'marine',
    emoji: '🪼',
    aiLabel: 'seahorse',
    aiDescription:
        'a marine seahorse aquarium with gentle flow and species-specific care needs',
  ),
  TankTypeOption(
    id: 'predator',
    emoji: '🦈',
    aiLabel: 'predator',
    aiDescription:
        'a predator aquarium with larger or more aggressive livestock and a heavier bioload',
  ),
  TankTypeOption(
    id: 'species_only',
    emoji: '🎯',
    aiLabel: 'species-only',
    aiDescription:
        'a species-only aquarium focused on one primary species or closely related group',
  ),
  TankTypeOption(
    id: 'breeding',
    emoji: '🥚',
    aiLabel: 'breeding',
    aiDescription:
        'a breeding aquarium set up to encourage spawning and raise young',
  ),
  TankTypeOption(
    id: 'quarantine',
    emoji: '🩺',
    aiLabel: 'quarantine',
    aiDescription:
        'a quarantine aquarium used for observation, acclimation, and temporary isolation',
  ),
  TankTypeOption(
    id: 'hospital',
    emoji: '💊',
    aiLabel: 'hospital',
    aiDescription:
        'a hospital aquarium used for treatment and close monitoring of sick livestock',
  ),
  TankTypeOption(
    id: customTankTypeId,
    emoji: '✨',
    aiLabel: 'custom',
    aiDescription:
        'a custom aquarium type defined by the user with extra context for AI recommendations',
  ),
];

List<TankTypeOption> getTankTypeOptionsForCategory(String category) =>
    tankTypeOptions.where((option) => option.supportsCategory(category)).toList();

TankTypeOption? getTankTypeOptionById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final option in tankTypeOptions) {
    if (option.id == id) return option;
  }
  return null;
}

String? normalizeTankTypeSelection({
  required String category,
  bool isReef = false,
  String? freshwaterSubtype,
  String? specialization,
  String? customTypeName,
}) {
  if (customTypeName != null && customTypeName.trim().isNotEmpty) {
    return customTankTypeId;
  }
  if (specialization != null &&
      specialization.isNotEmpty &&
      (getTankTypeOptionById(specialization)?.supportsCategory(category) ?? false)) {
    return specialization;
  }
  if (category == 'marine' && isReef) return 'reef';
  if (category == 'freshwater' &&
      (freshwaterSubtype == 'planted' || freshwaterSubtype == 'brackish')) {
    return freshwaterSubtype;
  }
  return null;
}

String getTankTypeDisplayLabel(
  AppLocalizations l10n,
  Tank tank,
) => getTankTypeDisplayLabelFromParts(
  l10n,
  category: tank.type,
  isReef: tank.isReef,
  freshwaterSubtype: tank.freshwaterSubtype,
  specialization: tank.specialization,
  customTypeName: tank.customTypeName,
);

String getTankTypeDisplayLabelFromParts(
  AppLocalizations l10n, {
  required String category,
  bool isReef = false,
  String? freshwaterSubtype,
  String? specialization,
  String? customTypeName,
}) {
  final customName = customTypeName?.trim();
  if (customName != null && customName.isNotEmpty) {
    return customName;
  }

  switch (normalizeTankTypeSelection(
    category: category,
    isReef: isReef,
    freshwaterSubtype: freshwaterSubtype,
    specialization: specialization,
  )) {
    case 'community':
      return l10n.tankTypeCommunity;
    case 'planted':
      return l10n.plantedTank;
    case 'blackwater':
      return l10n.tankTypeBlackwater;
    case 'brackish':
      return l10n.brackishTank;
    case 'cichlid':
      return l10n.tankTypeCichlid;
    case 'shrimp':
      return l10n.tankTypeShrimp;
    case 'nano':
      return l10n.tankTypeNano;
    case 'fish_only':
      return l10n.tankTypeFishOnly;
    case 'fowlr':
      return l10n.tankTypeFowlr;
    case 'reef':
      return l10n.reefTank;
    case 'nano_reef':
      return l10n.tankTypeNanoReef;
    case 'lagoon':
      return l10n.tankTypeLagoon;
    case 'invert_only':
      return l10n.tankTypeInvertOnly;
    case 'seahorse':
      return l10n.tankTypeSeahorse;
    case 'predator':
      return l10n.tankTypePredator;
    case 'species_only':
      return l10n.tankTypeSpeciesOnly;
    case 'breeding':
      return l10n.tankTypeBreeding;
    case 'quarantine':
      return l10n.tankTypeQuarantine;
    case 'hospital':
      return l10n.tankTypeHospital;
    case customTankTypeId:
      return l10n.tankTypeCustom;
    case null:
      return category == 'freshwater' ? l10n.freshwater : l10n.saltwater;
    default:
      return category == 'freshwater' ? l10n.freshwater : l10n.saltwater;
  }
}

String getTankTypeEmoji(Tank tank) {
  final effectiveType = normalizeTankTypeSelection(
    category: tank.type,
    isReef: tank.isReef,
    freshwaterSubtype: tank.freshwaterSubtype,
    specialization: tank.specialization,
    customTypeName: tank.customTypeName,
  );
  return switch (effectiveType) {
    'planted' => '🌿',
    'blackwater' => '🍂',
    'brackish' => '🦀',
    'cichlid' => '🐡',
    'shrimp' => '🦐',
    'nano' => '🫧',
    'fowlr' => '🪨',
    'reef' || 'nano_reef' => '🪸',
    'lagoon' => '🏝️',
    'invert_only' => '🦀',
    'seahorse' => '🪼',
    'predator' => '🦈',
    'species_only' => '🎯',
    'breeding' => '🥚',
    'quarantine' => '🩺',
    'hospital' => '💊',
    customTankTypeId => tank.type == 'freshwater' ? '✨' : '🌟',
    _ => tank.type == 'freshwater' ? '🐟' : '🌊',
  };
}

String getTankTypeAiContext(Tank tank) {
  final categoryLabel = tank.type == 'freshwater' ? 'freshwater' : 'marine';
  final customName = tank.customTypeName?.trim();
  final customDescription = tank.customTypeDescription?.trim();
  final effectiveType = normalizeTankTypeSelection(
    category: tank.type,
    isReef: tank.isReef,
    freshwaterSubtype: tank.freshwaterSubtype,
    specialization: tank.specialization,
    customTypeName: customName,
  );

  final option = getTankTypeOptionById(effectiveType);
  final parts = <String>[
    option?.aiDescription ?? '$categoryLabel aquarium',
  ];

  if (customName != null && customName.isNotEmpty) {
    parts.add('custom tank name: $customName');
  }
  if (customDescription != null && customDescription.isNotEmpty) {
    parts.add('user notes for AI: $customDescription');
  }

  return parts.join('. ');
}
