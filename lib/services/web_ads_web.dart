// Web implementation – calls the JS bridge functions defined in index.html.
import 'dart:js_interop';

@JS('hideOverlayAds')
external void hideOverlayAds();

@JS('showOverlayAds')
external void showOverlayAds();
