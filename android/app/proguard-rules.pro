# Flutter Local Notifications ProGuard rules
# Required to prevent "Missing type parameter" crash when using zonedSchedule

# Keep Flutter Local Notifications plugin classes and all their members
-keep class com.dexterous.** { *; }
-keep interface com.dexterous.** { *; }

# Keep notification receivers - critical for background notifications
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }

# Keep Gson TypeToken - required for reflection used by flutter_local_notifications
# This is critical to prevent "Missing type parameter" errors
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keepclassmembers class * extends com.google.gson.reflect.TypeToken {
    <fields>;
    <methods>;
}

# Keep generic signatures and type parameters - essential for generics to work at runtime
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Prevent Gson from being stripped
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep all Gson-related generic type information
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Parcelable implementations - used for notification data passing
-keep class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep Serializable classes for notification payloads
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
