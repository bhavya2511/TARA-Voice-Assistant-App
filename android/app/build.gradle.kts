plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tara_va"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    // Use Java 1.8 for desugaring compatibility
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        // enable core library desugaring for plugins that require Java 8+ library support
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        // ensure Kotlin targets Java 8 bytecode
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.tara_va"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Add project dependencies needed for desugaring
dependencies {
    // core library desugaring (enables modern Java library APIs on older Android)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.1.5")
}
