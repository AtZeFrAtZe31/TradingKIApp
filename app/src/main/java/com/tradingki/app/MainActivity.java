package com.tradingki.app;
import android.os.*; import android.view.View; import android.widget.*; 
import androidx.appcompat.app.AppCompatActivity; 
import com.google.android.material.floatingactionbutton.FloatingActionButton; import com.google.android.material.snackbar.Snackbar;
import com.github.mikephil.charting.charts.LineChart; import com.github.mikephil.charting.data.*;
import java.util.*; 
public class MainActivity extends AppCompatActivity {
  private LineChart chart; private final Handler h=new Handler(); private final List<Float> px=new ArrayList<>();
  private boolean run=true, live=false; private final TFLiteHelper tfl=new TFLiteHelper(); private final Random rnd=new Random(); private Spinner strat;
  @Override protected void onCreate(Bundle b){
    super.onCreate(b); setContentView(R.layout.activity_main);
    strat=findViewById(R.id.strategySpinner);
    ArrayAdapter<CharSequence> ad=ArrayAdapter.createFromResource(this,R.array.strategies,android.R.layout.simple_spinner_item);
    ad.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item); strat.setAdapter(ad);
    ToggleButton mode=findViewById(R.id.modeToggle); mode.setOnCheckedChangeListener((btn,chk)-> live=chk);
    FloatingActionButton buy=findViewById(R.id.fabBuy), sell=findViewById(R.id.fabSell); View root=findViewById(android.R.id.content);
    buy.setOnClickListener(v-> Snackbar.make(root,"BUY (Demo)",Snackbar.LENGTH_SHORT).show());
    sell.setOnClickListener(v-> Snackbar.make(root,"SELL (Demo)",Snackbar.LENGTH_SHORT).show());
    chart=findViewById(R.id.lineChart);
    boolean ki=tfl.init(this);
    px.clear(); px.addAll(DataFeed.loadDemoPrices(this)); if(px.isEmpty()) px.add(30000f);
    render(); loop(ki);
  }
  private void loop(boolean ki){ h.post(new Runnable(){ @Override public void run(){ if(!run) return; float next= live? tickLive(): tickDemo(); px.add(next); float s=signal(strat.getSelectedItemPosition(),ki); renderSignal(s); h.postDelayed(this,800); } }); }
  private float signal(int i, boolean kiReady){
    int N=Math.min(60,px.size()); List<Float> w=px.subList(px.size()-N,px.size());
    switch(i){ case 0: return Strategies.emaSignal(w,12,26); case 1: return Strategies.rsiSignal(w,14);
      case 2: return Strategies.bollSignal(w,20,2f); case 3: return Strategies.momentumSignal(w,10);
      case 4: float x=w.get(w.size()-1); return Math.signum(kiReady? tfl.predict(x):0f); default: return 0f; }
  }
  private float tickDemo(){ float last=px.get(px.size()-1); return last + (rnd.nextFloat()-0.5f)*10f; }
  private float tickLive(){ float last=px.get(px.size()-1); return last + (rnd.nextFloat()-0.5f)*15f; }
  private void render(){ List<Entry> es=new ArrayList<>(); for(int i=0;i<px.size();i++) es.add(new Entry(i,px.get(i))); LineDataSet ds=new LineDataSet(es,"BTC/USDT"); chart.setData(new LineData(ds)); chart.getDescription().setText("Signal: HOLD"); chart.invalidate(); }
  private void renderSignal(float s){ List<Entry> es=new ArrayList<>(); for(int i=0;i<px.size();i++) es.add(new Entry(i,px.get(i))); LineDataSet ds=new LineDataSet(es,"BTC/USDT"); String tx=s>0?"BUY":(s<0?"SELL":"HOLD"); chart.setData(new LineData(ds)); chart.getDescription().setText("Signal: "+tx); chart.invalidate(); }
}
