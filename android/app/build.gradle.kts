import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
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
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId = "com.cca.fishai"
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Facebook SDK credentials – read from environment variables first,
        // then fall back to key.properties entries.
        // Set FACEBOOK_APP_ID and FACEBOOK_CLIENT_TOKEN in your CI environment
        // or add them to android/key.properties (do not commit that file).
        val facebookAppId: String =
            System.getenv("FACEBOOK_APP_ID")
                ?: (keyProperties["facebookAppId"] as? String ?: "")
        val facebookClientToken: String =
            System.getenv("FACEBOOK_CLIENT_TOKEN")
                ?: (keyProperties["facebookClientToken"] as? String ?: "")
        manifestPlaceholders["facebookAppId"] = facebookAppId
        manifestPlaceholders["facebookClientToken"] = facebookClientToken
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
}