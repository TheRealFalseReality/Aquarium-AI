package com.cca.fishai

import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val integrityChannel = "com.cca.fishai/play_integrity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, integrityChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getIntegrityToken" -> {
                        val nonce = call.argument<String>("nonce")
                        if (nonce == null) {
                            result.error("INVALID_ARGUMENT", "nonce is required", null)
                            return@setMethodCallHandler
                        }
                        val integrityManager =
                            IntegrityManagerFactory.create(applicationContext)
                        integrityManager
                            .requestIntegrityToken(
                                IntegrityTokenRequest.builder()
                                    .setNonce(nonce)
                                    .build()
                            )
                            .addOnSuccessListener(mainExecutor) { response ->
                                result.success(response.token())
                            }
                            .addOnFailureListener(mainExecutor) { exception ->
                                result.error(
                                    "INTEGRITY_ERROR",
                                    exception.message,
                                    null
                                )
                            }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
