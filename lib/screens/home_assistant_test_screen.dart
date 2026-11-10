import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main_layout.dart';
import '../services/home_assistant_service.dart';

/// Experimental, self-contained screen for testing the Home Assistant
/// REST integration: connect, pick sensors, and view a live dashboard.
class HomeAssistantTestScreen extends StatefulWidget {
  const HomeAssistantTestScreen({super.key});

  @override
  State<HomeAssistantTestScreen> createState() =>
      _HomeAssistantTestScreenState();
}

class _HomeAssistantTestScreenState extends State<HomeAssistantTestScreen> {
  static const _intervals = [60, 120, 300, 600];

  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  HomeAssistantService _service = HomeAssistantService();
  List<HaSensorConfig> _selected = [];
  List<HaSensor> _available = [];
  List<HaSensor> _readings = [];
  String _filter = '';
  bool _showToken = false;
  bool _busy = false;
  bool _loaded = false;
  String? _status;
  bool _statusIsError = false;
  DateTime? _lastRefresh;
  int _intervalSeconds = 60;
  Timer? _timer;
  bool _isEditMode = false;
  final List<List<HaSensorConfig>> _undoStack = [];

  String _summaryTitle = 'My Aquarium';
  List<String> _summaryEntityIds = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final (service, selected) = await HomeAssistantService.load();
    final (summaryTitle, summaryEntityIds) = await HomeAssistantService.loadSummary();
    if (!mounted) return;
    setState(() {
      _service = service;
      _selected = selected;
      _summaryTitle = summaryTitle;
      _summaryEntityIds = summaryEntityIds;
      _urlController.text = service.baseUrl;
      _tokenController.text = service.token;
      _loaded = true;
    });
    if (service.baseUrl.isNotEmpty && service.token.isNotEmpty) {
      await _refreshReadings();
      _startPolling();
    }
  }

  void _startPolling() {
    _timer?.cancel();
    if (!mounted) return;
    _timer = Timer.periodic(
      Duration(seconds: _intervalSeconds),
      (_) => _refreshReadings(),
    );
  }

  void _setStatus(String message, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _status = message;
      _statusIsError = error;
    });
  }

  void _applyCredentials() {
    _service.baseUrl = HomeAssistantService.normalizeUrl(_urlController.text);
    _service.token = _tokenController.text.trim();
    _urlController.text = _service.baseUrl;
  }

  Future<void> _connect() async {
    _applyCredentials();
    if (_service.baseUrl.isEmpty || _service.token.isEmpty) {
      _setStatus('Enter both a URL and an access token.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final msg = await _service.testConnection();
      final sensors = await _service.fetchSensors();
      await _service.save(_selected);
      if (!mounted) return;
      setState(() => _available = sensors);
      _setStatus('$msg — found ${sensors.length} sensors.');
      await _refreshReadings();
      _startPolling();
    } on HaException catch (e) {
      _setStatus(e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadSensors() async {
    _applyCredentials();
    setState(() => _busy = true);
    try {
      final sensors = await _service.fetchSensors();
      if (mounted) setState(() => _available = sensors);
    } on HaException catch (e) {
      _setStatus(e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshReadings() async {
    if (_selected.isEmpty ||
        _service.baseUrl.isEmpty ||
        _service.token.isEmpty) {
      if (mounted) setState(() => _readings = []);
      return;
    }
    try {
      final readings = await _service.fetchSelected(_selected);
      if (!mounted) return;
      setState(() {
        _readings = readings;
        _lastRefresh = DateTime.now();
        if (_statusIsError) _status = null;
      });
    } on HaException catch (e) {
      _setStatus(e.message, error: true);
    }
  }

  Future<void> _toggle(String id, bool on) async {
    setState(() {
      if (on) {
        if (!_selected.any((c) => c.entityId == id)) {
          _selected = [..._selected, HaSensorConfig(entityId: id, fractionDigits: 2)];
        }
      } else {
        _selected = _selected.where((c) => c.entityId != id).toList();
      }
    });
    await _service.save(_selected);
    await _refreshReadings();
  }

  void _enterEditMode() {
    setState(() {
      _isEditMode = true;
      _undoStack.clear();
    });
  }

  void _exitEditMode() {
    setState(() {
      _isEditMode = false;
      _undoStack.clear();
    });
  }

  void _saveUndoState() {
    _undoStack.add(List.from(_selected));
  }

  Future<void> _updateConfig(int index, HaSensorConfig newConfig) async {
    _saveUndoState();
    setState(() {
      _selected[index] = newConfig;
    });
    await _service.save(_selected);
    await _refreshReadings();
  }

  Future<void> _removeSensor(int index) async {
    _saveUndoState();
    setState(() {
      _selected.removeAt(index);
    });
    await _service.save(_selected);
    await _refreshReadings();
  }

  Future<void> _disconnect() async {
    _timer?.cancel();
    await HomeAssistantService.clear();
    if (!mounted) return;
    setState(() {
      _service = HomeAssistantService();
      _selected = [];
      _available = [];
      _readings = [];
      _urlController.clear();
      _tokenController.clear();
      _status = 'Disconnected and cleared saved settings.';
      _statusIsError = false;
      _isEditMode = false;
      _undoStack.clear();
      _summaryTitle = 'My Aquarium';
      _summaryEntityIds = [];
    });
  }

  void _showEditOverlay(BuildContext context, int index) {
    final config = _selected[index];

    String tempEntityId = config.entityId;
    String? tempName = config.customName;
    String tempDigits = config.fractionDigits?.toString() ?? '2';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentSensorInfo = _available.firstWhere(
              (s) => s.entityId == tempEntityId,
              orElse: () => _readings.firstWhere(
                (r) => r.entityId == tempEntityId,
                orElse: () => HaSensor(entityId: tempEntityId, name: tempEntityId, state: ''),
              ),
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.haEditSensor, style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tempEntityId,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.haSourceEntity, border: OutlineInputBorder()),
                    isExpanded: true,
                    items: [
                      if (!_available.any((s) => s.entityId == tempEntityId))
                        DropdownMenuItem(value: tempEntityId, child: Text(tempEntityId)),
                      ..._available.map((s) => DropdownMenuItem(
                        value: s.entityId,
                        child: Text('${s.name} (${s.entityId})', overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() => tempEntityId = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: tempName,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.haCustomNameHint,
                      hintText: currentSensorInfo.name,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => tempName = v.trim().isEmpty ? null : v.trim(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: tempDigits,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.haDecimalPoints, border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => tempDigits = v,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _removeSensor(index);
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red)),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              final newConfig = HaSensorConfig(
                                entityId: tempEntityId,
                                customName: tempName,
                                fractionDigits: int.tryParse(tempDigits) ?? 2,
                              );
                              Navigator.pop(ctx);
                              _updateConfig(index, newConfig);
                            },
                            child: Text(AppLocalizations.of(context)!.save),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: AppLocalizations.of(context)!.haTestScreenTitle,
      floatingActionButton: _isEditMode
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_undoStack.isNotEmpty)
                  FloatingActionButton.small(
                    onPressed: () async {
                      setState(() {
                        _selected = _undoStack.removeLast();
                      });
                      await _service.save(_selected);
                      await _refreshReadings();
                    },
                    heroTag: 'undo',
                    child: const Icon(Icons.undo),
                  ),
                if (_undoStack.isNotEmpty) const SizedBox(height: 8),
                FloatingActionButton.extended(
                  onPressed: _exitEditMode,
                  icon: const Icon(Icons.check),
                  label: Text(AppLocalizations.of(context)!.haDone),
                  heroTag: 'done',
                ),
              ],
            )
          : null,
      child: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildConnectionCard(context),
                const SizedBox(height: 16),
                _buildTankSummaryWidget(context),
                const SizedBox(height: 16),
                _buildDashboard(context),
                const SizedBox(height: 16),
                _buildPicker(context),
              ],
            ),
    );
  }

  Widget _buildConnectionCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.haUrlLabel,
                hintText: 'http://homeassistant.local:8123',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              obscureText: !_showToken,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.haTokenLabel,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showToken ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _showToken = !_showToken),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _connect,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link),
                    label: Text(AppLocalizations.of(context)!.haConnectAndLoad),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _disconnect,
                  child: Text(AppLocalizations.of(context)!.clear),
                ),
              ],
            ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Text(
                _status!,
                style: TextStyle(
                  color: _statusIsError ? scheme.error : scheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.haTokenSecurelyEncrypted,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _showSummaryConfigOverlay(BuildContext context) {
    String tempTitle = _summaryTitle;
    List<String> tempIds = List.from(_summaryEntityIds);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.haConfigOverviewTitle, style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: tempTitle,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.haTankNameLabel, border: OutlineInputBorder()),
                    onChanged: (v) => tempTitle = v,
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.haSelectSensorsOverview, style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_selected.isEmpty)
                    Text(AppLocalizations.of(context)!.haNoSensorsInDashboard)
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _selected.length,
                        itemBuilder: (context, i) {
                          final config = _selected[i];
                          final isChecked = tempIds.contains(config.entityId);
                          final sensor = _available.firstWhere((s) => s.entityId == config.entityId, orElse: () => HaSensor(entityId: config.entityId, name: config.entityId, state: ''));
                          return CheckboxListTile(
                            title: Text(config.customName ?? sensor.name),
                            subtitle: Text(config.entityId),
                            value: isChecked,
                            onChanged: (v) {
                              setModalState(() {
                                if (v == true) {
                                  tempIds.add(config.entityId);
                                } else {
                                  tempIds.remove(config.entityId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          setState(() {
                            _summaryTitle = tempTitle.trim().isEmpty ? 'My Aquarium' : tempTitle.trim();
                            _summaryEntityIds = tempIds;
                          });
                          await HomeAssistantService.saveSummary(_summaryTitle, _summaryEntityIds);
                        },
                        child: Text(AppLocalizations.of(context)!.save),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummarySensorItem(BuildContext context, String entityId) {
    final theme = Theme.of(context);
    final config = _selected.firstWhere((c) => c.entityId == entityId, orElse: () => HaSensorConfig(entityId: entityId));
    final reading = _readings.firstWhere(
      (r) => r.entityId == entityId,
      orElse: () => HaSensor(entityId: entityId, name: config.customName ?? entityId, state: '—'),
    );
    
    String value = reading.isAvailable ? reading.state : '—';
    if (reading.isAvailable && config.fractionDigits != null) {
      final numVal = double.tryParse(reading.state);
      if (numVal != null) {
        value = numVal.toStringAsFixed(config.fractionDigits!);
      }
    }
    final displayName = config.customName ?? reading.name;
    
    return Container(
      width: 120, // fixed width to allow them to flow nicely
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              if (reading.unit != null && reading.isAvailable) ...[
                const SizedBox(width: 2),
                Text(
                  reading.unit!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTankSummaryWidget(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.haTankOverviewWidget, style: theme.textTheme.titleLarge),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: AppLocalizations.of(context)!.haConfigOverviewTooltip,
              onPressed: () => _showSummaryConfigOverlay(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          color: scheme.secondaryContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _summaryTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                if (_summaryEntityIds.isEmpty)
                  Text(
                    AppLocalizations.of(context)!.haTapSettingsToAddSensors,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSecondaryContainer.withValues(alpha: 0.7)),
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final id in _summaryEntityIds)
                        if (_selected.any((c) => c.entityId == id))
                          _buildSummarySensorItem(context, id),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(AppLocalizations.of(context)!.haDashboard, style: theme.textTheme.titleLarge),
            ),
            DropdownButton<int>(
              value: _intervalSeconds,
              items: [
                for (final s in _intervals)
                  DropdownMenuItem(value: s, child: Text('Every ${s}s')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _intervalSeconds = v);
                _startPolling();
              },
            ),
            IconButton(
              tooltip: AppLocalizations.of(context)!.haRefreshNow,
              icon: const Icon(Icons.refresh),
              onPressed: _refreshReadings,
            ),
          ],
        ),
        if (_lastRefresh != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Last updated ${TimeOfDay.fromDateTime(_lastRefresh!).format(context)}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        if (_selected.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(AppLocalizations.of(context)!.haNoSensorsSelected),
            ),
          )
        else if (_isEditMode)
          Card(
            clipBehavior: Clip.antiAlias,
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selected.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex -= 1;
                _saveUndoState();
                final item = _selected.removeAt(oldIndex);
                _selected.insert(newIndex, item);
                setState(() {});
                await _service.save(_selected);
                await _refreshReadings();
              },
              itemBuilder: (context, index) {
                final config = _selected[index];
                final reading = _readings.firstWhere(
                  (r) => r.entityId == config.entityId,
                  orElse: () => HaSensor(entityId: config.entityId, name: config.customName ?? config.entityId, state: ''),
                );
                return ListTile(
                  key: ValueKey(config.entityId),
                  leading: const Icon(Icons.drag_handle),
                  title: Text(config.customName ?? reading.name),
                  subtitle: Text(config.entityId),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditOverlay(context, index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeSensor(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (int i = 0; i < _selected.length; i++)
                GestureDetector(
                  onLongPress: _enterEditMode,
                  child: _SensorTile(
                    config: _selected[i],
                    sensor: _readings.firstWhere(
                      (r) => r.entityId == _selected[i].entityId,
                      orElse: () => HaSensor(entityId: _selected[i].entityId, name: _selected[i].entityId, state: 'unknown'),
                    ),
                  ),
                ),
            ],
          ),
        if (_selected.isNotEmpty && !_isEditMode) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _enterEditMode,
              icon: const Icon(Icons.edit),
              label: Text(AppLocalizations.of(context)!.haEditDashboard),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPicker(BuildContext context) {
    final theme = Theme.of(context);
    final q = _filter.toLowerCase();
    final filtered = _available
        .where(
          (s) =>
              q.isEmpty ||
              s.name.toLowerCase().contains(q) ||
              s.entityId.toLowerCase().contains(q),
        )
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.haSelectSensors} (${_selected.length})',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _loadSensors,
                  icon: const Icon(Icons.sync),
                  label: Text(AppLocalizations.of(context)!.haReload),
                ),
              ],
            ),
            if (_available.isEmpty)
              Text(AppLocalizations.of(context)!.haConnectToLoadSensors)
            else ...[
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: AppLocalizations.of(context)!.haFilterSensors,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final s = filtered[i];
                    return CheckboxListTile(
                      dense: true,
                      value: _selected.any((c) => c.entityId == s.entityId),
                      title: Text(s.name),
                      subtitle: Text(
                        '${s.entityId} • ${s.state}${s.unit != null ? ' ${s.unit}' : ''}',
                      ),
                      onChanged: (v) => _toggle(s.entityId, v ?? false),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SensorTile extends StatelessWidget {
  final HaSensorConfig config;
  final HaSensor sensor;

  const _SensorTile({required this.config, required this.sensor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    String value = sensor.isAvailable ? sensor.state : '—';
    if (sensor.isAvailable && config.fractionDigits != null) {
      final numVal = double.tryParse(sensor.state);
      if (numVal != null) {
        value = numVal.toStringAsFixed(config.fractionDigits!);
      }
    }

    final displayName = config.customName ?? sensor.name;

    return SizedBox(
      width: 170,
      child: Card(
        color: sensor.isAvailable
            ? scheme.primaryContainer.withValues(alpha: 0.4)
            : scheme.errorContainer.withValues(alpha: 0.4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (sensor.unit != null && sensor.isAvailable) ...[
                      const SizedBox(width: 4),
                      Text(sensor.unit!, style: theme.textTheme.titleSmall),
                    ],
                  ],
                ),
              ),
              if (sensor.lastUpdated != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'Updated ${TimeOfDay.fromDateTime(sensor.lastUpdated!).format(context)}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
