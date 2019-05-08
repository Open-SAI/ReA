package com.example.ra.bt1;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;

import android.view.GestureDetector;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.View;
import android.app.ActionBar;
import android.app.ActionBar.Tab;

import android.app.Activity;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.widget.Toast;

//public class MainActivity extends AppCompatActivity {
public class MainActivity extends Activity implements SensorEventListener  {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        /*super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        View view = this.getWindow().getDecorView();
        view.setSystemUiVisibility(View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);

        ActionBar actionBar = getActionBar();*/

        //ActionBar actionBar = getSupportActionBar.setDisplayHomeAsEnabled(true);
        //assert actionBar != null;
        //actionBar.hide();
        //View decorView = getActivity().getWindow().getDecorView();
        //decorView.setSystemUiVisibility(0);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        SensorManager sm = (SensorManager)getSystemService(SENSOR_SERVICE);
        Sensor sensor = sm.getDefaultSensor(Sensor.TYPE_HEADSET_TAP);
        sm.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL);
    }
    @Override
    public void onSensorChanged(SensorEvent event) {
        if (event.sensor.getType() == Sensor.TYPE_HEADSET_TAP) {
            //if tap event occurs, show Toast
            Toast.makeText(this, "tap event!", Toast.LENGTH_SHORT).show();
        }
    }
        @Override
        protected void onPause() {
            super.onPause();
            SensorManager sm = (SensorManager)getSystemService(SENSOR_SERVICE);
            if (sm != null) {
                sm.unregisterListener(this);
            }
        }
        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy) {
        }
}
