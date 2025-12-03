package com.cca.fishai

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge display for backward compatibility on Android 15+
        // This is required for apps targeting SDK 35 to display correctly
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
