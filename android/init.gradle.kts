allprojects {
    tasks.withType<JavaCompile>().configureEach {
        // Remove --release flag to prevent conflicts with Android Gradle Plugin
        options.compilerArgs.removeAll { it.startsWith("--release") }
        
        // Ensure Java 17 compatibility
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
        
        // Enable forking to use the correct Java home
        options.isFork = true
        options.forkOptions.javaHome = File(System.getProperty("java.home"))
    }
    
    // Ensure Kotlin compilation uses Java 17
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = JavaVersion.VERSION_17.toString()
            freeCompilerArgs = freeCompilerArgs + "-Xjvm-default=all"
        }
    }
}
