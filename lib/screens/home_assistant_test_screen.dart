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
  static const _intervals = [15, 30, 60, 120];

  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  HomeAssistantService _service = HomeAssistantService();
  List<String> _selected = [];
  List<HaSensor> _available = [];
  List<HaSensor> _readings = [];
  String _filter = '';
  bool _showToken = false;
  bool _busy = false;
  bool _loaded = false;
  String? _status;
  bool _statusIsError = false;
  DateTime? _lastRefresh;
  int _intervalSeconds = 30;
  Timer? _timer;

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
        if (!_selected.contains(id)) _selected = [..._selected, id];
      } else {
        _selected = _selected.where((e) => e != id).toList();
      }
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Home Assistant (Test)',
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
        if (_readings.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No sensors selected yet. Pick some below.'),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [for (final r in _readings) _SensorTile(sensor: r)],
          ),
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
                      value: _selected.contains(s.entityId),
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
  final HaSensor sensor;
  const _SensorTile({required this.sensor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final value = sensor.isAvailable ? sensor.state : '—';
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
                sensor.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Row(
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
              if (sensor.lastUpdated != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Changed ${TimeOfDay.fromDateTime(sensor.lastUpdated!).format(context)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
