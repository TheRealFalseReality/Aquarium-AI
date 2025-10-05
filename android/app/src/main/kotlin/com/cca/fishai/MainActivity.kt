package com.cca.fishai

import android.os.Bundle
import androidx.activity.EdgeToEdge
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge display for Android 15+ compatibility
        // EdgeToEdge.enable() works with any Activity, not just ComponentActivity
        EdgeToEdge.enable(this)
        super.onCreate(savedInstanceState)
    }
}
