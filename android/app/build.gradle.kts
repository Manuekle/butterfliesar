import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    kotlin("android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.butterfliesar"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.butterfliesar"
        minSdk = 24  // Required for ARCore
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        
        ndk {
            abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a"))
        }
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Java 8+ API desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // ARCore library
    implementation("com.google.ar:core:1.41.0")
    
    // Use Sceneform from the Flutter AR plugin instead of direct dependency
    // implementation("com.gorisse.thomas.sceneform:sceneform:1.23.0")
    
    // Add this to exclude the duplicate flatbuffers library
    configurations.all {
        exclude(group = "com.google.flatbuffers", module = "flatbuffers-java")
    }
}
