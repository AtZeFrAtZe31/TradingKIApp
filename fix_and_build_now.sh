#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
log(){ echo -e "\n[fix] $*"; }

# --- ENV ---
termux-setup-storage || true
export JAVA_HOME="$PREFIX/lib/jvm/openjdk-17"
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_SDK_ROOT="$HOME/android-sdk"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

# --- Basics ---
pkg update -y >/dev/null || true
pkg install -y openjdk-17 unzip wget curl git >/dev/null || true
command -v gradle >/dev/null 2>&1 || pkg install -y gradle

# --- SDK tools sicherstellen ---
mkdir -p "$ANDROID_SDK_ROOT"
if [ ! -x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
  log "Installiere cmdline-tools …"
  cd "$ANDROID_SDK_ROOT"
  rm -rf cmdline-tools
  mkdir -p cmdline-tools
  wget -q -O cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
  unzip -q cmdline-tools.zip -d cmdline-tools
  mkdir -p cmdline-tools/latest
  mv cmdline-tools/cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
  rm -f cmdline-tools.zip
fi
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

# --- SDK Pakete & Lizenzen (idempotent) ---
log "SDK-Komponenten & Lizenzen … (einmalig, kann dauern)"
yes | sdkmanager --sdk_root="$ANDROID_SDK_ROOT" "platform-tools" "platforms;android-34" "build-tools;34.0.0" >/dev/null
yes | sdkmanager --licenses >/dev/null

# --- Projekt NEU aufsetzen ---
APP="$HOME/TradingKIApp"
log "Projekt neu anlegen: $APP"
rm -rf "$APP"
mkdir -p "$APP/app/src/main/java/com/tradingki/app" "$APP/app/src/main/res/layout" "$APP/app/src/main/res/values" "$APP/app/src/main/assets"

cat > "$APP/settings.gradle" <<'EOF'
pluginManagement {
  repositories { google(); mavenCentral(); gradlePluginPortal(); maven { url 'https://jitpack.io' } }
}
dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  repositories { google(); mavenCentral(); maven { url 'https://jitpack.io' } }
}
rootProject.name = "TradingKIApp"
include ':app'
EOF

cat > "$APP/build.gradle" <<'EOF'
plugins { id 'com.android.application' version '8.2.2' apply false }
EOF

cat > "$APP/gradle.properties" <<'EOF'
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx1024m
EOF

cat > "$APP/app/build.gradle" <<'EOF'
plugins { id 'com.android.application' }

