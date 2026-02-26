// Web implementation – creates AdSense <ins> platform views for HtmlElementView.
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

import '../constants.dart';

int _adSenseViewCounter = 0;

/// Registers a Flutter platform-view factory for an AdSense [slot].
///
/// Returns a unique [viewType] string to pass to [HtmlElementView].
/// Safe to call from [initState]; each call generates a new unique factory.
String registerAdSenseFactory(
  String slot,
  String format, {
  bool responsive = true,
}) {
  final viewType = 'adsense-$slot-${_adSenseViewCounter++}';

  try {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final ins = web.document.createElement('ins') as web.HTMLElement;
      ins.className = 'adsbygoogle';
      ins.style.display = 'block';
      ins.style.width = '100%';
      ins.style.height = '100%';
      ins.setAttribute('data-ad-client', adSenseAppId);
      ins.setAttribute('data-ad-slot', slot);
      ins.setAttribute('data-ad-format', format);
      if (responsive) {
        ins.setAttribute('data-full-width-responsive', 'true');
      }
      // Push after the element is attached to the DOM.
      Future.microtask(_pushAdSense);
      return ins;
    });
  } catch (_) {
    // Factory already registered (e.g. during hot-reload) – ignore.
  }

  return viewType;
}

/// Equivalent to `(adsbygoogle = window.adsbygoogle || []).push({})`.
void _pushAdSense() {
  final win = web.window as JSObject;
  var arr = win.getProperty('adsbygoogle'.toJS);
  if (arr == null) {
    final newArr = JSArray<JSObject>();
    win.setProperty('adsbygoogle'.toJS, newArr);
    arr = newArr;
  }
  (arr as JSObject).callMethodVarArgs('push'.toJS, [JSObject()]);
}
