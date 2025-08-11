#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
say(){ echo -e "\n[$(date +%H:%M:%S)] $*"; }

termux-setup-storage || true

# Auto-Java & SDK PATH
if command -v java >/dev/null 2>&1; then JP="$(readlink -f "$(command -v java)")"; export JAVA_HOME="$(dirname "$(dirname "$JP")")"; export PATH="$JAVA_HOME/bin:$PATH"; fi
export ANDROID_SDK_ROOT="$HOME/android-sdk"; export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

# Tools
say "[1/6] Pakete & Tools"
pkg update -y || true; pkg install -y openjdk-17 unzip wget curl git gradle || true
java -version >/dev/null

# Android cmdline-tools
say "[2/6] cmdline-tools"
mkdir -p "$ANDROID_SDK_ROOT"
if [ ! -x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
  cd "$ANDROID_SDK_ROOT"; rm -rf cmdline-tools; mkdir -p cmdline-tools
  wget -q -O ct.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
  unzip -q ct.zip -d cmdline-tools; mkdir -p cmdline-tools/latest
  mv cmdline-tools/cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
  rm -f ct.zip
fi
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

# SDK Pakete & Lizenzen
say "[3/6] SDK Pakete"
yes | sdkmanager --sdk_root="$ANDROID_SDK_ROOT" "platform-tools" "platforms;android-34" "build-tools;34.0.0" >/dev/null
yes | sdkmanager --licenses >/dev/null

# Gradle tunen (RAM & Encoding)
say "[4/6] Gradle Settings"
mkdir -p ~/.gradle
cat > ~/.gradle/gradle.properties <<'EOG'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
EOG

# Manifest fixen (android:exported)
MAN="app/src/main/AndroidManifest.xml"
if grep -q "<activity" "$MAN" && ! grep -q 'android:exported=' "$MAN"; then
  sed -i '0,/<activity /s//<activity android:exported="true" /' "$MAN"
fi

# Wrapper & Build
say "[5/6] Build"
gradle wrapper --gradle-version 8.5
./gradlew :app:assembleDebug --no-daemon --stacktrace

# APK liefern & installieren
say "[6/6] APK ausliefern"
APK="app/build/outputs/apk/debug/app-debug.apk"
DST="$HOME/storage/shared/TradingKIApp.apk"
cp "$APK" "$DST"
echo "✅ APK: $DST"
termux-open "$DST" || true
