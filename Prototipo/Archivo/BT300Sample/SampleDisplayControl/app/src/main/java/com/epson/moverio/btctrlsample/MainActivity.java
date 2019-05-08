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


package com.epson.moverio.btctrlsample;

import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.CheckBox;
import android.widget.SeekBar;
import android.widget.Button;
import com.epson.moverio.btcontrol.DisplayControl;

public class MainActivity extends AppCompatActivity implements OnClickListener, SeekBar.OnSeekBarChangeListener {
    DisplayControl _displayControl;
    Button _btnMode, _btnMute;
    CheckBox _cbShowToast;
    SeekBar _seekBar;
    int _mode, _backlight;
    boolean _showToast = true;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // create instance
        _displayControl = new DisplayControl(this);

        _btnMode = (Button)findViewById(R.id.btn1);
        _btnMute = (Button)findViewById(R.id.btn2);
        _cbShowToast = (CheckBox)findViewById(R.id.cbOSD);
        _seekBar = (SeekBar)findViewById(R.id.sbar);

        // set listener
        _btnMode.setOnClickListener(this);
        _btnMute.setOnClickListener(this);
        _cbShowToast.setOnClickListener(this);
        _seekBar.setOnSeekBarChangeListener(this);

        // get current display condition
        _mode = _displayControl.getMode();
        _backlight = _displayControl.getBacklight();

        // set GUI parts parameters
        _seekBar.setMax(20);
        _seekBar.setProgress(_backlight);

        if (_mode == DisplayControl.DISPLAY_MODE_2D){
            _btnMode.setText("2D");
        }else if (_mode == DisplayControl.DISPLAY_MODE_3D){
            _btnMode.setText("3D");
        }

        View view = this.getWindow().getDecorView();
        view.setSystemUiVisibility(View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
                View.SYSTEM_UI_FLAG_FULLSCREEN |
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);

    }

    @Override
    public void onClick(View v){

        if(v == _btnMode) {
            _mode = _displayControl.getMode();

            if (_mode == DisplayControl.DISPLAY_MODE_2D) {
                // change to 3D mode
                _btnMode.setText("3D");
                _mode = DisplayControl.DISPLAY_MODE_3D;

            } else if (_mode == DisplayControl.DISPLAY_MODE_3D) {
                //change to 2D mode
                _btnMode.setText("2D");
                _mode = DisplayControl.DISPLAY_MODE_2D;
            }
            _displayControl.setMode(_mode, _showToast);

        }else if (v == _btnMute) {

            boolean isMute = _displayControl.getMute();
            if (isMute == false) {
                _displayControl.setMute(true);
                try {
                    Thread.sleep(3 * 1000); //wait for 3 sec
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                _displayControl.setMute(false);
            }
        }else if (v == _cbShowToast){
            if (true == _cbShowToast.isChecked()){
                _showToast = true;
            }else {
                _showToast = false;
            }
        }
    }

    @Override
    public void onProgressChanged(SeekBar sBar, int Progress, boolean fromUser){
        _backlight = Progress;
        _displayControl.setBacklight(_backlight);
    }

    @Override
    public void onStartTrackingTouch(SeekBar sBar){
    }

    @Override
    public void onStopTrackingTouch(SeekBar sBar){
    }

}
