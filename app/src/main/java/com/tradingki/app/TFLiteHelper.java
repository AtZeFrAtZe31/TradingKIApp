package com.tradingki.app;
import android.content.*; import android.content.res.AssetFileDescriptor; import android.util.Log;
import org.tensorflow.lite.Interpreter; import java.io.*; import java.nio.*; import java.nio.channels.FileChannel;
public class TFLiteHelper {
  private Interpreter interpreter=null;
  public boolean init(Context ctx){
    try{
      AssetFileDescriptor afd=ctx.getAssets().openFd("model.tflite");
      if(afd.getLength()<=0){ Log.w("TFLite","Empty model.tflite, skip"); return false; }
      FileInputStream fis=new FileInputStream(afd.getFileDescriptor());
      FileChannel fc=fis.getChannel();
      MappedByteBuffer model=fc.map(FileChannel.MapMode.READ_ONLY, afd.getStartOffset(), afd.getLength());
      interpreter=new Interpreter(model); return true;
    }catch(Exception e){ Log.w("TFLite","No valid model.tflite found, skipping KI."); return false; }
  }
  public float predict(float x){
    if(interpreter==null) return 0f; float[][] in={{x}}; float[][] out={{0f}}; interpreter.run(in,out); return out[0][0];
  }
}
