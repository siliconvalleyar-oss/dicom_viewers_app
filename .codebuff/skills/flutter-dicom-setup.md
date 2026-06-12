# Flutter DICOM Project Setup

## Dependencies
```yaml
dependencies:
  dicom_parser: ^0.0.15    # Parse DICOM files
  file_picker: ^11.0.2     # Pick .dcm files
  provider: ^6.1.2         # State management
  http: ^1.3.0             # Orthanc HTTP API
  shared_preferences: ^2.3.5  # Persist server config
  share_plus: ^10.1.4      # Share logs
```

## Android Configuration

### AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<application
    android:usesCleartextTraffic="true"
    ...>
```

- `INTERNET` permission needed in MAIN manifest (not just debug/profile)
- `usesCleartextTraffic="true"` required for HTTP (non-HTTPS) on Android 9+
- Orthanc uses HTTP by default, so cleartext is necessary

### Release Signing
```bash
keytool -genkey -v -keystore release-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias release -storepass <pass> -keypass <pass>
```

File `android/key.properties`:
```
storePassword=<pass>
keyPassword=<pass>
keyAlias=release
storeFile=../../release-keystore.jks
```

In `android/app/build.gradle.kts`:
```kotlin
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val keystorePresent = keystorePropertiesFile.exists()
if (keystorePresent) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    ...
    if (keystorePresent) {
        signingConfigs {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
    buildTypes {
        release {
            signingConfig = if (keystorePresent) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}
```

### .gitignore
Essential entries for Flutter + Android:
```
*.jks
android/key.properties
build/
.dart_tool/
.idea/
*.iml
```

## Emulator Setup
For Android emulator, use `10.0.2.2` to reach host machine's localhost.
