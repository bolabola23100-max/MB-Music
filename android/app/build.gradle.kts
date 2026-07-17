plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mbmusic.player"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        create("release") {
            storeFile = file("../../my-release-key.jks")
            storePassword = "m_01229306370_b_01019204419_mb_music"
            keyAlias = "my-key-alias"
            keyPassword ="m_01229306370_b_01019204419_mb_music"
        }
    }

    defaultConfig {
        applicationId = "com.mbmusic.player"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}