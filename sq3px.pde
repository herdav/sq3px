// SQ3PX 
// HSLU - Design & Art
// Created 2017 by David Herren
// https://github.com/herdav/dia
// Licensed under the MIT License.
// -----------------------------------

import processing.serial.*;
import cc.arduino.*;

Serial myPort;
Arduino arduino;

int[] servo = new int[9];
int[] sensor = new int[4];
int fan = 12;

int[] servo_val = new int[9];
int[] sensor_val = new int[4];

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
}

void draw() {
  sensor();
  servo();
  fan();  
  graphic();
}