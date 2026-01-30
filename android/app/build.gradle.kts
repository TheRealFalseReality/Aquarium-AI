import java.util.Properties
import java.io.FileInputStream

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

flutter {
    source = "../.."
}

android {
    namespace = "com.cca.fishai"
    compileSdk = flutter.compileSdkVersion ?: 34
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as? String ?: ""
            keyPassword = keyProperties["keyPassword"] as? String ?: ""
            val storeFileProp = keyProperties["storeFile"] as? String
            if (storeFileProp != null) {
                storeFile = file(storeFileProp)
            }
            storePassword = keyProperties["storePassword"] as? String ?: ""
        }
    }

    defaultConfig {
        applicationId = "com.cca.fishai"
        minSdk = flutter.minSdkVersion ?: 21
        targetSdk = flutter.targetSdkVersion ?: 34
        versionCode = flutter.versionCode ?: 1
        versionName = flutter.versionName ?: "1.0.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
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

dependencies {
    implementation("com.google.android.material:material:1.13.0")
    implementation("androidx.core:core-ktx:1.17.0")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    implementation(platform("com.google.firebase:firebase-bom:34.8.0"))
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-analytics")
}