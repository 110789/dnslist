# Flutter default rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter embedding
-keep class io.flutter.embedding.** { *; }

# Keep driver classes
-keep class org.lioisme.dnslist.drivers.** { *; }

# Dio rules
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Provider rules
-keep class provider.** { *; }

# GoRouter rules
-keep class go_router.** { *; }
-keep class go.** { *; }

# Google Play Core (for deferred components)
-dontwarn com.google.android.play.**
-keep class com.google.android.play.** { *; }