import java.util.Properties
import java.io.FileInputStream
import java.util.Base64
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

// Extract flutter dart-defines
val dartEnvironmentVariables = mutableMapOf<String, String>()
if (project.hasProperty("dart-defines")) {
    val defines = project.property("dart-defines") as String
    defines.split(",").forEach {
        val decoded = String(Base64.getDecoder().decode(it))
        val split = decoded.split("=", limit = 2)
        if (split.size == 2) {
            dartEnvironmentVariables[split[0]] = split[1]
        }
    }
}

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.firebase.crashlytics") version "3.0.6"
}

android {
    namespace = "com.cca.fishai"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String? ?: ""
            keyPassword = keyProperties["keyPassword"] as String? ?: ""
            storeFile = if (keyProperties["storeFile"] != null) file(keyProperties["storeFile"] as String) else null
            storePassword = keyProperties["storePassword"] as String? ?: ""
        }
    }

    defaultConfig {
        applicationId = "com.cca.fishai"
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Facebook SDK requires the App ID and Client Token at native build time.
        // The App ID is public; the Client Token is read from the FACEBOOK_CLIENT_TOKEN
        // passed via --dart-define=FACEBOOK_CLIENT_TOKEN=XXXX or environment variable.
        val fbClientToken = dartEnvironmentVariables["FACEBOOK_CLIENT_TOKEN"] 
            ?: System.getenv("FACEBOOK_CLIENT_TOKEN") 
            ?: ""
            
        if (fbClientToken.isEmpty()) {
            logger.warn(
                "[WARNING] FACEBOOK_CLIENT_TOKEN is not set. " +
                "Facebook Login will not work at runtime. " +
                "Set it via --dart-define=FACEBOOK_CLIENT_TOKEN=XXXX before a release build."
            )
        }
        resValue("string", "facebook_app_id", "941109785269057")
        resValue("string", "facebook_client_token", fbClientToken)
        resValue("string", "fb_login_protocol_scheme", "fb941109785269057")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // ProGuard/R8 configuration for flutter_local_notifications
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    flavorDimensions += "default"
    productFlavors {
        create("staging") {
            dimension = "default"
            resValue(
                type = "string",
                name = "app_name",
                value = "Aquarium AI dev")
            applicationIdSuffix = ".dev"
        }
        create("production") {
            dimension = "default"
            resValue(
                type = "string",
                name = "app_name",
                value = "Aquarium AI")
        }
    }

}

flutter {
    source = "../.."
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    implementation("com.google.android.material:material:1.13.0")
    implementation("androidx.core:core-ktx:1.17.0")

    // Core library desugaring for flutter_local_notifications
    // Updated to 2.1.4+ to satisfy flutter_local_notifications AAR metadata
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    // Add the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.2.0"))
    // Add the Crashlytics dependency
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-analytics")

    // Play Integrity API
    implementation("com.google.android.play:integrity:1.6.0")

    // Facebook Login SDK – required by flutter_facebook_auth for Android.
    // Pinned to the same version that flutter_facebook_auth 7.x bundles so
    // that Gradle resolves a single consistent version.
    implementation("com.facebook.android:facebook-login:17.0.2")
}