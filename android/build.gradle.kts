allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Configure Java version for all projects
    plugins.withType<JavaBasePlugin>().configureEach {
        extensions.configure<JavaPluginExtension> {
            toolchain {
                // remove
                //languageVersion.set(JavaLanguageVersion.of(11))
            }
        }
    }
    
    // Configure Android projects
    plugins.withType<com.android.build.gradle.BasePlugin>().configureEach {
        extensions.configure<com.android.build.gradle.BaseExtension> {
            compileOptions {
                // remove
                //sourceCompatibility = JavaVersion.VERSION_11
                //targetCompatibility = JavaVersion.VERSION_11
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