android {
  namespace 'com.tradingki.app'
  compileSdk 34

  defaultConfig {
    applicationId "com.tradingki.app"
    minSdk 24
    targetSdk 34
    versionCode 1
    versionName "1.0"
  }

  buildTypes {
    release {
      minifyEnabled false
      proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
  }

  compileOptions {
    sourceCompatibility JavaVersion.VERSION_17
    targetCompatibility JavaVersion.VERSION_17
  }
}

dependencies {
  implementation 'com.github.PhilJay:MPAndroidChart:v3.1.0'
  implementation 'org.tensorflow:tensorflow-lite:2.14.0'
  implementation 'org.tensorflow:tensorflow-lite-support:0.4.4'
  implementation 'org.tensorflow:tensorflow-lite-metadata:0.4.4'
  implementation 'androidx.appcompat:appcompat:1.6.1'
  implementation 'com.google.android.material:material:1.9.0'
}
EOF

cat > "$APP/app/src/main/AndroidManifest.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-permission android:name="android.permission.INTERNET"/>
  <application android:label="Trading KI Demo" android:allowBackup="true" android:supportsRtl="true">
    <activity android:name=".MainActivity" android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity>
  </application>
</manifest>
EOF

cat > "$APP/app/src/main/res/layout/activity_main.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
  android:orientation="vertical" android:padding="12dp"
  android:layout_width="match_parent" android:layout_height="match_parent">

  <LinearLayout
    android:layout_width="match_parent" android:layout_height="wrap_content"
    android:orientation="horizontal">

    <Spinner
      android:id="@+id/strategySpinner"
      android:layout_width="0dp"
      android:layout_height="wrap_content"
      android:layout_weight="1" />

    <ToggleButton
      android:id="@+id/modeToggle"
      android:textOn="LIVE"
      android:textOff="DEMO"
      android:layout_width="wrap_content"
      android:layout_height="wrap_content"
      android:checked="false" />
  </LinearLayout>

  <Button
    android:id="@+id/startBtn"
    android:text="Start"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:layout_marginTop="8dp"/>

  <com.github.mikephil.charting.charts.LineChart
    android:id="@+id/lineChart"
    android:layout_width="match_parent"
    android:layout_height="0dp"
    android:layout_weight="1"
    android:layout_marginTop="8dp"/>
</LinearLayout>
EOF

cat > "$APP/app/src/main/res/values/arrays.xml" <<'EOF'
<resources>
  <string-array name="strategies">
    <item>EMA</item>
    <item>RSI</item>
    <item>Bollinger</item>
    <item>Momentum</item>
    <item>KI (TFLite)</item>
  </string-array>
</resources>
EOF

cat > "$APP/app/src/main/assets/btc_demo.csv" <<'EOF'
ts,price
0,30000
1,30010
2,30008
3,30020
4,30015
5,30040
6,30035
7,30055
8,30030
9,30060
10,30050
11,30080
12,30070
13,30100
14,30090
15,30120
EOF
: > "$APP/app/src/main/assets/model.tflite"

cat > "$APP/app/src/main/java/com/tradingki/app/DataFeed.java" <<'EOF'
package com.tradingki.app;
import android.content.Context;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;
public class DataFeed {
  public static List<Float> loadDemoPrices(Context ctx) {
    List<Float> out = new ArrayList<>();
    try (BufferedReader br = new BufferedReader(new InputStreamReader(
        ctx.getAssets().open("btc_demo.csv")))) {
      String line; boolean first=true;
      while ((line = br.readLine()) != null) {
        if (first) { first=false; continue; }
        String[] parts = line.split(",");
        if (parts.length>=2) out.add(Float.parseFloat(parts[1]));
      }
    } catch (Exception e) { e.printStackTrace(); }
    return out;
  }
}
EOF

cat > "$APP/app/src/main/java/com/tradingki/app/Strategies.java" <<'EOF'
package com.tradingki.app;
import java.util.List;
public class Strategies {
  public static float emaSignal(List<Float> prices, int fast, int slow){
    if (prices.size()<slow) return 0f;
    float kf = 2f/(fast+1f), ks = 2f/(slow+1f);
    float emaF = prices.get(0), emaS = prices.get(0);
    for (float p: prices){ emaF = p*kf + emaF*(1-kf); emaS = p*ks + emaS*(1-ks); }
    return Math.signum(emaF-emaS);
  }
  public static float rsiSignal(List<Float> p, int period){
    if (p.size()<period+1) return 0f;
    float gain=0,loss=0;
    for(int i=p.size()-period;i<p.size();i++){
      float diff = p.get(i)-p.get(i-1);
      if (diff>0) gain+=diff; else loss-=diff;
    }
    if (loss==0) return 0f;
    float rs = (gain/period)/(loss/period);
    float rsi = 100f - (100f/(1f+rs));
    if (rsi<30) return 1f; if (rsi>70) return -1f; return 0f;
  }
  public static float bollSignal(List<Float> p, int period, float mult){
    if (p.size()<period) return 0f;
    int n=period;
    float mean=0f; for(int i=p.size()-n;i<p.size();i++) mean+=p.get(i); mean/=n;
    float var=0f; for(int i=p.size()-n;i<p.size();i++){ float d=p.get(i)-mean; var+=d*d; }
    float std=(float)Math.sqrt(var/n);
    float upper=mean+mult*std, lower=mean-mult*std;
    float last=p.get(p.size()-1);
    if (last>upper) return -1f;
    if (last<lower) return 1f;
    return 0f;
  }
  public static float momentumSignal(List<Float> p, int lookback){
    if (p.size()<=lookback) return 0f;
    float diff = p.get(p.size()-1)-p.get(p.size()-1-lookback);
    return Math.signum(diff);
  }
}
EOF

cat > "$APP/app/src/main/java/com/tradingki/app/TFLiteHelper.java" <<'EOF'
package com.tradingki.app;
import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.util.Log;
import org.tensorflow.lite.Interpreter;
import java.io.FileInputStream;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
public class TFLiteHelper {
  private Interpreter interpreter=null;
  public boolean init(Context ctx){
    try {
      AssetFileDescriptor afd = ctx.getAssets().openFd("model.tflite");
      if (afd.getLength() <= 0) { Log.w("TFLite","Empty model.tflite, skip"); return false; }
      FileInputStream fis = new FileInputStream(afd.getFileDescriptor());
      FileChannel fc = fis.getChannel();
      MappedByteBuffer model = fc.map(FileChannel.MapMode.READ_ONLY, afd.getStartOffset(), afd.getLength());
      interpreter = new Interpreter(model);
      return true;
    } catch (Exception e){
      Log.w("TFLite","No valid model.tflite found, skipping KI.");
      return false;
    }
  }
  public float predict(float x){
    if (interpreter==null) return 0f;
    float[][] in = new float[][]{{x}};
    float[][] out = new float[][]{{0f}};
    interpreter.run(in, out);
    return out[0][0];
  }
}
EOF

cat > "$APP/app/src/main/java/com/tradingki/app/MainActivity.java" <<'EOF'
package com.tradingki.app;
import android.os.Bundle;
import android.os.Handler;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.Spinner;
import android.widget.ToggleButton;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.github.mikephil.charting.charts.LineChart;
import com.github.mikephil.charting.data.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;
public class MainActivity extends AppCompatActivity {
  private LineChart chart;
  private final Handler handler = new Handler();
  private final List<Float> prices = new ArrayList<>();
  private boolean running=true; // Auto-Start
  private boolean live=false;
  private TFLiteHelper tfl = new TFLiteHelper();
  private Random rnd = new Random();
  private Spinner strat;
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);
    strat = findViewById(R.id.strategySpinner);
    ArrayAdapter<CharSequence> adapter = ArrayAdapter.createFromResource(this, R.array.strategies, android.R.layout.simple_spinner_item);
    adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
    strat.setAdapter(adapter);
    ToggleButton mode = findViewById(R.id.modeToggle);
    mode.setOnCheckedChangeListener((b, checked) -> live = checked);
    Button start = findViewById(R.id.startBtn);
    chart = findViewById(R.id.lineChart);
    boolean ki = tfl.init(this);
    if (!ki) Toast.makeText(this, "Ohne KI-Modell – Demo läuft.", Toast.LENGTH_SHORT).show();
    prices.clear();
    prices.addAll(DataFeed.loadDemoPrices(this));
    if (prices.isEmpty()) prices.add(30000f);
    start.setOnClickListener(v -> { running = !running; if (running) startLoop(); });
    renderChart();
    startLoop(); // Autostart
  }
  private void startLoop(){
    handler.post(new Runnable() {
      @Override public void run() {
        if (!running) return;
        float next = live ? tickLive() : tickDemo();
        prices.add(next);
        float signal = computeSignal(strat.getSelectedItemPosition());
        renderChartWithSignal(signal);
        handler.postDelayed(this, 800);
      }
    });
  }
  private float computeSignal(int idx){
    int N = Math.min(60, prices.size());
    List<Float> w = prices.subList(prices.size()-N, prices.size());
    switch (idx){
      case 0: return Strategies.emaSignal(w, 12, 26);
      case 1: return Strategies.rsiSignal(w, 14);
      case 2: return Strategies.bollSignal(w, 20, 2f);
      case 3: return Strategies.momentumSignal(w, 10);
      case 4: float x = w.get(w.size()-1); return Math.signum(tfl.predict(x));
      default: return 0f;
    }
  }
  private float tickDemo(){ float last = prices.get(prices.size()-1); float drift = (rnd.nextFloat()-0.5f) * 10f; return last + drift; }
  private float tickLive(){ float last = prices.get(prices.size()-1); float j = (rnd.nextFloat()-0.5f) * 15f; return last + j; }
  private void renderChart(){
    List<Entry> es = new ArrayList<>();
    for (int i=0;i<prices.size();i++) es.add(new Entry(i, prices.get(i)));
    LineDataSet ds = new LineDataSet(es, "BTC/USDT");
    chart.setData(new LineData(ds));
    chart.getDescription().setText("Signal: HOLD");
    chart.invalidate();
  }
  private void renderChartWithSignal(float signal){
    List<Entry> es = new ArrayList<>();
    for (int i=0;i<prices.size();i++) es.add(new Entry(i, prices.get(i)));
    LineDataSet ds = new LineDataSet(es, "BTC/USDT");
    String s = signal>0?"BUY":(signal<0?"SELL":"HOLD");
    LineData data = new LineData(ds);
    chart.setData(data);
    chart.getDescription().setText("Signal: "+s);
    chart.invalidate();
  }
}
EOF

# --- Gradle Wrapper 8.5 + Build ---
cd "$APP"
log "Gradle Wrapper 8.5 erzeugen …"
gradle wrapper --gradle-version 8.5
log "assembleDebug … (Erstlauf lädt Abhängigkeiten)"
./gradlew :app:assembleDebug

# --- APK ausliefern ---
APK_SRC="$APP/app/build/outputs/apk/debug/app-debug.apk"
APK_DST="$HOME/storage/shared/TradingKIApp.apk"
cp "$APK_SRC" "$APK_DST"
log "Fertig: $APK_DST – installiere per: termux-open \"$APK_DST\""
