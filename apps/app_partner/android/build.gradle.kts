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

// Fix #406: AGP 8+ requires namespace for all Android library projects.
// Third-party plugins (e.g. iamport_flutter) may not set it — read from AndroidManifest.xml.
subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        if (android.namespace.isNullOrEmpty()) {
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val parsedManifest = groovy.xml.XmlParser().parse(manifestFile)
                val packageName = parsedManifest.attribute("package")?.toString()
                if (!packageName.isNullOrEmpty()) {
                    android.namespace = packageName
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
