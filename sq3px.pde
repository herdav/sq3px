// SQ3PX 
// HSLU - Design & Art
// Created 2017 by David Herren
// https://github.com/herdav/dia
// Licensed under the MIT License.
// -------------------------------

import processing.serial.*;
import cc.arduino.*;
  
Serial myPort;
Arduino arduino;

int[] servo = new int[9];
int[] sensor = new int[4];

int fan_pin = 12;

int[] servo_val_A = new int[9];
int[] servo_val_B = new int[9];
int[] sensor_val_A = new int[4];
int[] sensor_val_B = new int[4];

int[] sensor_read = new int[4];

boolean fan_max;
int fan_max_delay;
int servo_max = 165;
int servo_min = 5;

float[] w = new float[9];
float[] W = new float[9];
float[] wFill = new float[9];
PVector[] P = new PVector[9];
float x, y, dX, dY, k1, k2;

void setup() {
  //fullScreen();
  size(600, 600);
  x = height/3;
  y = x;
  dX = (width - 3*x)/2;
  dY = (height - 3*y)/2;
  arduino();
  delay(1000);
}

void draw() {
  sensor();
  servo();
  fan();  
  graphic();
}

void arduino() {
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  for (int i = 0; i < 4; i++) {  
    sensor[i] = i + 12;
  }
  for (int i = 0; i < 9; i++) {
    servo[i] = i + 2;
    arduino.pinMode(servo[i], Arduino.SERVO);
  }  
  arduino.pinMode(fan_pin, Arduino.OUTPUT);
}

void sensor() {
  for (int i = 0; i < 4; i++) {
    sensor_val_A[i] = int(map(arduino.analogRead(sensor[i]), 0, 1023, 0, 255));
    if (sqrt(sq(sensor_val_A[i] - sensor_val_B[i])) > 10) {
      fan_max = true;
    }
    sensor_val_B[i] = int(map(arduino.analogRead(sensor[i]), 0, 1023, 0, 255));
  }

  k1 = 0.8;
  w[0] = k1*(0.5*sensor_val_A[0] + 0.2*sensor_val_A[2] + 0.2*sensor_val_A[1] + 0.1*sensor_val_A[3]);  
  w[2] = k1*(0.5*sensor_val_A[1] + 0.2*sensor_val_A[3] + 0.2*sensor_val_A[0] + 0.1*sensor_val_A[2]); 
  w[6] = k1*(0.5*sensor_val_A[2] + 0.2*sensor_val_A[0] + 0.2*sensor_val_A[3] + 0.1*sensor_val_A[1]); 
  w[8] = k1*(0.5*sensor_val_A[3] + 0.2*sensor_val_A[1] + 0.2*sensor_val_A[2] + 0.1*sensor_val_A[0]);
  w[1] = 0.5*w[0] + 0.5*w[2];
  w[3] = 0.5*w[0] + 0.5*w[6];
  w[5] = 0.5*w[2] + 0.5*w[8];
  w[7] = 0.5*w[6] + 0.5*w[8];
  w[4] = 0.25*w[1] + 0.25*w[3] + 0.25*w[5] + 0.25*w[7];

  for (int i = 0; i < 9; i++) {
    servo_val_A[i] = int(map(wFill[i], 0, 255, servo_min, servo_max));
    if (sqrt(sq(servo_val_A[i] -  servo_val_B[i])) > 5) {
       fan_max = true;
    }
    servo_val_B[i] = int(map(wFill[i], 0, 255, servo_min, servo_max));
    W[i] = 0.1*w[i];
    wFill[i] = 1*w[i];
  }
}

void servo() {
  if (mousePressed != true) {
    for (int i = 0; i < 9; i++) {
      arduino.servoWrite(servo[i], servo_val_A[i]);
    }
  }
  if (mousePressed == true) {
    if (keyCode == UP) {
      for (int i = 0; i < 9; i++) {
        wFill[i] = 255;
        arduino.servoWrite(servo[i], servo_max);
      }
    }
    if (keyCode == DOWN) {
      for (int i = 0; i < 9; i++) {
        wFill[i] = 0;
        arduino.servoWrite(servo[i], servo_min);
      }
    }
    if (keyCode == RIGHT) {
      for (int i = 0; i < 9; i++) {
        wFill[i] = 128;
        arduino.servoWrite(servo[i], (servo_max+servo_min)/2);
      }
    }
  }
}

