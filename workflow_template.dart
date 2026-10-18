/// The GitHub Actions workflow that the app pushes to
/// .github/workflows/build.yml in your repo before every build.
///
/// - Creates the android/ and web/ folders (flutter create) around the
///   generated lib/ and pubspec.yaml.
/// - Sets the app name, INTERNET permission, extra permissions and icon.
/// - Creates ONE signing key per app the first time (keys/appN.jks) and
///   reuses it afterwards, so every new APK installs over the old one.
const buildWorkflowYaml = r'''
name: build

on:
  workflow_dispatch:
    inputs:
      app:
        description: "app folder"
        required: true
      label:
        description: "app name"
        required: true
      mode:
        description: "apk or web"
        required: true
        default: apk

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 40
    env:
      APP: ${{ inputs.app }}
      LABEL: ${{ inputs.label }}
      MODE: ${{ inputs.mode }}
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "17"

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Create platform folders
        working-directory: apps/${{ inputs.app }}
        run: |
          set -e
          rm -rf /tmp/bak && mkdir -p /tmp/bak
          cp -r lib /tmp/bak/lib
          cp pubspec.yaml /tmp/bak/pubspec.yaml
          flutter create . --org com.myapps --project-name "$APP" --platforms=android,web
          rm -rf lib && cp -r /tmp/bak/lib lib
          cp /tmp/bak/pubspec.yaml pubspec.yaml
          flutter pub get

      - name: App name and permissions
        if: env.MODE == 'apk'
        working-directory: apps/${{ inputs.app }}
        run: |
          python3 - <<'PY'
          import os, re
          p = "android/app/src/main/AndroidManifest.xml"
          s = open(p, encoding="utf-8").read()
          label = os.environ["LABEL"].replace("&", "&amp;").replace('"', "&quot;").replace("<", "&lt;")
          s = re.sub(r'android:label="[^"]*"', 'android:label="' + label + '"', s, count=1)
          perms = ["android.permission.INTERNET"]
          if os.path.exists("android_permissions.txt"):
              for line in open("android_permissions.txt", encoding="utf-8"):
                  line = line.strip()
                  if re.fullmatch(r"android\.permission\.[A-Z_]+", line) and line not in perms:
                      perms.append(line)
          add = "".join('    <uses-permission android:name="%s"/>\n' % x for x in perms if x not in s)
          s = s.replace("<application", add + "    <application", 1)
          open(p, "w", encoding="utf-8").write(s)
          PY

      - name: Launcher icon
        if: env.MODE == 'apk'
        working-directory: apps/${{ inputs.app }}
        run: |
          if [ -f icon.png ]; then
            flutter pub add dev:flutter_launcher_icons
            printf '\nflutter_launcher_icons:\n  android: true\n  ios: false\n  image_path: "icon.png"\n' >> pubspec.yaml
            dart run flutter_launcher_icons
          fi

      - name: Fixed signing key for this app
        if: env.MODE == 'apk'
        run: |
          set -e
          mkdir -p keys
          KS="keys/${APP}.jks"
          if [ ! -f "$KS" ]; then
            PASS=$(openssl rand -hex 16)
            keytool -genkeypair -keystore "$KS" -alias upload -keyalg RSA -keysize 2048 -validity 10000 -storepass "$PASS" -keypass "$PASS" -dname "CN=${APP}, O=My apps, C=SD"
            echo "$PASS" > "keys/${APP}.pass"
            git config user.name "github-actions"
            git config user.email "actions@github.com"
            git add keys
            git commit -m "add signing key for ${APP}"
            git push
          fi
          PASS=$(cat "keys/${APP}.pass")
          cat > "apps/${APP}/android/key.properties" <<EOF
          storePassword=$PASS
          keyPassword=$PASS
          keyAlias=upload
          storeFile=$GITHUB_WORKSPACE/$KS
          EOF

      - name: Sign release builds with that key
        if: env.MODE == 'apk'
        working-directory: apps/${{ inputs.app }}/android/app
        run: |
          python3 - <<'PY'
          import os, re
          kts = os.path.exists("build.gradle.kts")
          p = "build.gradle.kts" if kts else "build.gradle"
          s = open(p, encoding="utf-8").read()
          if "keystoreProperties" not in s:
              if kts:
                  head = "import java.util.Properties\nimport java.io.FileInputStream\n\n"
                  load = 'val keystoreProperties = Properties()\nval keystorePropertiesFile = rootProject.file("key.properties")\nif (keystorePropertiesFile.exists()) {\n    keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n}\n\n'
                  signing = '    signingConfigs {\n        create("release") {\n            keyAlias = keystoreProperties["keyAlias"] as String\n            keyPassword = keystoreProperties["keyPassword"] as String\n            storeFile = file(keystoreProperties["storeFile"] as String)\n            storePassword = keystoreProperties["storePassword"] as String\n        }\n    }\n'
                  s = head + s
                  s = s.replace("android {", load + "android {\n" + signing, 1)
                  s = re.sub(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)', 'signingConfig = signingConfigs.getByName("release")', s)
                  ok = 'getByName("release")' in s
              else:
                  load = "def keystoreProperties = new Properties()\ndef keystorePropertiesFile = rootProject.file('key.properties')\nif (keystorePropertiesFile.exists()) {\n    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n}\n\n"
                  signing = "    signingConfigs {\n        release {\n            keyAlias keystoreProperties['keyAlias']\n            keyPassword keystoreProperties['keyPassword']\n            storeFile file(keystoreProperties['storeFile'])\n            storePassword keystoreProperties['storePassword']\n        }\n    }\n"
                  s = s.replace("android {", load + "android {\n" + signing, 1)
                  s = re.sub(r'signingConfig\s+signingConfigs\.debug', 'signingConfig signingConfigs.release', s)
                  ok = "signingConfigs.release" in s
              if not ok:
                  raise SystemExit("Could not patch the release signing config")
              open(p, "w", encoding="utf-8").write(s)
          PY

      - name: Build APK
        if: env.MODE == 'apk'
        working-directory: apps/${{ inputs.app }}
        run: |
          flutter build apk --release
          mkdir -p dist
          cp build/app/outputs/flutter-apk/app-release.apk dist/app.apk

      - name: Build web preview
        if: env.MODE == 'web'
        working-directory: apps/${{ inputs.app }}
        run: flutter build web --release

      - name: Upload APK
        if: env.MODE == 'apk'
        uses: actions/upload-artifact@v4
        with:
          name: apk-${{ inputs.app }}
          path: apps/${{ inputs.app }}/dist/app.apk
          retention-days: 7

      - name: Upload web preview
        if: env.MODE == 'web'
        uses: actions/upload-artifact@v4
        with:
          name: web-${{ inputs.app }}
          path: apps/${{ inputs.app }}/build/web
          retention-days: 3
''';
