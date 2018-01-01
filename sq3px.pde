// SQ3PX
// Created 2017 by David Herren
// https://github.com/herdav/sq3px
// Licensed under the MIT License.
// -------------------------------

import processing.serial.*;
import cc.arduino.*;
Arduino arduino;

/* actors and sensors */
int servo_num = 9;
int[] servo = new int[servo_num];
int[] servo_val = new int[servo_num];
int servo_max = 160;
int servo_min = 20;

int sensor_num = 4;
int[] sensor = new int[sensor_num];

int[] sensor_proportional = new int[sensor_num];
int[] sensor_integral = new int[sensor_num];
int[] sensor_differential_A = new int[sensor_num];
int[] sensor_differential_B = new int[sensor_num];
int[] sensor_differential = new int[sensor_num];
int[] sensor_PI_difference = new int[sensor_num];
int[] sensor_PID_difference = new int[sensor_num];

int[] sensor_val = new int[sensor_num];
int sensor_store_lenght = 100;
int[][] sensor_val_store = new int[sensor.length][sensor_store_lenght];
int count_sensor_val = 0;
int[] weighting_sensor = new int[servo_num];
int weighting_store_lenght = 5;
int[][] weighting_store = new int[weighting_sensor.length][weighting_store_lenght];
int count_weighting = 0;
int fan_pin = 12;
int fan_max_delay;
boolean fan_max;

/* graphic */
Signifier[] signifier;
PVector[] point = new PVector[weighting_sensor.length];
PFont cour;
int lines = 3;
int weight = 5;
int wide;
int cycle;
int time_start, time_stop;

void setup() {
  /* actors and sensors setup */
  arduino = new Arduino(this, "COM4", 57600);
  for (int i = 0; i < sensor.length; i++) {  
    sensor[i] = i + sensor.length;
  }
  for (int i = 0; i < servo.length; i++) {
    servo[i] = i + 2;
    arduino.pinMode(servo[i], Arduino.SERVO);
  }  
  arduino.pinMode(fan_pin, Arduino.OUTPUT);

  /* graphic setup */
  //fullScreen();
  size(1280, 800);
  graphic_setup();
  delay(1000);
}

void draw() {
  background(0);
  sensors();
  servos();
  fan();
  graphic();
  data();
  println();
}

void sensors() {
  for (int i = 0; i < sensor.length; i++) {
    sensor_proportional[i] = arduino.analogRead(sensor[i]);
    sensor_val_store[i][count_sensor_val] = sensor_proportional[i];
    for (int j = 0; j < sensor_store_lenght; j++) {
      sensor_integral[i] += sensor_val_store[i][j];
    }
    sensor_integral[i] = (sensor_integral[i] / (sensor_store_lenght+1));
    sensor_PI_difference[i] = sensor_proportional[i] - sensor_integral[i];
  } 
  count_sensor_val++;
  if (count_sensor_val == sensor_store_lenght) {
    count_sensor_val = 0;
  }
  for (int i = 0; i < sensor_val.length; i++) {
    sensor_differential_A[i] = sensor_integral[i];
    sensor_differential[i] = (sensor_differential_A[i] - sensor_differential_B[i])*2;
    sensor_differential_B[i] = sensor_integral[i];
    sensor_PID_difference[i] = sensor_proportional[i] - sensor_PI_difference[i] - int(sensor_differential[i]);
  }
  
  for (int i = 0; i < sensor_val.length; i++) {
    sensor_val[i] = int(map(sensor_integral[i]+sensor_differential[i], 0, 1023, 0, 255));
  }

  weighting_sensor[0] = int((0.5*sensor_val[0] + 0.2*sensor_val[2] + 0.2*sensor_val[1] + 0.1*sensor_val[3]));  
  weighting_sensor[2] = int((0.5*sensor_val[1] + 0.2*sensor_val[3] + 0.2*sensor_val[0] + 0.1*sensor_val[2])); 
  weighting_sensor[6] = int((0.5*sensor_val[2] + 0.2*sensor_val[0] + 0.2*sensor_val[3] + 0.1*sensor_val[1])); 
  weighting_sensor[8] = int((0.5*sensor_val[3] + 0.2*sensor_val[1] + 0.2*sensor_val[2] + 0.1*sensor_val[0]));
  weighting_sensor[1] = int(0.5*weighting_sensor[0] + 0.5*weighting_sensor[2]);
  weighting_sensor[3] = int(0.5*weighting_sensor[0] + 0.5*weighting_sensor[6]);
  weighting_sensor[5] = int(0.5*weighting_sensor[2] + 0.5*weighting_sensor[8]);
  weighting_sensor[7] = int(0.5*weighting_sensor[6] + 0.5*weighting_sensor[8]);
  weighting_sensor[4] = int(0.25*weighting_sensor[1] + 0.25*weighting_sensor[3] + 0.25*weighting_sensor[5] + 0.25*weighting_sensor[7]);

  for (int i = 0; i < weighting_sensor.length; i++) {
    servo_val[i] = int(map(weighting_sensor[i], 0, 255, servo_min, servo_max));    
    weighting_store[i][count_weighting] = int(map(weighting_sensor[i], 0, 255, -height/7, height/7));    
    if (count_weighting < weighting_store_lenght-1) {
      weighting_store[i][count_weighting] = weighting_store[i][count_weighting+1];
    } else {
      weighting_store[i][count_weighting] = weighting_store[i][weighting_store_lenght-1];
    }
  }
  count_weighting++;
  if (count_weighting == weighting_store_lenght) {
    count_weighting = 0;
  }
}

