package com.cca.fishai

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge display for Android 15+ compatibility
        // This replaces the deprecated WindowCompat.setDecorFitsSystemWindows approach
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
