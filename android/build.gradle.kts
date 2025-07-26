
buildscript {
    repositories { // <--- THIS `repositories` BLOCK MUST BE HERE
        google()
        mavenCentral()
    }
    dependencies {
        // This is the correct way to declare the google-services plugin:
        classpath("com.google.gms:google-services:4.3.15")
        // You'll also likely have the Android Gradle Plugin here, e.g.:
        // classpath("com.android.tools.build:gradle:8.3.0")
    }
}
allprojects {
    repositories {
        google()
        mavenCentral()
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



