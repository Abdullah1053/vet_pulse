# Flutter Wrapper & Engine Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Fix R8 Missing Google Play Core / SplitInstall Classes (Optional Deferred Components)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
-dontwarn com.google.android.play.core.**

# Keep flutter_local_notifications & GSON models
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep SQLite / sqflite native bindings
-keep class com.tekartik.sqflite.** { *; }

# Keep Device Info Plus
-keep class dev.fluttercommunity.plus.device_info.** { *; }

# Desugaring & Java 8+ APIs
-dontwarn java.lang.invoke.**
-dontwarn java.time.**

# Prevent obfuscation of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Prevent stripping of annotations and generic signatures
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod