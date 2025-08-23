buildscript {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.7.2")  // Actualizado
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://maven.pkg.jetbrains.space/public/p/compose/dev") }
        maven { url = uri("https://jitpack.io") }
    }

    // CLAVE: Forzar la versión de Kotlin para todos los subproyectos
    configurations.all {
        resolutionStrategy {
            force("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
            force("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-common:2.1.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.1.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.1.0")
        }
    }

    // Configure Java 17 for all projects
    afterEvaluate {
        // For Android projects
        if (plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            // Configure Java compilation - explicitly disable --release flag
            tasks.withType<JavaCompile> {
                options.compilerArgs.remove("--release")
                sourceCompatibility = JavaVersion.VERSION_17.toString()
                targetCompatibility = JavaVersion.VERSION_17.toString()
                options.isFork = true
                options.forkOptions.javaHome = File(System.getProperty("java.home"))
                options.compilerArgs.add("--release")
                options.compilerArgs.add("8")  // Use Java 8 bytecode for maximum compatibility
            }
            
            // Configure Kotlin compilation
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
                kotlinOptions {
                    jvmTarget = JavaVersion.VERSION_17.toString()
                    freeCompilerArgs = freeCompilerArgs + "-Xjvm-default=all"
                    // Explicitly set language version for Kotlin
                    apiVersion = "2.1"
                    languageVersion = "2.1"
                }
            }
            
            // Configure Android project
            configure<com.android.build.gradle.BaseExtension> {
                // Using the correct method to set compileSdk
                compileSdkVersion(34)
                
                defaultConfig {
                    minSdk = 24
                    targetSdk = 34
                }
                
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }

        // Forzar Kotlin JVM Target 17 en todos los proyectos con Kotlin
        if (plugins.hasPlugin("org.jetbrains.kotlin.android")) {
            configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
                jvmToolchain(17)
            }
        }
    }

    // Configuración común para todos los subproyectos - TODOS los tipos de tareas Kotlin
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "17"
            freeCompilerArgs = freeCompilerArgs + listOf("-Xjvm-default=all")
        }
    }

    // También aplicar a tareas de compilación Java
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
        // NO usar options.release.set() en Android - causa conflicto con bootclasspath
    }
}

// Configuración de directorio de compilación personalizado
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // IMPORTANTE: Forzar versión de Kotlin en todos los subproyectos
    configurations.all {
        resolutionStrategy {
            force("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
            force("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-common:2.1.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.1.0")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.1.0")
        }
    }

    // FORZAR CONFIGURACIÓN JAVA 17 EN TODOS LOS SUBPROYECTOS
    afterEvaluate {
        // Para proyectos Android (aplicación)
        if (plugins.hasPlugin("com.android.application")) {
            configure<com.android.build.gradle.BaseExtension> {
                compileSdkVersion(36)
                
                defaultConfig {
                    minSdk = 24
                    targetSdk = 36
                    versionCode = 1
                    versionName = "1.0.0"
                    testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
                    vectorDrawables.useSupportLibrary = true
                }
                
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                    isCoreLibraryDesugaringEnabled = true
                }
                
                buildTypes {
                    getByName("release") {
                        isMinifyEnabled = true
                        proguardFiles(
                            getDefaultProguardFile("proguard-android-optimize.txt"),
                            "proguard-rules.pro"
                        )
                    }
                }
            }
        }

        // Para proyectos Android (biblioteca) - CRÍTICO para plugins
        if (plugins.hasPlugin("com.android.library")) {
            configure<com.android.build.gradle.LibraryExtension> {
                compileSdk = 36
                
                defaultConfig {
                    minSdk = 24
                    targetSdk = 36
                    testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
                }
                
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                    isCoreLibraryDesugaringEnabled = true
                }
            }
        }

        // Configuración Kotlin JVM toolchain
        if (plugins.hasPlugin("org.jetbrains.kotlin.android")) {
            configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
                jvmToolchain(17)
            }
        }
        
        // Forzar todas las tareas de compilación Kotlin
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "17"
                freeCompilerArgs = freeCompilerArgs + listOf("-Xjvm-default=all")
            }
        }
        
        // Forzar todas las tareas de compilación Java
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
            options.release.set(17)
        }
    }
}

// Configuración de dependencias entre subproyectos
subprojects {
    project.evaluationDependsOn(":app")
}

// Tarea de limpieza personalizada
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
    delete("$rootDir/build")
    delete("$rootDir/.gradle")
}