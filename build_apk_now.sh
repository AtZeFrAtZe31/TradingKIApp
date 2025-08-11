#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
step(){ echo -e "\n[fix] $*"; }

# 0) Env (Auto-Java + SDK PATH)
if command -v java >/dev/null 2>&1; then
  JP="$(readlink -f "$(command -v java)")"; export JAVA_HOME="$(dirname "$(dirname "$JP")")"
  export PATH="$JAVA_HOME/bin:$PATH"
fi
export ANDROID_SDK_ROOT="$HOME/android-sdk"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

# 1) Tools sicherstellen
step "Tools check"
pkg update -y || true
pkg install -y openjdk-17 unzip wget curl git gradle || true
java -version >/dev/null

# 2) cmdline-tools + SDK Pakete sicherstellen (idempotent)
step "SDK check"
mkdir -p "$ANDROID_SDK_ROOT"
if [ ! -x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
  cd "$ANDROID_SDK_ROOT"
  rm -rf cmdline-tools; mkdir -p cmdline-tools
  wget -q -O cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
  unzip -q cmdline-tools.zip -d cmdline-tools
  mkdir -p cmdline-tools/latest
  mv cmdline-tools/cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
  rm -f cmdline-tools.zip
fi
yes | sdkmanager --sdk_root="$ANDROID_SDK_ROOT" "platform-tools" "platforms;android-34" "build-tools;34.0.0" >/dev/null
yes | sdkmanager --licenses >/dev/null

# 3) Projekt prüfen
step "Projekt prüfen"
APP="$HOME/TradingKIApp"
[ -d "$APP/app" ] || { echo "[!] Projektordner fehlt. Erst 'build_tradingki_pro.sh' laufen lassen."; exit 1; }
cd "$APP"

# 4) Wrapper erzwingen (Gradle 8.5 kompatibel zu AGP 8.2.2)
step "Gradle Wrapper 8.5 erzeugen"
gradle wrapper --gradle-version 8.5

# 5) Build (Debug)
step "assembleDebug bauen"
./gradlew :app:assembleDebug --no-daemon

# 6) APK rauslegen
step "APK kopieren"
APK_SRC="$APP/app/build/outputs/apk/debug/app-debug.apk"
APK_DST="$HOME/storage/shared/TradingKIApp.apk"
cp "$APK_SRC" "$APK_DST"
echo "[✓] Fertig: $APK_DST"
