// lib/services/deep_link_service.dart

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants.dart' show deepLinkHost, deepLinkScheme;
import 'analytics_service.dart';

/// Centralized deep-link handler for the app.
///
/// Supports three URI flavours:
///
/// 1. **Custom scheme** – `aquariumai://<path>?<query>`
///    (e.g. `aquariumai://chatbot`, `aquariumai://tank?id=abc`)
///
/// 2. **HTTPS App Links / Universal Links** –
///    `https://fishai-31d40.web.app/<path>?<query>`
///
/// 3. **Web hash-fragment routes** – handled by the Flutter web router
///    automatically (e.g. `https://fishai-31d40.web.app/#/chatbot`).
///
/// ## Supported deep-link paths
///
/// | Path | Query params | Screen |
/// | ---- | ------------ | ------ |
/// | `/` or empty | | WelcomeScreen |
/// | `/chatbot` | `action=photo\|water\|fishinfo` | ChatbotScreen |
/// | `/settings` | `openAIProvider=true` | SettingsScreen |
/// | `/appearance` | | AppearanceScreen |
/// | `/calculators` | | CalculatorsScreen |
/// | `/tank-volume` | | TankVolumeCalculator |
/// | `/substrate` | | SubstrateCalculator |
/// | `/stocking` | | AquariumStockingScreen |
/// | `/compat-ai` | | FishCompatibilityScreen |
/// | `/compat-browser` | | FishCompatBrowserScreen |
/// | `/photo-analyzer` | | PhotoAnalysisScreen |
/// | `/tank-management` | | TankManagementScreen |
/// | `/community` | | CommunityScreen |
/// | `/community/post` | `id=<postId>` | CommunityPostScreen (via community) |
/// | `/profile` | `userId=<uid>` | ProfileScreen |
/// | `/auth` | | AuthScreen |
/// | `/onboarding` | `page=<0-based index>` | OnboardingScreen |
/// | `/about` | | AboutScreen |
/// | `/information` | | InformationScreen |
/// | `/analysis-history` | | AnalysisHistoryScreen |
/// | `/species-tags` | | SpeciesTagsScreen |
class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService _instance = DeepLinkService._();

  /// Singleton accessor.
  static DeepLinkService get instance => _instance;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  /// Navigator key used to push routes from outside the widget tree.
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Whether [initialize] has been called.
  bool _initialized = false;

  /// Pending URI that arrived before a navigator was available.
  Uri? _pendingUri;

  // ── Public API ──────────────────────────────────────────────────────────

  /// Initialize the deep-link listener.
  ///
  /// Must be called once during app startup (typically in `main()`).
  /// [navigatorKey] is the same global key passed to [MaterialApp.navigatorKey].
  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (_initialized) return;
    _initialized = true;
    _navigatorKey = navigatorKey;
    _appLinks = AppLinks();

    // 1. Check for an initial (cold-start) link.
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DeepLinkService: failed to get initial link – $e');
      }
    }

    // 2. Listen for subsequent (warm-start) links.
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (error) {
        if (kDebugMode) {
          debugPrint('DeepLinkService: link stream error – $error');
        }
      },
    );
  }

  /// Dispose the stream subscription.  Safe to call multiple times.
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  /// If a deep-link URI arrived before the navigator was ready, call this
  /// after the first frame to process it.
  void processPendingDeepLink() {
    if (_pendingUri != null) {
      final uri = _pendingUri!;
      _pendingUri = null;
      _handleUri(uri);
    }
  }

  // ── URI handling ────────────────────────────────────────────────────────

  void _handleUri(Uri uri) {
    if (kDebugMode) {
      debugPrint('DeepLinkService: received URI – $uri');
    }

    // Validate scheme + host for HTTPS links, or accept our custom scheme.
    if (uri.scheme == 'https') {
      if (uri.host != deepLinkHost) {
        if (kDebugMode) {
          debugPrint('DeepLinkService: ignoring unknown host ${uri.host}');
        }
        return;
      }
    } else if (uri.scheme != deepLinkScheme) {
      if (kDebugMode) {
        debugPrint('DeepLinkService: ignoring unknown scheme ${uri.scheme}');
      }
      return;
    }

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      // Navigator not mounted yet – stash for later.
      _pendingUri = uri;
      if (kDebugMode) {
        debugPrint('DeepLinkService: navigator not ready, queuing URI');
      }
      return;
    }

    _navigateForUri(navigator, uri);
  }

  void _navigateForUri(NavigatorState navigator, Uri uri) {
    final path = uri.path.isEmpty ? '/' : uri.path;
    final query = uri.queryParameters;

    // Log the deep link event to analytics.
    AnalyticsService.logFeatureUsed(
      featureName: 'deep_link',
      parameters: {'path': path},
    ).catchError((e) {
      if (kDebugMode) {
        debugPrint('DeepLinkService: analytics error – $e');
      }
    });

    switch (path) {
      case '/':
        navigator.pushNamedAndRemoveUntil('/', (route) => false);
        break;

      case '/chatbot':
        final action = query['action'];
        final Map<String, dynamic> args = {};
        if (action == 'photo') args['openPhotoAnalyzer'] = true;
        if (action == 'water') args['openWaterAnalysis'] = true;
        if (action == 'fishinfo') args['openFishInfo'] = true;
        navigator.pushNamedAndRemoveUntil(
          '/chatbot',
          (route) => route.isFirst,
          arguments: args.isNotEmpty ? args : null,
        );
        break;

      case '/settings':
        final openAI = query['openAIProvider'] == 'true';
        navigator.pushNamedAndRemoveUntil(
          '/settings',
          (route) => route.isFirst,
          arguments: openAI ? {'openAIProvider': true} : null,
        );
        break;

      case '/onboarding':
        final page = int.tryParse(query['page'] ?? '') ?? 0;
        navigator.pushNamedAndRemoveUntil(
          '/onboarding',
          (route) => route.isFirst,
          arguments: {'initialPage': page},
        );
        break;

      case '/profile':
        final userId = query['userId'];
        navigator.pushNamedAndRemoveUntil(
          '/profile',
          (route) => route.isFirst,
          arguments: userId != null ? {'userId': userId} : null,
        );
        break;

      case '/community/post':
        // Navigate to community first; the post ID can be handled by the
        // community screen once loaded.
        final postId = query['id'];
        navigator.pushNamedAndRemoveUntil(
          '/community',
          (route) => route.isFirst,
          arguments: postId != null ? {'postId': postId} : null,
        );
        break;

      // Simple routes (no arguments)
      case '/about':
      case '/information':
      case '/tank-volume':
      case '/substrate':
      case '/calculators':
      case '/stocking':
      case '/compat-ai':
      case '/compat-browser':
      case '/photo-analyzer':
      case '/appearance':
      case '/tank-management':
      case '/species-tags':
      case '/analysis-history':
      case '/community':
      case '/auth':
        navigator.pushNamedAndRemoveUntil(
          path,
          (route) => route.isFirst,
        );
        break;

      default:
        if (kDebugMode) {
          debugPrint('DeepLinkService: unknown path "$path", going to home');
        }
        navigator.pushNamedAndRemoveUntil('/', (route) => false);
        break;
    }
  }

  // ── Helpers for generating deep-link URIs ───────────────────────────────

  /// Build an HTTPS deep-link URI for the given [path] and optional [queryParameters].
  static Uri buildHttpsUri(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    return Uri(
      scheme: 'https',
      host: deepLinkHost,
      path: path,
      queryParameters:
          queryParameters?.isNotEmpty == true ? queryParameters : null,
    );
  }

  /// Build a custom-scheme deep-link URI for the given [path] and optional [queryParameters].
  ///
  /// Produces URIs like `aquariumai://chatbot` or `aquariumai://profile?userId=abc`.
  static Uri buildCustomSchemeUri(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final queryString = queryParameters != null && queryParameters.isNotEmpty
        ? '?${queryParameters.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';
    return Uri.parse('$deepLinkScheme:/$path$queryString');
  }

  /// Build a shareable HTTPS link to a community post.
  static String communityPostLink(String postId) {
    return buildHttpsUri('/community/post', queryParameters: {'id': postId})
        .toString();
  }

  /// Build a shareable HTTPS link to a user profile.
  static String profileLink(String userId) {
    return buildHttpsUri('/profile', queryParameters: {'userId': userId})
        .toString();
  }

  /// Build a shareable HTTPS link to the chatbot with an optional action.
  static String chatbotLink({String? action}) {
    return buildHttpsUri(
      '/chatbot',
      queryParameters: action != null ? {'action': action} : null,
    ).toString();
  }

  /// Build a shareable HTTPS link to the onboarding at a specific page.
  static String onboardingLink({int page = 0}) {
    return buildHttpsUri(
      '/onboarding',
      queryParameters: page > 0 ? {'page': page.toString()} : null,
    ).toString();
  }
}
