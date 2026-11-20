plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Push (M3): google-services.json no se versiona. Solo se aplica el plugin si el
// archivo existe y contiene un cliente para este applicationId; si no, la app
// compila y arranca sin notificaciones push (ver docs/pendientes_movil.md).
// Reutiliza el registro Android ya existente en Firebase (proyecto atemporal-f0125, alias
// "atemporal"): el applicationId debe coincidir con su package_name. El namespace (paquete del
// codigo Kotlin) no cambia.
val idAplicacion = "com.atemporal"
val archivoGoogleServices = file("google-services.json")
if (archivoGoogleServices.exists() &&
    archivoGoogleServices.readText().contains("\"package_name\": \"$idAplicacion\"")
) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.warn("google-services.json ausente o sin cliente para $idAplicacion: push desactivado.")
}

android {
    namespace = "com.traducontext.traducontextmovil"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Requerido por flutter_local_notifications.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = idAplicacion
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
