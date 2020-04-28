unsigned long lasttime = 0;
int prev_distance = 0;

int distance = 100;

int prev_power = 0;
bool distance_mutex = false;

#define _kp 30//35.4
#define _ki 3
#define _kd 25
 
//FastPID pid(_kp, _ki, _kd, 10);

void obstacleControllerLoop () {

  if(millis() - lasttime > 50 && !distance_mutex) {
    lasttime = millis();
    measureDistance();
    distance_mutex = true;
  }

  double speed = (( speedToSetA + speedToSetB) / 2) / 200;
      
  //PCF8574Write(0xC0 | PCF8574Read());
  //value = PCF8574Read() | 0x3F;         //read IR distane sensor
  //if (distance < 3 || value != 0xFF) {      //Ultrasonic range ranging 2cm to 400cm
   if (distance < 5) {
    stop();
    lasttime_stop = millis();
    stopFlag = true;
  } else if(distance < 20) {
    maximum /= 2;
    /*const int standstill = 5;
    const double headway = 20;
    int ddes = (speed * headway + standstill);

    int setpoint = distance - ddes;

   int power = pid.step(setpoint, prev_power);
    Serial.println(power);
  
   if(power > bt_maximum) { power = bt_maximum; } 
   if(power < 0) { power  = 0; }

    prev_power = power;

    maximum = power;

       // Serial.print("Speed: ");
    Serial.print(speed*10);
    Serial.print("\t");
    
    //Serial.print(" distance: ");
    Serial.print(distance);
    Serial.print("\t");
    
    Serial.println(maximum);*/
  }
}

void measureDistance()         // Measure the distance
{
  digitalWrite(TRIG, LOW);   // set trig pin low 2μs
  delayMicroseconds(2);
  digitalWrite(TRIG, HIGH);  // set trig pin 10μs , at last 10us
  delayMicroseconds(10);
  digitalWrite(TRIG, LOW);    // set trig pin low
  PulseInZero::begin(); // Read echo pulse with interrupt
}

void stop()
{
  speedToSetA = 0;
  speedToSetB = 0;
}

void pulseInComplete(unsigned long duration){
  if(duration != 0) {
    distance = (float)duration / 58;    //Y m=（X s*344）/2  
  } else {
    distance = 255; 
  }
  distance_mutex = false;
}
