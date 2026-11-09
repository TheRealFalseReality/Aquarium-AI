import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HaSensorConfig {
  final String entityId;
  final String? customName;
  final int? fractionDigits;

  const HaSensorConfig({
    required this.entityId,
    this.customName,
    this.fractionDigits,
  });

  factory HaSensorConfig.fromJson(Map<String, dynamic> json) => HaSensorConfig(
    entityId: json['entityId'] as String,
    customName: json['customName'] as String?,
    fractionDigits: json['fractionDigits'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'entityId': entityId,
    if (customName != null) 'customName': customName,
    if (fractionDigits != null) 'fractionDigits': fractionDigits,
  };

  HaSensorConfig copyWith({
    String? entityId,
    String? customName,
    int? fractionDigits,
  }) {
    return HaSensorConfig(
      entityId: entityId ?? this.entityId,
      customName: customName ?? this.customName,
      fractionDigits: fractionDigits ?? this.fractionDigits,
    );
  }
}

class HaSensor {
  final String entityId;
  final String name;
  final String state;
  final String? unit;
  final String? deviceClass;
  final DateTime? lastUpdated;

  const HaSensor({
    required this.entityId,
    required this.name,
    required this.state,
    this.unit,
    this.deviceClass,
    this.lastUpdated,
  });

  factory HaSensor.fromJson(Map<String, dynamic> json) {
    final attrs = (json['attributes'] as Map?)?.cast<String, dynamic>() ?? {};
    final id = json['entity_id'] as String;
    return HaSensor(
      entityId: id,
      name: (attrs['friendly_name'] as String?) ?? id,
      state: json['state']?.toString() ?? 'unknown',
      unit: attrs['unit_of_measurement'] as String?,
      deviceClass: attrs['device_class'] as String?,
      lastUpdated: DateTime.tryParse(json['last_updated']?.toString() ?? '')
          ?.toLocal(),
    );
  }

  double? get numericValue => double.tryParse(state);
  bool get isAvailable => state != 'unavailable' && state != 'unknown';
}

class HaException implements Exception {
  final String message;
  HaException(this.message);
  @override
  String toString() => message;
}

/// Thin REST client for the Home Assistant API.
class HomeAssistantService {
  static const _urlKey = 'ha_base_url';
  static const _tokenKey = 'ha_token';
  static const _selectedKey = 'ha_selected_entities';

  final http.Client _client;
  String baseUrl;
  String token;

  HomeAssistantService({
    this.baseUrl = '',
    this.token = '',
    http.Client? client,
  }) : _client = client ?? http.Client();

  static String normalizeUrl(String url) {
    var u = url.trim();
    if (u.isEmpty) return u;
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Future<dynamic> _get(String path) async {
    final uri = Uri.parse('${normalizeUrl(baseUrl)}$path');
    final http.Response res;
    try {
      res = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw HaException('Could not reach Home Assistant: $e');
    }
    if (res.statusCode == 401) {
      throw HaException('Unauthorized: check your access token.');
    }
    if (res.statusCode == 404) {
      throw HaException('Not found (404): ${uri.path}');
    }
    if (res.statusCode != 200) {
      throw HaException('Home Assistant returned ${res.statusCode}.');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  /// Returns the HA welcome message on success.
  Future<String> testConnection() async {
    final data = await _get('/api/');
    return (data as Map)['message']?.toString() ?? 'Connected';
  }

  Future<List<HaSensor>> fetchSensors() async {
    final data = await _get('/api/states') as List;
    final sensors = data
        .cast<Map<String, dynamic>>()
        .where((e) => (e['entity_id'] as String).startsWith('sensor.'))
        .map(HaSensor.fromJson)
        .toList();
    sensors.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return sensors;
  }

  Future<HaSensor> fetchSensor(String entityId) async {
    final data = await _get('/api/states/$entityId');
    return HaSensor.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<List<HaSensor>> fetchSelected(List<HaSensorConfig> configs) async {
    final all = await fetchSensors();
    final byId = {for (final s in all) s.entityId: s};
    return [for (final config in configs) if (byId[config.entityId] != null) byId[config.entityId]!];
  }

  Future<void> save(List<HaSensorConfig> selected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, baseUrl);
    await prefs.setString(_tokenKey, token);
    await prefs.setStringList(
        _selectedKey, selected.map((c) => jsonEncode(c.toJson())).toList());
  }

  static Future<(HomeAssistantService, List<HaSensorConfig>)> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_selectedKey) ?? <String>[];
    final configs = list.map((item) {
      try {
        if (item.startsWith('{')) {
          return HaSensorConfig.fromJson(jsonDecode(item));
        }
      } catch (_) {}
      return HaSensorConfig(entityId: item);
    }).toList();

    return (
      HomeAssistantService(
        baseUrl: prefs.getString(_urlKey) ?? '',
        token: prefs.getString(_tokenKey) ?? '',
      ),
      configs,
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_urlKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_selectedKey);
  }
}
