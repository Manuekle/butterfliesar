plugins {
    id("com.android.application")
    kotlin("android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.butterfliesar"
    compileSdk = 36
    buildToolsVersion = "34.0.0"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
    
    // Configure Java compilation to avoid --release flag issues
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.remove("--release")
        options.isFork = true
        options.forkOptions.javaHome = File(System.getProperty("java.home"))
    }

    defaultConfig {
        applicationId = "com.example.butterfliesar"
        minSdk = 24  // Must match the version set in root build.gradle.kts
        targetSdk = 36  // Actualizado para consistencia
        versionCode = 1
        versionName = "1.0.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
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
    
    packaging {  // Sintaxis actualizada
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")  // Actualizado
    
    // AndroidX Test
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test:runner:1.6.2")  // Actualizado
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")  // Actualizado
}