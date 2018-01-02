// SQ3PX
// Created 2017 by David Herren
// https://github.com/herdav/sq3px
// Licensed under the MIT License.
// -------------------------------

import processing.serial.*;
import cc.arduino.*;
Arduino arduino;

// actors
int servo_num = 9;
int[] servo = new int[servo_num];
int[] servo_valid = new int[servo_num];
int servo_max = 160;
int servo_min = 20;
int fan_pin = 12;
int fan_max_delay;
boolean fan_max;

//sensors
int sensor_num = 4;
int[] sensor = new int[sensor_num];
int sensor_store_lenght = 70;
int count_sensor_proportional = 0;
int count_weighting = 0;
int weighting_store_lenght = 5;
float[] sensor_proportional = new float[sensor_num];
float[] sensor_integral_A = new float[sensor_num];
float[] sensor_integral_B = new float[sensor_num];
float[] sensor_differential = new float[sensor_num];
float[] sensor_output = new float[sensor_num];
float[][] sensor_proportional_store = new float[sensor.length][sensor_store_lenght];
float sensor_differential_gain;
int[] sensor_valid = new int[sensor_num];
int[] weighting_sensor = new int[servo_num];
int[][] weighting_store = new int[weighting_sensor.length][weighting_store_lenght];

// graphic
Signifier[] signifier;
PVector[] point = new PVector[weighting_sensor.length];
int lines = 3;
int weight = 5;
int wide;

// data test
int cycle;
int time_start, time_stop;
int data_length = 600;
int[] input = new int[data_length];
int[] output_A = new int[data_length];
int[] output_B = new int[data_length];
int count_output = 0;

void setup() {
  // actors and sensors setup
  arduino = new Arduino(this, "COM4", 57600);
  for (int i = 0; i < sensor.length; i++) {  
    sensor[i] = i + sensor.length;
  }
  for (int i = 0; i < servo.length; i++) {
    servo[i] = i + 2;
    arduino.pinMode(servo[i], Arduino.SERVO);
  }  
  arduino.pinMode(fan_pin, Arduino.OUTPUT);

  // graphic setup
  // fullScreen();
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
  //data();
  println();
}

