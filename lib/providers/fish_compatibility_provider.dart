import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// A provider that asynchronously loads the fish compatibility data
final fishCompatibilityProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/fishcompat.json');
  return json.decode(jsonString);
});