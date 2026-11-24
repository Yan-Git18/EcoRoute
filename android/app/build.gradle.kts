import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val useLegacySigning = providers.environmentVariable("ECOROUTE_ANDROID_LEGACY_SIGNING")
    .map { it.equals("true", ignoreCase = true) }
    .getOrElse(false)
val signingPropertiesFile = rootProject.file("key.properties")
val signingProperties = Properties()
if (!useLegacySigning && signingPropertiesFile.isFile) {
    signingPropertiesFile.inputStream().use { signingProperties.load(it) }
}
val releaseKeyStore = signingProperties.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }
    ?.let { rootProject.file(it) }

android {
    namespace = "com.example.ecoroute"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.ecoroute"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = releaseKeyStore
            storePassword = signingProperties.getProperty("storePassword")
            keyAlias = signingProperties.getProperty("keyAlias")
            keyPassword = signingProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (useLegacySigning) "debug" else "release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

val checkReleaseSigning = tasks.register("checkReleaseSigning") {
    doLast {
        if (!useLegacySigning) {
            check(signingPropertiesFile.isFile) {
                "Configura android/key.properties para firmar la versión de publicación. Consulta el README."
            }
            check(listOf("storeFile", "storePassword", "keyAlias", "keyPassword").all {
                !signingProperties.getProperty(it).isNullOrBlank()
            }) {
                "Completa storeFile, storePassword, keyAlias y keyPassword en android/key.properties."
            }
            check(releaseKeyStore?.isFile == true) {
                "El archivo de firma indicado en storeFile no existe."
            }
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(checkReleaseSigning)
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core:1.16.0")
}
