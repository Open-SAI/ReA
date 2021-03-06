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

package com.epson.moverio.bt300.sample.sampleheadsetgyro;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.TextView;
import android.view.View;
import android.view.View.OnClickListener;
import iocomms.subpos.*;

public class MainActivity extends AppCompatActivity implements SwingDetector.ISwingDetectListener {

    SubPos subpos;

    private SwingDetector mSwingDetector;

    private final int[] IMAGES = {
            R.drawable.image1,
            R.drawable.image2,
            R.drawable.image3,
    };

    private ImageView mImageView;
    private int mImageIndex;

    private TextView mTextViewX;
    private TextView mTextViewY;
    private TextView mTextViewZ;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mTextViewX = (TextView) findViewById(R.id.textViewGyroX);
        mTextViewY = (TextView) findViewById(R.id.textViewGyroY);
        mTextViewZ = (TextView) findViewById(R.id.textViewGyroZ);

        mImageView = (ImageView) findViewById(R.id.imageView);
        changeImage();

        mSwingDetector = new SwingDetector(this);

        View view = this.getWindow().getDecorView();
        view.setSystemUiVisibility(View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
                View.SYSTEM_UI_FLAG_FULLSCREEN |
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);

        //Create new SubPos service
        subpos = new SubPos(this); //"this" passes the context
        SubPosPosition position; //returns null if position is not calculated
        position = subpos.getPosition();

        //String newLine = System.getProperty("line.separator");
        StringBuilder output = new StringBuilder();
        output.append("\n" + "\n" + "*****************************");
        output.append("\n" + "Coords: ");
        output.append(position);
        output.append("\n" + "*****************************");
        System.out.println(output);
    }

    @Override
    protected void onResume() {
        super.onResume();
        mImageIndex = 0;

        if (mSwingDetector != null) {
            mSwingDetector.startSensor();
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (mSwingDetector != null) {
            mSwingDetector.stopSensor();
        }
    }

    @Override
    public void onSwing(int direction) {
        if (direction == SwingDetector.LEFT_SWING) {
            mImageIndex--;
            changeImage();
        } else if (direction == SwingDetector.RIGHT_SWING) {
            mImageIndex++;
            changeImage();
        } else {
            // do nothing
        }
    }

    @Override
    public void onChanged(float gx, float gy, float gz) {
        mTextViewX.setText(String.valueOf(gx));
        mTextViewY.setText(String.valueOf(gy));
        mTextViewZ.setText(String.valueOf(gz));
    }

    private void changeImage() {
        if (IMAGES.length <= mImageIndex) {
            mImageIndex = 0;
        } else if (mImageIndex < 0) {
            mImageIndex = IMAGES.length - 1;
        }

        mImageView.setImageResource(IMAGES[mImageIndex]);
    }
}

