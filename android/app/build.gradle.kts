plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.yuzbasi.wakeup.wake_up"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.yuzbasi.wakeup.wake_up"

        // Alarm paketinin stabil çalışması için minSdk en az 21 olmalı.
        minSdk = flutter.minSdkVersion

        // Modern Android izinleri (Android 14+) için targetSdk 34 olmalı.
        targetSdk = 34

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

subprojects {
    val project = this
    // Sadece 'app' olmayan (dışarıdan gelen paketler) modüllere müdahale et
    if (project.name != "app") {
        project.plugins.withType<com.android.build.gradle.api.AndroidBasePlugin> {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension

            // 1. Namespace Yaması
            if (android.namespace == null) {
                android.namespace = project.group.toString()
            }

            // 2. Alt paketlerin Java seviyesini 17'ye çek
            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }

        // 3. Alt paketlerin Kotlin seviyesini 17'ye çek (Hata buradaydı!)
        project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "17"
            }
        }
    }
}
