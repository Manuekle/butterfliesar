import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import com.android.build.api.dsl.BuildType

plugins {
    id("com.android.application")
    kotlin("android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.butterfliesar"
    compileSdk = 36  // Actualizado a la versión más alta requerida por los plugins
    ndkVersion = "27.0.12077973"  // Versión requerida por los plugins

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.butterfliesar"
        minSdk = 24  // Mínimo para ARCore
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        
        ndk {
            abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a"))
        }
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    
    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "/META-INF/DEPENDENCIES"
            excludes += "/META-INF/LICENSE*"
            excludes += "/META-INF/NOTICE*"
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
    implementation("com.google.ar:core:1.40.0")  // Versión ligeramente anterior más estable
    
    // Sceneform
    implementation("com.google.ar.sceneform:core:1.17.1")
    implementation("com.google.ar.sceneform.ux:sceneform-ux:1.17.1")
    
    // Excluir duplicados
    configurations.all {
        exclude(group = "com.google.flatbuffers", module = "flatbuffers-java")
        exclude(group = "com.google.ar.sceneform", module = "plugin")
    }
}

// Asegurar que el plugin ARCore se configure correctamente
afterEvaluate {
    tasks.named("mergeReleaseResources") {
        dependsOn(":arcore_flutter_plugin:extractProguardFiles")
    }
}
