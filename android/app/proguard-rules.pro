# Flutter Local Notifications ProGuard rules
# Required to prevent "Missing type parameter" crash when using zonedSchedule

# Keep Flutter Local Notifications plugin classes and all members
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.** { *; }

# Prevent obfuscation of broadcast receivers
-keep class * extends android.content.BroadcastReceiver { *; }

# Keep Gson TypeToken - required for reflection used by flutter_local_notifications
# This is critical to prevent the "Missing type parameter" crash
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keepclassmembers class * extends com.google.gson.reflect.TypeToken {
    <init>(...);
    <fields>;
}

# Keep generic signatures and type parameters - crucial for Gson deserialization
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations

# Prevent Gson from being stripped or obfuscated
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter { *; }
-keep class * implements com.google.gson.TypeAdapterFactory { *; }
-keep class * implements com.google.gson.JsonSerializer { *; }
-keep class * implements com.google.gson.JsonDeserializer { *; }

# Keep classes with @SerializedName annotation
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Prevent R8 from removing or optimizing Gson-related code
-dontwarn com.google.gson.**
-dontnote com.google.gson.**
