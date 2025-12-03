package com.cca.fishai

import android.os.Bundle
import androidx.activity.EdgeToEdge
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge display for backward compatibility on Android 15+
        // This is required for apps targeting SDK 35 to display correctly
        // Use EdgeToEdge.enable() instead of enableEdgeToEdge() extension function
        // since FlutterActivity extends Activity, not ComponentActivity
        EdgeToEdge.enable(this)
        super.onCreate(savedInstanceState)
    }
}
