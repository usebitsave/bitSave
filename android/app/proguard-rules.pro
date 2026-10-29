# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Keep Pigeon generated classes
-keep class dev.flutter.pigeon.** { *; }
-keep class * implements io.flutter.plugin.common.Plugin { *; }

# Keep path_provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Suppress warnings from Google Play Core classes referenced by the Flutter Engine (deferred components)
-dontwarn com.google.android.play.core.**

