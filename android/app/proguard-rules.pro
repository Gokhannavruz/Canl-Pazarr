# Flutter için gerekli kurallar
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase için gerekli kurallar
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Play Core için gerekli kurallar
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Kotlin için gerekli kurallar
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# URL Launcher için
-keep class androidx.browser.** { *; }

# Genel optimizasyon kuralları
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Hayvan alım satımı uygulaması için özel kurallar
-keep class com.canlipazar.** { *; }
-keep class * implements androidx.lifecycle.LifecycleObserver { *; } 