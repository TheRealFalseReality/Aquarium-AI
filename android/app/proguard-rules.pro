# Flutter Local Notifications ProGuard rules
# CRITICAL: These rules prevent "Missing type parameter" crash in background notifications
# 
# Issue: flutter_local_notifications v18.x uses GSON for serialization. When R8/ProGuard
# strips generic type information, scheduled notifications crash with "Missing type parameter"
# when fired in the background.
#
# Solution: Keep GSON type information and generic signatures
# Reference: https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/example/android/app/proguard-rules.pro
#
# IMPORTANT: These rules are REQUIRED for flutter_local_notifications v18.x
# NOTE: Version 19.0.0+ includes these rules automatically - consider upgrading when ready
#
# Flutter core classes are already handled by Flutter's default ProGuard configuration
# so we only need to keep the GSON-specific rules below

## Gson rules
# Gson uses generic type information stored in a class file when working with fields.
# Proguard removes such information by default, so configure it to keep all of it.
-keepattributes Signature

# For using GSON @Expose annotation
-keepattributes *Annotation*

# Keep additional attributes that may be needed
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Gson specific classes
-dontwarn sun.misc.**

# Prevent proguard from stripping interface information from TypeAdapter, TypeAdapterFactory,
# JsonSerializer, JsonDeserializer instances (so they can be used in @JsonAdapter)
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Prevent R8 from leaving Data object members always null
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Retain generic signatures of TypeToken and its subclasses with R8 version 3.0 and higher.
# This is critical to prevent "Missing type parameter" crashes
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# Keep line numbers and source file names for better crash reports
-keepattributes SourceFile,LineNumberTable
