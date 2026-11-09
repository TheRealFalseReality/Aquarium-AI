import 'dart:async';

import 'package:flutter/material.dart';

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
    if (!mounted) return;
    setState(() {
      _service = service;
      _selected = selected;
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
                  Text('Edit Sensor', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tempEntityId,
                    decoration: const InputDecoration(labelText: 'Source Entity', border: OutlineInputBorder()),
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
                      labelText: 'Custom Name (leave blank for default)',
                      hintText: currentSensorInfo.name,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => tempName = v.trim().isEmpty ? null : v.trim(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: tempDigits,
                    decoration: const InputDecoration(labelText: 'Decimal Points to Display', border: OutlineInputBorder()),
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
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
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
                            child: const Text('Save'),
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
      title: 'Home Assistant (BETA)',
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
                  label: const Text('Done'),
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
              decoration: const InputDecoration(
                labelText: 'Home Assistant URL',
                hintText: 'http://homeassistant.local:8123',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              obscureText: !_showToken,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Long-Lived Access Token',
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
                    label: const Text('Connect & load sensors'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _busy ? null : _disconnect,
                  child: const Text('Clear'),
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
              'Testing only: the token is stored unencrypted on this device.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
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
              child: Text('Dashboard', style: theme.textTheme.titleLarge),
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
              tooltip: 'Refresh now',
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
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No sensors selected yet. Pick some below.'),
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
              label: const Text('Edit Dashboard'),
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
                    'Select sensors (${_selected.length})',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _loadSensors,
                  icon: const Icon(Icons.sync),
                  label: const Text('Reload'),
                ),
              ],
            ),
            if (_available.isEmpty)
              const Text('Connect to load the list of available sensors.')
            else ...[
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Filter sensors',
                  border: OutlineInputBorder(),
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
