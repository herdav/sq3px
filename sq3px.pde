// SQ3PX 
// HSLU - Design & Art
// Created 2017 by David Herren
// https://github.com/herdav/dia
// Licensed under the MIT License.
// -------------------------------

import processing.serial.*;
import cc.arduino.*;

Arduino arduino;
Signifier[] signifier;
Target target;

int[] servo = new int[9];
int[] sensor = new int[4];
int[] servo_val_A = new int[9];
int[] servo_val_B = new int[9];
int[] sensor_val_A = new int[4];
int[] sensor_val_B = new int[4];
int[] sensor_read = new int[4];
int fan_pin = 12;
boolean fan_max;
int fan_max_delay;
int servo_max = 165;
int servo_min = 5;
float[] weighting_sensor = new float[9];
PVector[] P = new PVector[9];
PVector[] point = new PVector[9];
float x, y, dX, dY, k2, k3;
float correction_val_sensor;

void setup() {
  //fullScreen();
  size(1120, 630);
  smooth(8);
  x = height/3;
  y = x;
  dX = (width - 3*x)/2;
  dY = (height - 3*y)/2;
  arduino();
  graphic_setup();
  delay(1000);
}

void draw() {
  background(0);
  sensor();
  servo();
  fan();
  graphic();
  println();
}

