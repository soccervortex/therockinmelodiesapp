-keep class io.flutter.** { *; }
-keep class com.rockinmelodies.app.** { *; }

# Flutter references Play Core for deferred components but we don't use them.
# Tell R8 to ignore the missing classes rather than fail.
-dontwarn com.google.android.play.core.**
