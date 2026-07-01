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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    project.plugins.withId("com.android.library") {
        val androidObj = extensions.findByName("android")
        if (androidObj != null) {
            try {
                val getNamespace = androidObj.javaClass.getMethod("getNamespace")
                val namespaceVal = getNamespace.invoke(androidObj)
                if (namespaceVal == null) {
                    val setNamespace = androidObj.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(androidObj, project.group.toString())
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
    }
}
