// SQ3PX
// Created 2017 by David Herren
// https://github.com/herdav/sq3px
// Licensed under the MIT License.
// -------------------------------

#include <Servo.h>

Servo servo0;
Servo servo1;
Servo servo2;
Servo servo3;
Servo servo4;
Servo servo5;
Servo servo6;
Servo servo7;
Servo servo8;

int servoVal0;
int servoVal1;
int servoVal2;
int servoVal3;
int servoVal4;
int servoVal5;
int servoVal6;
int servoVal7;
int servoVal8;

const int pho0 = A4;
const int pho1 = A5;
const int pho2 = A6;
const int pho3 = A7;

const int fan = A12;

int valPho0;
int valPho1;
int valPho2;
int valPho3;
int phoVal0;
int phoVal1;
int phoVal2;
int phoVal3;
String data1;
int angle = 165;

void setup() {
  Serial.begin(9600);
  Serial1.begin(38400);
  Serial2.begin(19200);
  Serial3.begin(4800);

  servo0.attach(2);
  servo1.attach(3);
  servo2.attach(4);
  servo3.attach(5);
  servo4.attach(6);
  servo5.attach(7);
  servo6.attach(8);
  servo7.attach(9);
  servo8.attach(10);
}
void loop() {
  valPho0 = analogRead(pho0);
  valPho1 = analogRead(pho1);
  valPho2 = analogRead(pho2);
  valPho3 = analogRead(pho3);

  servoVal0 = map(0.4*valPho0 + 0.2*valPho2 + 0.2*valPho1 + 0.1*valPho3,
  0, 1023,0, angle);
  servoVal2 = map(0.4*valPho1 + 0.2*valPho3 + 0.2*valPho0 + 0.1*valPho2,
  0, 1023, 0, angle);
  servoVal6 = map(0.4*valPho2 + 0.2*valPho0 + 0.2*valPho3 + 0.1*valPho1,
  0, 1023, 0, angle);
  servoVal8 = map(0.4*valPho3 + 0.2*valPho1 + 0.2*valPho2 + 0.1*valPho0,
  0, 1023, 0, angle);

  servoVal1 = 0.5*servoVal0 + 0.5*servoVal2;
  servoVal3 = 0.5*servoVal0 + 0.5*servoVal6;
  servoVal5 = 0.5*servoVal2 + 0.5*servoVal8;
  servoVal7 = 0.5*servoVal6 + 0.5*servoVal8;
  
  servoVal4 = 0.25*servoVal1 + 0.25*servoVal3 + 0.25*servoVal5 +
  0.25*servoVal7;

  servo0.write(servoVal0);
  servo1.write(servoVal1);
  servo2.write(servoVal2);
  servo3.write(servoVal3);
  servo4.write(servoVal4);
  servo5.write(servoVal5); 
  servo6.write(servoVal6); 
  servo7.write(servoVal7);  
  servo8.write(servoVal8);
  
  //data1 = normalizeData1(valPho0, valPho1, valPho2, valPho3);
  data1 = normalizeData1(valPho0, valPho1, valPho2, valPho3);
  Serial.println(data1);
  //Serial.println(servoVal0);

  analogWrite(fan, 255);
  
  delay(50);
}
String normalizeData1(int valPho0, int valPho1, int valPho2, int valPho3) {
  String val0string = String(valPho0);
  String val1string = String(valPho1);
  String val2string = String(valPho2);
  String val3string = String(valPho3);

  String ret = String('a') + val0string + String('b') + val1string +
  String('c') + val2string + String('d') + val3string + String('#');
  return ret;
}
