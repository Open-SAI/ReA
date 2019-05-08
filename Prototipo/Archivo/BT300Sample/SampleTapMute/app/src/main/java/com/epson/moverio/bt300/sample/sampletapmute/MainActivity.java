/*
 * Copyright(C) Seiko Epson Corporation 2016. All rights reserved.
 *
 * Warranty Disclaimers.
 * You acknowledge and agree that the use of the software is at your own risk.
 * The software is provided "as is" and without any warranty of any kind.
 * Epson and its licensors do not and cannot warrant the performance or results
 * you may obtain by using the software.
 * Epson and its licensors make no warranties, express or implied, as to non-infringement,
 * merchantability or fitness for any particular purpose.
 */

package com.epson.moverio.bt300.sample.sampletapmute;

import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;

import com.epson.moverio.btcontrol.DisplayControl;

public class MainActivity extends AppCompatActivity implements SensorEventListener {

    private final int TAPPED = 2;

    private DisplayControl mDisplayControl;
    private SensorManager mSensorManager;

    private boolean mIsMute;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mIsMute = false;

        mDisplayControl = new DisplayControl(this);
    }

    @Override
    protected void onResume() {
        super.onResume();

        setMute(false);

        mSensorManager = (SensorManager) getSystemService(SENSOR_SERVICE);
        if (mSensorManager != null) {
            Sensor tap = mSensorManager.getDefaultSensor(Sensor.TYPE_HEADSET_TAP);
            mSensorManager.registerListener(this, tap, SensorManager.SENSOR_DELAY_UI);
        }
    }

    @Override
    protected void onPause() {
        super.onPause();

        setMute(false);

        if (mSensorManager != null) {
            mSensorManager.unregisterListener(this);
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        if (event.sensor.getType() == Sensor.TYPE_HEADSET_TAP) {
            if (event.values[0] == TAPPED) {
                if (mIsMute) {
                    // Mute ON -> OFF
                    setMute(false);
                } else {
                    // Mute OFF -> ON
                    setMute(true);
                }
            }
        }
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {

    }

    private void setMute(boolean isMute) {
        mIsMute = isMute;
        mDisplayControl.setMute(isMute);
    }
}
