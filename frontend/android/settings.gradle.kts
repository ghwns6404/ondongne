pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// Use settings-level repositories instead of deprecated allprojects{}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        // Flutter Android artifacts (예: flutter_embedding_debug)를 위한 저장소
        maven {
            url = uri("https://storage.googleapis.com/download.flutter.io")
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // 기존 Flutter 템플릿에서 사용하던 AGP 버전으로 복원
    id("com.android.application") version "8.3.2" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.4.2") apply false
    // END: FlutterFire Configuration
    // Kotlin도 AGP 8.9.1과 호환되는 2.x 대로 올리는 것이 권장이나,
    // Flutter에서 아직 2.x 지원 안내가 없다면 추후 업그레이드 검토
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}

include(":app")
