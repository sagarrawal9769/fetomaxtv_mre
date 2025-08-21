package com.example.fetomaxtv_mre;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import android.content.ContentResolver;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.engine.FlutterEngine;
import android.util.Log;
import android.provider.Settings;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.doto.fetomax/print";
    private MethodChannel mChannel;


//    @Override
//    protected void onCreate(@Nullable Bundle savedInstanceState) {
//        super.onCreate(savedInstanceState);
//    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        mChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        mChannel.setMethodCallHandler((call, result) -> {

            Log.i("Method channel", "         in");

            switch (call.method) {
                /* ─────────── getAndroidID ─────────── */
                case "getAndroidID": {
                    String id = null;
                    try {
                        ContentResolver resolver = getApplicationContext().getContentResolver();
                        if (resolver != null) {
                            id = Settings.Secure.getString(resolver, Settings.Secure.ANDROID_ID);
                        }
                    } catch (Exception e) {
                        Log.e("getAndroidID MethodChannel", "Error reading ANDROID_ID", e);
                    }

                    if (id == null || id.isEmpty()) {
                        Log.w("getAndroidID MethodChannel", "ANDROID_ID unavailable");
                    } else {
                        // Don't log raw IDs in production — log a hash instead

                        Log.d("getAndroidID MethodChannel", "ANDROID_ID = " + id);
                    }

                    // Always respond to the Flutter side (null is OK)
                    result.success(id);
                    break;
                }

                default:
                    result.notImplemented();
            }

        });


    }


}
