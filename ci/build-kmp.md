# CI Build KMP — titipo-app-kmp

Pin: Kotlin 2.2.20, Compose 1.8.2, Navigation3 1.0.0, JDK 17, Gradle 8.10.

## Langkah

```bash
# Validasi pin sama standar
grep -E 'kotlin = "2.2.20"|compose = "1.8.2"|navigation3 = "1.0.0"' gradle/libs.versions.toml

# Android debug + lint
./gradlew :composeApp:assembleDebug --stacktrace

# Android rilis (butuh keystore di CI secret)
./gradlew :composeApp:bundleRelease

# iOS framework (runner macos)
./gradlew :composeApp:linkReleaseFrameworkIosArm64
```

Artefak: `*.apk`, `*.aab`, `*.xcframework` diunggah sebagai artefak CI 7 hari.
