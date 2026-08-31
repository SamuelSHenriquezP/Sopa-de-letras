plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter es OBLIGATORIO para que funcionen las variables 'flutter.'
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sunliesstudio.sopadeletras"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.sunliesstudio.sopadeletras"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = "Ss84.597.280"
            storeFile = file("upload-keystore.jks")
            storePassword = "Ss84.597.280"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