void sensors() {  
  // regulate sensor data  
  for (int i = 0; i < sensor.length; i++) {
    sensor_proportional[i] = arduino.analogRead(sensor[i]);
    sensor_proportional_store[i][count_sensor_proportional] = sensor_proportional[i];
    for (int j = 0; j < sensor_store_lenght; j++) {
      sensor_integral_A[i] += sensor_proportional_store[i][j];
    }
    sensor_integral_A[i] = sensor_integral_A[i] / (sensor_store_lenght+1);
  } 
  count_sensor_proportional++;
  if (count_sensor_proportional == sensor_store_lenght) {
    count_sensor_proportional = 0;
  }
  for (int i = 0; i < sensor_valid.length; i++) {
    sensor_differential[i] = sensor_integral_A[i] / sensor_proportional[i];
  }
  sensor_differential_gain = 0.5;
  for (int i = 0; i < sensor_valid.length; i++) {   
    sensor_differential[i] = sensor_integral_A[i] - sensor_integral_B[i];
    sensor_integral_B[i] = sensor_integral_A[i];
    sensor_output[i] = sensor_integral_A[i] + sensor_differential_gain*sensor_differential[i];
    sensor_valid[i] = int(map(sensor_output[i], 0, 1024, 0, 255));
  }  
  // weighting sensor data for servos and graphic
  weighting_sensor[0] = int((0.5*sensor_valid[0] + 0.2*sensor_valid[2] + 0.2*sensor_valid[1] + 0.1*sensor_valid[3]));  
  weighting_sensor[2] = int((0.5*sensor_valid[1] + 0.2*sensor_valid[3] + 0.2*sensor_valid[0] + 0.1*sensor_valid[2])); 
  weighting_sensor[6] = int((0.5*sensor_valid[2] + 0.2*sensor_valid[0] + 0.2*sensor_valid[3] + 0.1*sensor_valid[1])); 
  weighting_sensor[8] = int((0.5*sensor_valid[3] + 0.2*sensor_valid[1] + 0.2*sensor_valid[2] + 0.1*sensor_valid[0]));
  weighting_sensor[1] = int(0.5*weighting_sensor[0] + 0.5*weighting_sensor[2]);
  weighting_sensor[3] = int(0.5*weighting_sensor[0] + 0.5*weighting_sensor[6]);
  weighting_sensor[5] = int(0.5*weighting_sensor[2] + 0.5*weighting_sensor[8]);
  weighting_sensor[7] = int(0.5*weighting_sensor[6] + 0.5*weighting_sensor[8]);
  weighting_sensor[4] = int(0.25*weighting_sensor[1] + 0.25*weighting_sensor[3] + 0.25*weighting_sensor[5] + 0.25*weighting_sensor[7]);

  for (int i = 0; i < weighting_sensor.length; i++) {
    servo_valid[i] = int(map(weighting_sensor[i], 0, 255, servo_min, servo_max));    
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
  // control servos
  int[] servo_write = new int[servo.length];  
  for (int i = 0; i < servo_write.length; i++) {
    servo_write[i] = servo_valid[i];
    if (key == CODED) {
      if (keyCode == UP) {
        arduino.servoWrite(servo[i], 165);
      }
      if (keyCode == DOWN) {
        arduino.servoWrite(servo[i], 5);
      }
      if (keyCode == RIGHT) {
        arduino.servoWrite(servo[i], 90);
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
  // control fan
  arduino.analogWrite(fan_pin, 255);
}

void graphic_setup() {
  // initialize graphic
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
  // show graphic
  int dX, dY, k, x, y, l;
  x = wide;
  y = x;
  dX = (width-3*x)/2;
  dY = (height-3*y)/2;
  l = x/(weighting_store_lenght-3);
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

class Signifier {
  int diameter;
  int valid, valid_eff;
  PVector pos = new PVector();

  Signifier(int tempDiameter, float tempX, float tempY) {
    pos.x = tempX;
    pos.y = tempY;
    diameter = tempDiameter;
  }
  void display_rect(int sensor_valid) {
    fill(sensor_valid);
    noStroke();
    rect(pos.x, pos.y, diameter, diameter);
  }
}

void data() {
  // visualize control system
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
    text(int(sensor_proportional[i]), wide - (i+1)*gap - rand, 50);
    text(int(sensor_integral_A[i]), wide - (i+1)*gap - rand, 75);
    text(sensor_differential[i], wide - (i+1)*gap - rand, 100);
    text(int(sensor_output[i]), wide - (i+1)*gap - rand, 125);
  }
  for (int i = 0; i < 3; i++) {
    text(weighting_sensor[i], wide - (i+1)*gap - rand, 200);
  }
  for (int i = 0; i < 3; i++) {
    text(weighting_sensor[i+3], wide - (i+1)*gap - rand, 225);
  }
  for (int i = 0; i < 3; i++) {
    text(weighting_sensor[i+6], wide - (i+1)*gap - rand, 250);
  }
  text(cycle + "ms/cycle", wide - 60, 300);
  count_output++;
  if (count_output == output_A.length) {
    count_output = 0;
  }
  input[count_output] = int(map(sensor_proportional[0], 0, 1024, 0, 255));
  output_A[count_output] = int(map(sensor_output[0], 0, 1024, 0, 255));
  output_B[count_output] = weighting_sensor[0];
  noFill();
  strokeWeight(1);
  beginShape();
  stroke(255, 0, 0);
  for (int i = 0; i < input.length; i++) {
    curveVertex(50 + i*2, height/2 + input[i]);
  }
  endShape();
  beginShape();
  stroke(0, 255, 0);
  for (int i = 0; i < output_A.length; i++) {
    curveVertex(50 + i*2, height/2 + output_A[i]);
  }
  endShape();
  beginShape();
  stroke(0, 255, 255);
  for (int i = 0; i < output_A.length; i++) {
    curveVertex(50 + i*2, height/2 + output_B[i]);
  }
  endShape();
}
