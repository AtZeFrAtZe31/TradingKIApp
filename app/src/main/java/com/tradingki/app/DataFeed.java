package com.tradingki.app;
import android.content.Context; import java.io.*; import java.util.*;
public class DataFeed {
  public static List<Float> loadDemoPrices(Context ctx){
    List<Float> out=new ArrayList<>();
    try(BufferedReader br=new BufferedReader(new InputStreamReader(ctx.getAssets().open("btc_demo.csv")))){
      String line; boolean first=true;
      while((line=br.readLine())!=null){
        if(first){first=false; continue;}
        String[] parts=line.split(",");
        if(parts.length>=2) out.add(Float.parseFloat(parts[1]));
      }
    }catch(Exception e){ e.printStackTrace(); }
    return out;
  }
}
