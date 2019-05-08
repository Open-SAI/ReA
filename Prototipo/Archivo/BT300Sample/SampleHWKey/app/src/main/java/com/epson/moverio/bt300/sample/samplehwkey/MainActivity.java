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

package com.epson.moverio.bt300.sample.samplehwkey;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.KeyEvent;
import android.widget.ImageView;

public class MainActivity extends AppCompatActivity {

    private final int[] IMAGES = {
            R.drawable.image1,
            R.drawable.image2,
            R.drawable.image3,
    };

    private ImageView mImageView;
    private int mImageIndex;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mImageView = (ImageView) findViewById(R.id.imageView);
    }

    @Override
    protected void onResume() {
        super.onResume();
        mImageIndex = 0;
        setImage(0);
    }

    @Override
    protected void onPause() {
        super.onPause();
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        if (event.getAction() == KeyEvent.ACTION_DOWN) {
            switch (event.getKeyCode()) {
                case KeyEvent.KEYCODE_DPAD_LEFT:
                    mImageIndex--;
                    changeImage();
                    break;
                case KeyEvent.KEYCODE_DPAD_RIGHT:
                    mImageIndex++;
                    changeImage();
                    break;
                default:
                    break;
            }
        }

        return super.dispatchKeyEvent(event);
    }

    private void changeImage() {
        if (IMAGES.length <= mImageIndex) {
            mImageIndex = 0;
        } else if (mImageIndex < 0) {
            mImageIndex = IMAGES.length - 1;
        }

        setImage(mImageIndex);
    }

    private void setImage(int index) {
        if (0 <= index && index < IMAGES.length) {
            mImageView.setImageResource(IMAGES[index]);
            mImageIndex = index;
        }
    }
}