void servos() {
  int[] servo_write = new int[servo.length];  
  for (int i = 0; i < servo_write.length; i++) {
    servo_write[i] = servo_val[i];
    if (key == CODED) {
      if (keyCode == UP) {
        arduino.servoWrite(servo[i], servo_max);
      }
      if (keyCode == DOWN) {
        arduino.servoWrite(servo[i], servo_min);
      }
      if (keyCode == RIGHT) {
        arduino.servoWrite(servo[i], (servo_min+servo_max)/2);
      }
      if (keyCode == LEFT) {
        arduino.servoWrite(servo[i], servo_write[i]);
      }
    } else {
      arduino.servoWrite(servo[i], servo_write[i]);
    }
  }
}

void fan() {
  arduino.analogWrite(fan_pin, 255);
}

void graphic_setup() {
  rectMode(CENTER);
  wide = height / 3;
  int x0 = (width - 3*wide)/2 + wide/2;
  int y0 = wide/2;
  signifier = new Signifier[weighting_sensor.length];

  for (int i = 0; i < signifier.length; i++) {
    if (i < signifier.length/3) {
      signifier[i] = new Signifier(wide, x0 + i*wide, y0);
    }
    if (i >= signifier.length/3) {
      signifier[i] = new Signifier(wide, x0 + (i-3)*wide, y0 + wide);
    }
    if (i >= signifier.length/3*2) {
      signifier[i] = new Signifier(wide, x0 + (i-6)*wide, y0 + 2*wide);
    }
  }
}

void graphic() {
  int dX, dY, k, x, y, l;
  x = wide;
  y = x;
  dX = (width - 3*x)/2;
  dY = (height - 3*y)/2;
  l = x / (weighting_store_lenght - 3);
  k = height/14;

  point[0] = new PVector(0.25*x + weighting_sensor[0] + dX, 0.25*y + weighting_sensor[0] + dY);
  point[2] = new PVector(2.75*x - weighting_sensor[2] + dX, 0.25*y + weighting_sensor[2] + dY);
  point[6] = new PVector(0.25*x + weighting_sensor[6] + dX, 2.75*x - weighting_sensor[6] + dY);
  point[8] = new PVector(2.75*x - weighting_sensor[8] + dX, 2.75*x - weighting_sensor[8] + dY);
  point[1] = new PVector(1.50*x + weighting_sensor[0] - weighting_sensor[2] + dX, 0.75*y + weighting_sensor[1] + dY - k);
  point[7] = new PVector(1.50*x + weighting_sensor[6] - weighting_sensor[8] + dX, 2.25*y - weighting_sensor[7] + dY + k);
  point[3] = new PVector(0.75*x + weighting_sensor[3] + dX - k, 1.5*y + weighting_sensor[0] - weighting_sensor[6] + dY);
  point[5] = new PVector(2.25*x - weighting_sensor[5] + dX + k, 1.5*y - weighting_sensor[8] + weighting_sensor[2] + dY);
  point[4] = new PVector(1.5*x + dX, 1.5*y + dY);

  for (int i = 0; i < signifier.length; i++) {
    signifier[i].display_rect(int(weighting_sensor[i]));
  }
  for (int j = 0; j < signifier.length; j++) {
    noFill();  
    stroke(255-weighting_sensor[j]);
    strokeWeight(weight);
    strokeCap(SQUARE);
    for (int n = 0; n < lines; n++) {
      int d = (1024 / (weighting_sensor[j]+1)) + weight;
      beginShape();
      for (int i = 0; i < weighting_store_lenght; i++) {
        curveVertex(signifier[j].pos.x + i*l - x/2 - l, signifier[j].pos.y + weighting_store[j][i] - n*d);
      }
      endShape();
    }
  }
}

void data() {
  int gap = 45;
  int rand = 10;
  time_start = millis();
  cycle = time_start - time_stop;
  time_stop = millis();
  fill(0, 255, 255);
  textAlign(LEFT);
  text("P: ", rand, 50);
  text("I: ", rand, 75);
  text("D: ", rand, 100);
  textAlign(RIGHT);
  for (int i = 0; i < sensor.length; i++) {
    text(sensor_proportional[i], wide -(i+1)*gap - rand, 50);
    text(sensor_PI_difference[i], wide-(i+1)*gap - rand, 75);
    text(sensor_differential[i], wide-(i+1)*gap - rand, 100);
    text(sensor_PID_difference[i], wide-(i+1)*gap - rand, 125);
    text(sensor_PID_difference[i]-sensor_proportional[i], wide-(i+1)*gap - rand, 150);
  }
  for (int i = 0; i < 3; i++) {
    text(weighting_sensor[i], wide-(i+1)*gap-rand, 200);
  }
  for (int i = 0; i < 3; i++) {
    text(weighting_sensor[i+3], wide-(i+1)*gap-rand, 225);
  }
  for (int i = 0; i < 3; i++) {
    text(weighting_sensor[i+6], wide-(i+1)*gap-rand, 250);
  }
  text(cycle + "ms/cycle", wide - 60, 300);
}

class Signifier {
  int diameter;
  int val, val_eff;
  PVector pos = new PVector();

  Signifier(int tempDiameter, float tempX, float tempY) {
    pos.x = tempX;
    pos.y = tempY;
    diameter = tempDiameter;
  }
  void display_rect(int sensor_val) {
    fill(sensor_val);
    noStroke();
    rect(pos.x, pos.y, diameter, diameter);
  }
}
