allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Fix for plugin namespace issues with newer AGP
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            
            // Skip manifest processing for plugins that have package attribute instead of namespace
            if (project.name in listOf("isar_flutter_libs", "share_plus", "path_provider_android", "url_launcher_android")) {
                android.sourceSets {
                    getByName("main") {
                        manifest.srcFile(project.file("src/main/AndroidManifest.xml"))
                    }
                }
            }
            
            if (!project.hasProperty("namespace")) {
                android.namespace = "com.example.personal_news_brief"
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
