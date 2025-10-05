// Web-specific AdSense implementation
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import '../services/ad_helper.dart';

/// Register a web view for displaying AdSense ads
void registerAdSenseView(String viewId) {
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final div = html.DivElement()
      ..style.width = '100%'
      ..style.minHeight = '90px'
      ..style.display = 'flex'
      ..style.justifyContent = 'center'
      ..style.alignItems = 'center';

    final ins = html.Element.html('''
      <ins class="adsbygoogle"
           style="display:block"
           data-ad-client="${AdHelper.adSenseAppIdForWeb}"
           data-ad-slot="${AdHelper.adSenseAdUnitIdForWeb}"
           data-ad-format="auto"
           data-full-width-responsive="true"></ins>
    ''');
    
    div.append(ins);
    
    // Push the ad
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        // ignore: avoid_dynamic_calls
        (html.window as dynamic).adsbygoogle?.push({});
      } catch (e) {
        if (kDebugMode) {
          print('AdSense push error: $e');
        }
      }
    });

    return div;
  });
}
