import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

keystoreProperties.load(FileInputStream(keystorePropertiesFile)) // ligne 13

android {
    namespace = "com.wallet.dz.ecom"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.wallet.dz.ecom"
        multiDexEnabled = true
        minSdk = 23//flutter.minSdkVersion
        targetSdk = 35//flutter.targetSdkVersion
        versionCode = 1//flutter.versionCode
        versionName = "1.0.0"//flutter.versionName
    }
    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
dependencies {
    // Add the desugaring dependency
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation ("com.android.support:multidex:1.0.3")
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.8.0"))
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.core:core:1.12.0")
//    implementation 'com.google.android.gms:play-services-ads:23.6.0'
//    implementation 'org.bouncycastle:bcprov-jdk18on:1.78.1'
    // TODO: Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
//    implementation("com.google.firebase:firebase-analytics")
//    implementation "org.jetbrains.kotlin:kotlin-stdlib:$kotlin_version"
//    implementation 'androidx.core:core-ktx:1.15.0'
//    implementation 'androidx.appcompat:appcompat:1.7.0'
//    implementation 'com.google.android.material:material:1.12.0'
//    implementation 'androidx.constraintlayout:constraintlayout:2.2.0'
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // Dépendances Firebase
    implementation("com.google.firebase:firebase-analytics") // Analytics (optionnel)
    implementation("com.google.firebase:firebase-firestore") // Firestore (si utilisé)
    implementation("com.google.firebase:firebase-auth") // Authentication (si utilisé)
    implementation("com.google.firebase:firebase-storage") // Storage (si u
//    implementation("com.google.android.gms:play-services-ads:23.1.0") {
//        exclude group: 'org.bouncycastle', module: 'bcprov-jdk18on'
//    }
//    implementation 'org.bouncycastle:bcprov-jdk18on:1.76'
//
//    implementation 'com.bytedance.ies.ugc.aweme:opensdk-china-external:0.1.9.6'
//    implementation 'com.bytedance.ies.ugc.aweme:opensdk-common:0.1.9.6'
    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries
//}
//dependencies {
//    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version")
//    implementation "androidx.core:core-ktx:1.15.0"
//    implementation(platform("com.google.firebase:firebase-bom:33.8.0"))
//    implementation("com.google.firebase:firebase-auth")
//    implementation("com.google.android.gms:play-services-base:18.5.0")
//    implementation("com.google.firebase:firebase-analytics")
//    implementation("androidx.multidex:multidex:2.0.1")
//    implementation("io.objectbox:objectbox-java:4.0.3")
//    implementation("io.objectbox:objectbox-android:4.0.3")
//    debugImplementation("io.objectbox:objectbox-android-objectbrowser:4.0.3")
}