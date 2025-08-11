package com.tradingki.app;
import java.util.*;
public class Strategies {
  public static float emaSignal(List<Float> p,int f,int s){
    if(p.size()<s) return 0f; float kf=2f/(f+1f), ks=2f/(s+1f);
    float ef=p.get(0), es=p.get(0);
    for(float x:p){ ef=x*kf+ef*(1-kf); es=x*ks+es*(1-ks); }
    return Math.signum(ef-es);
  }
  public static float rsiSignal(List<Float> p,int n){
    if(p.size()<n+1) return 0f; float g=0,l=0;
    for(int i=p.size()-n;i<p.size();i++){ float d=p.get(i)-p.get(i-1); if(d>0) g+=d; else l-=d; }
    if(l==0) return 0f; float rs=(g/n)/(l/n); float r=100f-(100f/(1f+rs));
    if(r<30) return 1f; if(r>70) return -1f; return 0f;
  }
  public static float bollSignal(List<Float> p,int n,float m){
    if(p.size()<n) return 0f; float mean=0; for(int i=p.size()-n;i<p.size();i++) mean+=p.get(i); mean/=n;
    float var=0; for(int i=p.size()-n;i<p.size();i++){ float d=p.get(i)-mean; var+=d*d; }
    float std=(float)Math.sqrt(var/n); float up=mean+m*std, lo=mean-m*std; float last=p.get(p.size()-1);
    if(last>up) return -1f; if(last<lo) return 1f; return 0f;
  }
  public static float momentumSignal(List<Float> p,int lb){
    if(p.size()<=lb) return 0f; float d=p.get(p.size()-1)-p.get(p.size()-1-lb); return Math.signum(d);
  }
}