void fan() {
  if (fan_max == true) {
    fan_max_delay = millis();
    fan_max = false;
  }
  if (millis() - fan_max_delay < 10000) {
    arduino.analogWrite(fan_pin, 255);
  } else {
    arduino.analogWrite(fan_pin, 0);
  }
}

void graphic() {
  background(0);
  noStroke();
  fill(wFill[0], wFill[0], wFill[0]);
  rect(0+dX, 0+dY, x, y);
  fill(wFill[1], wFill[1], wFill[1]);
  rect(0+dX, y+dY, x, y);
  fill(wFill[2], wFill[2], wFill[2]);
  rect(0+dX, 2*y+dY, x, y);
  fill(wFill[3], wFill[3], wFill[3]);
  rect(x+dX, 0+dY, x, y);
  fill(wFill[4], wFill[4], wFill[4]);
  rect(x+dX, y+dY, x, y);
  fill(wFill[5], wFill[5], wFill[5]);
  rect(x+dX, 2*y+dY, x, y);
  fill(wFill[6], wFill[6], wFill[6]);
  rect(2*x+dX, 0+dY, x, y);
  fill(wFill[7], wFill[7], wFill[7]);
  rect(2*x+dX, y+dY, x, y);
  fill(wFill[8], wFill[8], wFill[8]);
  rect(2*x+dX, 2*y+dY, x, y);

  k2 = height/14;
  P[0] = new PVector(0.25*x + W[0] + dX, 0.25*y + W[0] + dY);
  P[2] = new PVector(2.75*x - W[2] + dX, 0.25*y + W[2] + dY);
  P[6] = new PVector(0.25*x + W[6] + dX, 2.75*x - W[6] + dY);
  P[8] = new PVector(2.75*x - W[8] + dX, 2.75*x - W[8] + dY);
  P[1] = new PVector(1.50*x + W[0] - W[2] + dX, 0.75*y + W[1] + dY - k2);
  P[7] = new PVector(1.50*x + W[6] - W[8] + dX, 2.25*y - W[7] + dY + k2);
  P[3] = new PVector(0.75*x + W[3] + dX - k2, 1.5*y + W[0] - W[6] + dY);
  P[5] = new PVector(2.25*x - W[5] + dX + k2, 1.5*y - W[8] + W[2] + dY);
  P[4] = new PVector(1.5*x + dX, 1.5*y + dY);

  for (int i=0; i < P.length; i++) {
    fill(255 - wFill[i]);
    ellipse(P[i].x, P[i].y, x/2.5, y/2.5);
    fill(wFill[i]);
    ellipse(P[i].x, P[i].y, x/4, y/4);
  }

  stroke(255, 70);
  strokeWeight(1);
  line(P[0].x, P[0].y, P[2].x, P[2].y);
  line(P[0].x, P[0].y, P[6].x, P[6].y);
  line(P[8].x, P[8].y, P[6].x, P[6].y);
  line(P[8].x, P[8].y, P[2].x, P[2].y);  
  line(P[0].x, P[0].y, P[3].x, P[3].y);
  line(P[0].x, P[0].y, P[1].x, P[1].y);
  line(P[2].x, P[2].y, P[1].x, P[1].y);
  line(P[2].x, P[2].y, P[5].x, P[5].y);
  line(P[6].x, P[6].y, P[3].x, P[3].y);
  line(P[6].x, P[6].y, P[7].x, P[7].y);
  line(P[8].x, P[8].y, P[5].x, P[5].y);
  line(P[8].x, P[8].y, P[7].x, P[7].y);
  line(P[4].x, P[4].y, P[1].x, P[1].y);
  line(P[4].x, P[4].y, P[3].x, P[3].y);
  line(P[4].x, P[4].y, P[5].x, P[5].y);
  line(P[4].x, P[4].y, P[7].x, P[7].y);
  line(P[0].x, P[0].y, P[8].x, P[8].y);
  line(P[2].x, P[2].y, P[6].x, P[6].y);
}
