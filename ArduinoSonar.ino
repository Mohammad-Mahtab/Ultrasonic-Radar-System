/*Ultrasonic radar system.
  *Upload the following code first.
  *Serial monitor readings.
  *created by the SriTu Tech team.
  *Read the code below and use it for any of your creations.
*/
#include <Servo.h>//include library
Servo myServo;//create object your own name

// Define ultrasonic sensor pins
const int trigPin = 9;  // Trigger pin for ultrasonic sensor
const int echoPin = 10; // Echo pin for ultrasonic sensor

int dis;
void setup() {
  pinMode(trigPin, OUTPUT);//define arduino pin
  pinMode(echoPin, INPUT);//define arduino pin
  Serial.begin(9600);//enable serial monitor
  myServo.attach(8);//servo connect pin
}
void loop() {
  for (int x = 0; x <= 180; x++) { //servo turn left
    myServo.write(x);//rotete servo
    dis=distance();
    Serial.print(x);//print servo angle
    Serial.print(",");
    Serial.print(dis);//print ultrasonic readings
    Serial.print(".");
    delay(50);
  }
  for (int y = 179; y > 0; y--) {//servo turn right
    myServo.write(y);//rotete servo
    dis=distance();
    Serial.print(y);////print servo angle
    Serial.print(",");
    Serial.print(dis);//print ultrasonic readings
    Serial.print(".");
    delay(50);
  }
}
//ultrasonic sensor code
int distance() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(4);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
 
 
  int t = pulseIn(echoPin, HIGH);
  int cm = t / 29 / 2; //time convert distance
  return cm;//return value
}
