plugins {
    // ✅ Plugin de Google Services — versión única y sincronizada
    id("com.google.gms.google-services") version "4.4.3" apply false

    // ✅ Plugin de Android y Kotlin con versiones modernas
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Redefine el directorio de build para mantener estructura limpia
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

// ✅ Aplica estructura modular para subproyectos
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// ✅ Tarea de limpieza global
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
