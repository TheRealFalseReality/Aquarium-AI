import '../models/tank.dart';

String mergeUserContextWithEstablishedTanks({
  required List<Tank> tanks,
  String? userContext,
  int maxTanks = 4,
  int maxInhabitantsPerTank = 6,
}) {
  final trimmedUserContext = userContext?.trim() ?? '';
  final tankContext = buildEstablishedTanksContext(
    tanks,
    maxTanks: maxTanks,
    maxInhabitantsPerTank: maxInhabitantsPerTank,
  );
  if (tankContext.isEmpty) return trimmedUserContext;
  if (trimmedUserContext.isEmpty) return tankContext;
  return '$trimmedUserContext\n\n$tankContext';
}

String buildEstablishedTanksContext(
  List<Tank> tanks, {
  int maxTanks = 4,
  int maxInhabitantsPerTank = 6,
}) {
  if (tanks.isEmpty) return '';

  final sortedTanks = [...tanks]
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final selectedTanks = sortedTanks.take(maxTanks).toList();

  final lines = selectedTanks.map((tank) {
    final typeLabel = _formatTankType(tank);
    final sizeLabel = _formatTankSize(tank);
    final inhabitantsLabel = _formatInhabitants(
      tank,
      maxInhabitantsPerTank: maxInhabitantsPerTank,
    );
    final notes = tank.notes?.trim();
    final notesLabel = (notes != null && notes.isNotEmpty)
        ? '; notes: ${_truncate(notes, 180)}'
        : '';
    return '- ${tank.name} ($typeLabel, $sizeLabel); inhabitants: $inhabitantsLabel$notesLabel';
  }).join('\n');

  return '''
Use this established tank context from the user's app profile when relevant:
$lines
''';
}

String _formatTankType(Tank tank) {
  if (tank.type == 'freshwater') {
    if (tank.freshwaterSubtype == 'planted') return 'freshwater (planted)';
    if (tank.freshwaterSubtype == 'brackish') return 'freshwater (brackish)';
    return 'freshwater';
  }
  if (tank.type == 'marine') {
    return tank.isReef ? 'marine (reef)' : 'marine';
  }
  return tank.type;
}

String _formatTankSize(Tank tank) {
  final gallons = tank.sizeGallons;
  final liters = tank.sizeLiters;
  if (gallons != null && liters != null) {
    return '${gallons.toStringAsFixed(0)} gal / ${liters.toStringAsFixed(0)} L';
  }
  if (gallons != null) return '${gallons.toStringAsFixed(0)} gal';
  if (liters != null) return '${liters.toStringAsFixed(0)} L';
  return 'size not specified';
}

String _formatInhabitants(
  Tank tank, {
  required int maxInhabitantsPerTank,
}) {
  if (tank.inhabitants.isEmpty) return 'none listed';

  final withNames = tank.inhabitants.where((i) => i.fishUnit.trim().isNotEmpty);
  if (withNames.isEmpty) return 'none listed';

  final entries = withNames
      .take(maxInhabitantsPerTank)
      .map((i) => '${i.fishUnit} x${i.quantity}')
      .toList();
  final hidden = withNames.length - entries.length;
  if (hidden > 0) entries.add('+$hidden more');
  return entries.join(', ');
}

String _truncate(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength - 3)}...';
}
