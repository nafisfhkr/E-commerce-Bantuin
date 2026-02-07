plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.jkw.bantuin"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // ← Wajib untuk Firebase SDK terbaru

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // Aktifkan desugaring
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.jkw.bantuin"
        minSdk = 23 // ← Tetap 23 sesuai kebutuhan Anda
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
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

dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))

    // Firebase libraries
    implementation("com.google.firebase:firebase-analytics")

    // MultiDex support
    implementation("androidx.multidex:multidex:2.0.1")

    // Tambahkan dependensi desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}