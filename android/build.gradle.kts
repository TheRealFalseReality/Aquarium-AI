allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirect root build directory to the project-level 'build' folder
val rootBuildDir = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.value(rootBuildDir)

// Get the drive letter of the project (e.g., "D")
val projectDrive = rootProject.projectDir.absolutePath.split(":")[0].uppercase()

subprojects {
    // Get the drive letter of the subproject/plugin
    val subprojectDrive = project.projectDir.absolutePath.split(":")[0].uppercase()
    
    // Only redirect build directory if it's on the same drive to avoid "different roots" error
    // for plugins located in the Pub cache on a different drive (e.g., C:).
    if (subprojectDrive == projectDrive) {
        project.layout.buildDirectory.value(rootBuildDir.dir(project.name))
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}