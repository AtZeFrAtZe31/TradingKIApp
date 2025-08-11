#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
say(){ echo -e "\n[$(date +%H:%M:%S)] $*"; }

# --- Auto-Java + SDK PATH ---
termux-setup-storage || true
if command -v java >/dev/null 2>&1; then JP="$(readlink -f "$(command -v java)")"; export JAVA_HOME="$(dirname "$(dirname "$JP")")"; export PATH="$JAVA_HOME/bin:$PATH"; fi
export ANDROID_SDK_ROOT="$HOME/android-sdk"; export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

say "[1/8] Pakete & Tools"
pkg update -y || true
pkg install -y openjdk-17 unzip wget curl git || true
command -v gradle >/dev/null 2>&1 || pkg install -y gradle || true
[ -d "$PREFIX/lib/jvm/openjdk-17" ] && export JAVA_HOME="$PREFIX/lib/jvm/openjdk-17" && export PATH="$JAVA_HOME/bin:$PATH"
java -version >/dev/null

say "[2/8] Android cmdline-tools"
mkdir -p "$ANDROID_SDK_ROOT"
if [ ! -x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
  cd "$ANDROID_SDK_ROOT"; rm -rf cmdline-tools; mkdir -p cmdline-tools
  wget -q -O cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
  unzip -q cmdline-tools.zip -d cmdline-tools; mkdir -p cmdline-tools/latest
  mv cmdline-tools/cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
  rm -f cmdline-tools.zip
fi
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

say "[3/8] SDK Pakete + Lizenzen (kann dauern)"
yes | sdkmanager --sdk_root="$ANDROID_SDK_ROOT" "platform-tools" "platforms;android-34" "build-tools;34.0.0" >/dev/null
yes | sdkmanager --licenses >/dev/null

APP="$HOME/TradingKIApp"
say "[4/8] Projekt PRO neu aufsetzen"
rm -rf "$APP"; mkdir -p "$APP/app/src/main/java/com/tradingki/app" "$APP/app/src/main/res/layout" "$APP/app/src/main/res/values" "$APP/app/src/main/assets" "$APP/app/src/main/res/values-night"
cat > "$APP/settings.gradle" <<'EOG'
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal(); maven { url 'https://jitpack.io' } } }
dependencyResolutionManagement { repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS); repositories { google(); mavenCentral(); maven { url 'https://jitpack.io' } } }
rootProject.name="TradingKIApp"; include(":app")
EOG
cat > "$APP/build.gradle" <<'EOG'
plugins { id 'com.android.application' version '8.2.2' apply false }
EOG
cat > "$APP/gradle.properties" <<'EOG'
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx1024m
EOG
cat > "$APP/app/build.gradle" <<'EOG'
plugins { id 'com.android.application' }
android {
  namespace 'com.tradingki.app'; compileSdk 34
  defaultConfig { applicationId "com.tradingki.app"; minSdk 24; targetSdk 34; versionCode 1; versionName "1.0" }
  buildTypes { release { minifyEnabled false; proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro' } }
  compileOptions { sourceCompatibility JavaVersion.VERSION_17; targetCompatibility JavaVersion.VERSION_17 }
}
dependencies {
  implementation 'com.github.PhilJay:MPAndroidChart:v3.1.0'
  implementation 'androidx.appcompat:appcompat:1.6.1'
  implementation 'com.google.android.material:material:1.11.0'
  implementation 'org.tensorflow:tensorflow-lite:2.14.0'
  implementation 'org.tensorflow:tensorflow-lite-support:0.4.4'
  implementation 'org.tensorflow:tensorflow-lite-metadata:0.4.4'
}
EOG
cat > "$APP/app/src/main/AndroidManifest.xml" <<'EOG'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-permission android:name="android.permission.INTERNET"/>
  <application android:label="Trading KI Pro" android:theme="@style/Theme.TradingKI" android:allowBackup="true" android:supportsRtl="true">
    <activity android:name=".MainActivity" android:exported="true">
      <intent-filter><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.LAUNCHER"/></intent-filter>
    </activity>
  </application>
</manifest>
EOG
cat > "$APP/app/src/main/res/values/styles.xml" <<'EOG'
<resources><style name="Theme.TradingKI" parent="Theme.Material3.DayNight.NoActionBar"/></resources>
EOG
cat > "$APP/app/src/main/res/values/arrays.xml" <<'EOG'
<resources><string-array name="strategies"><item>EMA</item><item>RSI</item><item>Bollinger</item><item>Momentum</item><item>KI (TFLite)</item></string-array></resources>
EOG
cat > "$APP/app/src/main/res/layout/activity_main.xml" <<'EOG'
<androidx.coordinatorlayout.widget.CoordinatorLayout xmlns:android="http://schemas.android.com/apk/res/android"
  xmlns:app="http://schemas.android.com/apk/res-auto" android:layout_width="match_parent" android:layout_height="match_parent">
  <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="horizontal" android:padding="12dp">
    <Spinner android:id="@+id/strategySpinner" android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1"/>
    <ToggleButton android:id="@+id/modeToggle" android:textOn="LIVE" android:textOff="DEMO" android:layout_width="wrap_content" android:layout_height="wrap_content" android:checked="false"/>
  </LinearLayout>
  <com.github.mikephil.charting.charts.LineChart android:id="@+id/lineChart" android:layout_width="match_parent" android:layout_height="match_parent" android:layout_marginTop="56dp"/>
  <com.google.android.material.floatingactionbutton.FloatingActionButton android:id="@+id/fabBuy" android:layout_width="wrap_content" android:layout_height="wrap_content" app:srcCompat="@android:drawable/ic_input_add" app:layout_anchor="@id/lineChart" app:layout_anchorGravity="bottom|start" android:layout_margin="16dp"/>
  <com.google.android.material.floatingactionbutton.FloatingActionButton android:id="@+id/fabSell" android:layout_width="wrap_content" android:layout_height="wrap_content" app:srcCompat="@android:drawable/ic_delete" app:layout_anchor="@id/lineChart" app:layout_anchorGravity="bottom|end" android:layout_margin="16dp"/>
</androidx.coordinatorlayout.widget.CoordinatorLayout>
EOG
cat > "$APP/app/src/main/assets/btc_demo.csv" <<'EOG'
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
EOG
: > "$APP/app/src/main/assets/model.tflite"
cat > "$APP/app/src/main/java/com/tradingki/app/DataFeed.java" <<'EOG'
package com.tradingki.app; import android.content.Context; import java.io.*; import java.util.*;
public class DataFeed { public static List<Float> loadDemoPrices(Context ctx){ List<Float> out=new ArrayList<>(); try(BufferedReader br=new BufferedReader(new InputStreamReader(ctx.getAssets().open("btc_demo.csv")))){ String line; boolean first=true; while((line=br.readLine())!=null){ if(first){first=false; continue;} String[] parts=line.split(","); if(parts.length>=2) out.add(Float.parseFloat(parts[1])); } } catch(Exception e){ e.printStackTrace(); } return out; } }
EOG
cat > "$APP/app/src/main/java/com/tradingki/app/Strategies.java" <<'EOG'
package com.tradingki.app; import java.util.*; public class Strategies {
  public static float emaSignal(List<Float> p,int f,int s){ if(p.size()<s) return 0f; float kf=2f/(f+1f), ks=2f/(s+1f); float ef=p.get(0), es=p.get(0); for(float x:p){ ef=x*kf+ef*(1-kf); es=x*ks+es*(1-ks);} return Math.signum(ef-es); }
  public static float rsiSignal(List<Float> p,int n){ if(p.size()<n+1) return 0f; float g=0,l=0; for(int i=p.size()-n;i<p.size();i++){ float d=p.get(i)-p.get(i-1); if(d>0) g+=d; else l-=d; } if(l==0) return 0f; float rs=(g/n)/(l/n); float rsi=100f-(100f/(1f+rs)); if(rsi<30) return 1f; if(rsi>70) return -1f; return 0f; }
  public static float bollSignal(List<Float> p,int n,float m){ if(p.size()<n) return 0f; float mean=0; for(int i=p.size()-n;i<p.size();i++) mean+=p.get(i); mean/=n; float var=0; for(int i=p.size()-n;i<p.size();i++){ float d=p.get(i)-mean; var+=d*d; } float std=(float)Math.sqrt(var/n); float up=mean+m*std, lo=mean-m*std; float last=p.get(p.size()-1); if(last>up) return -1f; if(last<lo) return 1f; return 0f; }
  public static float momentumSignal(List<Float> p,int lb){ if(p.size()<=lb) return 0f; float d=p.get(p.size()-1)-p.get(p.size()-1-lb); return Math.signum(d); }
}
EOG
cat > "$APP/app/src/main/java/com/tradingki/app/TFLiteHelper.java" <<'EOG'
package com.tradingki.app; import android.content.*; import android.content.res.AssetFileDescriptor; import android.util.Log; import org.tensorflow.lite.Interpreter; import java.io.*; import java.nio.*; import java.nio.channels.FileChannel;
public class TFLiteHelper { private Interpreter interpreter=null;
  public boolean init(Context ctx){ try{ AssetFileDescriptor afd=ctx.getAssets().openFd("model.tflite"); if(afd.getLength()<=0){ Log.w("TFLite","Empty model.tflite, skip"); return false;} FileInputStream fis=new FileInputStream(afd.getFileDescriptor()); FileChannel fc=fis.getChannel(); MappedByteBuffer model=fc.map(FileChannel.MapMode.READ_ONLY, afd.getStartOffset(), afd.getLength()); interpreter=new Interpreter(model); return true; }catch(Exception e){ Log.w("TFLite","No valid model.tflite found, skipping KI."); return false; } }
  public float predict(float x){ if(interpreter==null) return 0f; float[][] in={{x}}; float[][] out={{0f}}; interpreter.run(in,out); return out[0][0]; }
}
EOG
cat > "$APP/app/src/main/java/com/tradingki/app/MainActivity.java" <<'EOG'
package com.tradingki.app;
import android.os.*; import android.view.View; import android.widget.*; import com.google.android.material.floatingactionbutton.FloatingActionButton; import com.google.android.material.snackbar.Snackbar;
import androidx.appcompat.app.AppCompatActivity; import com.github.mikephil.charting.charts.LineChart; import com.github.mikephil.charting.data.*; import java.util.*; 
public class MainActivity extends AppCompatActivity {
  private LineChart chart; private final Handler h=new Handler(); private final List<Float> px=new ArrayList<>(); private boolean run=true, live=false; private final TFLiteHelper tfl=new TFLiteHelper(); private final Random rnd=new Random(); private Spinner strat;
  @Override protected void onCreate(Bundle b){ super.onCreate(b); setContentView(R.layout.activity_main);
    strat=findViewById(R.id.strategySpinner);
    ArrayAdapter<CharSequence> ad=ArrayAdapter.createFromResource(this,R.array.strategies,android.R.layout.simple_spinner_item); ad.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item); strat.setAdapter(ad);
    ToggleButton mode=findViewById(R.id.modeToggle); mode.setOnCheckedChangeListener((btn,chk)-> live=chk);
    FloatingActionButton buy=findViewById(R.id.fabBuy), sell=findViewById(R.id.fabSell); View root=findViewById(android.R.id.content);
    buy.setOnClickListener(v-> Snackbar.make(root,"BUY (Demo)",Snackbar.LENGTH_SHORT).show());
    sell.setOnClickListener(v-> Snackbar.make(root,"SELL (Demo)",Snackbar.LENGTH_SHORT).show());
    chart=findViewById(R.id.lineChart);
    boolean ki=tfl.init(this);
    px.clear(); px.addAll(DataFeed.loadDemoPrices(this)); if(px.isEmpty()) px.add(30000f);
    render(); loop(root,ki);
  }
  private void loop(View root, boolean ki){ h.post(new Runnable(){ @Override public void run(){ if(!run) return; float next= live? tickLive(): tickDemo(); px.add(next); float s=signal(strat.getSelectedItemPosition(),ki); renderSignal(s); h.postDelayed(this,800); } }); }
  private float signal(int i, boolean ki){ int N=Math.min(60,px.size()); List<Float> w=px.subList(px.size()-N,px.size());
    switch(i){ case 0: return Strategies.emaSignal(w,12,26); case 1: return Strategies.rsiSignal(w,14); case 2: return Strategies.bollSignal(w,20,2f); case 3: return Strategies.momentumSignal(w,10); case 4: float x=w.get(w.size()-1); return Math.signum(ki? tfl.predict(x):0f); default: return 0f; } }
  private float tickDemo(){ float last=px.get(px.size()-1); return last + (rnd.nextFloat()-0.5f)*10f; }
  private float tickLive(){ float last=px.get(px.size()-1); return last + (rnd.nextFloat()-0.5f)*15f; }
  private void render(){ List<Entry> es=new ArrayList<>(); for(int i=0;i<px.size();i++) es.add(new Entry(i,px.get(i))); LineDataSet ds=new LineDataSet(es,"BTC/USDT"); chart.setData(new LineData(ds)); chart.getDescription().setText("Signal: HOLD"); chart.invalidate(); }
  private void renderSignal(float s){ List<Entry> es=new ArrayList<>(); for(int i=0;i<px.size();i++) es.add(new Entry(i,px.get(i))); LineDataSet ds=new LineDataSet(es,"BTC/USDT"); String tx=s>0?"BUY":(s<0?"SELL":"HOLD"); chart.setData(new LineData(ds)); chart.getDescription().setText("Signal: "+tx); chart.invalidate(); }
}
EOG

say "[5/8] Gradle Wrapper 8.5"
cd "$APP"; gradle wrapper --gradle-version 8.5

say "[6/8] Build (assembleDebug)"
./gradlew :app:assembleDebug

say "[7/8] APK ausliefern"
APK_SRC="$APP/app/build/outputs/apk/debug/app-debug.apk"; APK_DST="$HOME/storage/shared/TradingKIApp.apk"
cp "$APK_SRC" "$APK_DST"

say "[8/8] Fertig! APK: $APK_DST"
echo "Installiere: termux-open \"$APK_DST\""
