package com.cca.fishai

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // No need to override onCreate for edge-to-edge
    // Flutter handles system bar insets automatically via SystemChrome.setSystemUIOverlayStyle
    // Removing WindowCompat.setDecorFitsSystemWindows fixes the extra spacing issue
}
