plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.appteam.nimbus_2k26_frontend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            storeFile = file(project.property("MYAPP_STORE_FILE") as String)
            storePassword = project.property("MYAPP_STORE_PASSWORD") as String
            keyAlias = project.property("MYAPP_KEY_ALIAS") as String
            keyPassword = project.property("MYAPP_KEY_PASSWORD") as String
        }
    }

    defaultConfig {
        applicationId = "com.appteam.nimbus_2k26_frontend"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders += mapOf("appAuthRedirectScheme" to "com.appteam.nimbus_2k26_frontend")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")  // ← changed from debug
        }
    }
}

flutter {
    source = "../.."
}
<<<<<<< HEAD

dependencies {
    implementation("com.pusher:pusher-java-client:2.4.2")
}
=======
>>>>>>> ba70c8c63c6599438c4461785c3f2c46fb1e1968
