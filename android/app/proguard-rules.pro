# Flutter specific ProGuard rules

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Bluetooth printing classes
-keep class id.manava.pencetprint.** { *; }

# Suppress warnings
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.play.core.splitcompat.**