void arduino() {
  arduino = new Arduino(this, Arduino.list()[0], 57600);
   for (int i = 0; i < 4; i++) {  
    sensor[i] = i + 4;
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
  correction_val_sensor = 0.8;
  weighting_sensor[0] = correction_val_sensor*(0.5*sensor_val_A[0] + 0.2*sensor_val_A[2] + 0.2*sensor_val_A[1] + 0.1*sensor_val_A[3]);  
  weighting_sensor[2] = correction_val_sensor*(0.5*sensor_val_A[1] + 0.2*sensor_val_A[3] + 0.2*sensor_val_A[0] + 0.1*sensor_val_A[2]); 
  weighting_sensor[6] = correction_val_sensor*(0.5*sensor_val_A[2] + 0.2*sensor_val_A[0] + 0.2*sensor_val_A[3] + 0.1*sensor_val_A[1]); 
  weighting_sensor[8] = correction_val_sensor*(0.5*sensor_val_A[3] + 0.2*sensor_val_A[1] + 0.2*sensor_val_A[2] + 0.1*sensor_val_A[0]);
  weighting_sensor[1] = 0.5*weighting_sensor[0] + 0.5*weighting_sensor[2];
  weighting_sensor[3] = 0.5*weighting_sensor[0] + 0.5*weighting_sensor[6];
  weighting_sensor[5] = 0.5*weighting_sensor[2] + 0.5*weighting_sensor[8];
  weighting_sensor[7] = 0.5*weighting_sensor[6] + 0.5*weighting_sensor[8];
  weighting_sensor[4] = 0.25*weighting_sensor[1] + 0.25*weighting_sensor[3] + 0.25*weighting_sensor[5] + 0.25*weighting_sensor[7];

  for (int i = 0; i < 9; i++) {
    servo_val_A[i] = int(map(weighting_sensor[i], 0, 255, servo_min, servo_max));
    if (sqrt(sq(servo_val_A[i] -  servo_val_B[i])) > 5) {
       fan_max = true;
    }
    servo_val_B[i] = int(map(weighting_sensor[i], 0, 255, servo_min, servo_max));
  }
}

void servo() {
  for (int i = 0; i < 9; i++) {
    arduino.servoWrite(servo[i], int((signifier[i].val+weighting_sensor[i])/2));
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

void graphic_setup() {
  int l = height/3;
  int x0 = (width-3*l)/2+l/2;
  int y0 = l/2;
  rectMode(CENTER);

  target = new Target();
  signifier = new Signifier[9];
  
  for (int i = 0; i < signifier.length; i++) {
    if (i < 3) {
      signifier[i] = new Signifier(l, x0+i*l, y0);
    }
    if (i >= 3) {
      signifier[i] = new Signifier(l, x0+(i-3)*l, y0+l);
    }
    if (i >= 6) {
      signifier[i] = new Signifier(l, x0+(i-6)*l, y0+2*l);
    }
  }
}

void graphic() {
  k2 = height/14;
  k3 = 0.1;
  point[0] = new PVector(0.25*x + k3*weighting_sensor[0] + dX, 0.25*y + k3*weighting_sensor[0] + dY);
  point[2] = new PVector(2.75*x - k3*weighting_sensor[2] + dX, 0.25*y + k3*weighting_sensor[2] + dY);
  point[6] = new PVector(0.25*x + k3*weighting_sensor[6] + dX, 2.75*x - k3*weighting_sensor[6] + dY);
  point[8] = new PVector(2.75*x - k3*weighting_sensor[8] + dX, 2.75*x - k3*weighting_sensor[8] + dY);
  point[1] = new PVector(1.50*x + k3*weighting_sensor[0] - k3*weighting_sensor[2] + dX, 0.75*y + k3*weighting_sensor[1] + dY - k2);
  point[7] = new PVector(1.50*x + k3*weighting_sensor[6] - k3*weighting_sensor[8] + dX, 2.25*y - k3*weighting_sensor[7] + dY + k2);
  point[3] = new PVector(0.75*x + k3*weighting_sensor[3] + dX - k2, 1.5*y + k3*weighting_sensor[0] - k3*weighting_sensor[6] + dY);
  point[5] = new PVector(2.25*x - k3*weighting_sensor[5] + dX + k2, 1.5*y - k3*weighting_sensor[8] + k3*weighting_sensor[2] + dY);
  point[4] = new PVector(1.5*x + dX, 1.5*y + dY);

  target.display();
  target.move();
  for (int i = 0; i < signifier.length; i++) {
    signifier[i].display(int(weighting_sensor[i]));
    signifier[i].pointer(point[i].x, point[i].y, int(weighting_sensor[i]));
  }

  stroke(50, 250);
  strokeWeight(1);  
  line(signifier[0].needle.x, signifier[0].needle.y, signifier[1].needle.x, signifier[1].needle.y);
  line(signifier[0].needle.x, signifier[0].needle.y, signifier[3].needle.x, signifier[3].needle.y);
  line(signifier[2].needle.x, signifier[2].needle.y, signifier[1].needle.x, signifier[1].needle.y);
  line(signifier[2].needle.x, signifier[2].needle.y, signifier[5].needle.x, signifier[5].needle.y);
  line(signifier[6].needle.x, signifier[6].needle.y, signifier[3].needle.x, signifier[3].needle.y);
  line(signifier[6].needle.x, signifier[6].needle.y, signifier[7].needle.x, signifier[7].needle.y);
  line(signifier[8].needle.x, signifier[8].needle.y, signifier[5].needle.x, signifier[5].needle.y);
  line(signifier[8].needle.x, signifier[8].needle.y, signifier[7].needle.x, signifier[7].needle.y);
  line(signifier[4].needle.x, signifier[4].needle.y, signifier[1].needle.x, signifier[1].needle.y);
  line(signifier[4].needle.x, signifier[4].needle.y, signifier[3].needle.x, signifier[3].needle.y);
  line(signifier[4].needle.x, signifier[4].needle.y, signifier[5].needle.x, signifier[5].needle.y);
  line(signifier[4].needle.x, signifier[4].needle.y, signifier[7].needle.x, signifier[7].needle.y);
}

class Signifier {
  int diameter;
  int val, val_eff;
  PVector pos = new PVector();
  PVector needle = new PVector();  

  Signifier(int tempDiameter, int tempX, int tempY) {
    pos.x = tempX;
    pos.y = tempY;
    diameter = tempDiameter;
  }
  void display(int sensor_val) {
    val_eff = (val+sensor_val)/2;
    fill(val_eff);
    noStroke();
    rect(pos.x, pos.y, diameter, diameter);
  }
  void pointer(float x, float y, int sensor_val) {
    int l = diameter/5;
    float distance_eff, distance_min, angle;
    val_eff = (val+sensor_val)/2;
    distance_eff = dist(x, y, target.pos.x, target.pos.y);
    distance_min = target.pos.x - x;
    angle = acos(distance_min / distance_eff);

    if (target.pos.x <= x) {
      needle.x = x;
    } else {
      needle.x = x + l * cos(angle);
    }
    if (pos.y < target.pos.y) {
      needle.y = y + l * sin(angle);
      if (target.pos.x <= pos.x) {
        needle.y = y + l;
      }
    }
    if (pos.y > target.pos.y) {
      needle.y = y - l * sin(angle);
      if (target.pos.x <= x) {
        needle.y = y - l;
      }
    }
    val = int(map(y + l - needle.y, 0, 2*l, servo_min, servo_max));

    fill(val);
    ellipse(pos.x, pos.y, diameter/1.5, diameter/1.5);
    strokeWeight(2);
    noStroke();
    fill(sensor_val);
    ellipse(x, y, diameter/2.5, diameter/2.5);
    strokeWeight(1);
    stroke(255);
    //line(x, y, needle.x, needle.y);
    noStroke();
    fill(0);
    ellipse(needle.x, needle.y, 10, 10);
  }
}

class Target {
  PVector pos = new PVector();
  float xspeed, yspeed;

  Target() {
    pos.x = width;
    pos.y = height/2;
    xspeed = 0;
    yspeed = 1;
  }
  void display() {
    fill(255);
    noStroke();
    ellipse(pos.x, pos.y, 50, 50);
  }
  void move() {
    int rand = height/5;
    pos.y = pos.y - yspeed;  
    if (pos.y > height-rand || pos.y < rand) {
      yspeed *= -1;
    }
    if (mousePressed == true) {
      pos.x = mouseX;
      pos.y = mouseY;
    }
  }
}
