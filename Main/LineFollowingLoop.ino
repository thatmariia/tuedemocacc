const double Kp =  0.71;//1.6//0.026//0.72//1//1.113//0.72    //1/20
const double Ki = 1.0 / 10000;   //1/10000   //1/1000
const double Kd = 10;//10    //1/10

#define beep_on  PCF8574Write(0xDF & PCF8574Read())
#define beep_off PCF8574Write(0x20 | PCF8574Read())

unsigned long lasttime_lf = 0;

TRSensors trs =   TRSensors();
unsigned int sensorValues[NUM_SENSORS];
unsigned int last_proportional = 0;
unsigned int position;
long integral = 0;
uint16_t i, j;
Adafruit_NeoPixel RGB = Adafruit_NeoPixel(4, PIN, NEO_GRB + NEO_KHZ800);

void PCF8574Write(byte data);
byte PCF8574Read();
uint32_t Wheel(byte WheelPos);

void stopCheck() {
  //analogWrite(PWMA,0);
  //analogWrite(PWMB,0);
  if ( //(sensorValues[0] > 900 && sensorValues[1] > 900 && sensorValues[2] > 900 && sensorValues[3] > 900 && sensorValues[3] > 900) ||
    (sensorValues[0] < 50 && sensorValues[1] < 50 && sensorValues[2] < 50 && sensorValues[3] < 50 && sensorValues[3] < 50)) {
    //speedToSetA = 0;
    //speedToSetB = 0;
  }
}

void lineFollowingLoop() {
  int a = analogRead(PWMA);
  int b = analogRead(PWMB);

  position = trs.readLine(sensorValues);

  // The "proportional" term should be 0 when we are on the line.
  //int proportional = (int)position - 2000;
  int proportional = 2000 - (int)position;

  // Compute the derivative (change) and integral (sum) of the position.
  int derivative = proportional - last_proportional;
  integral += proportional;

  // Remember the last position.
  last_proportional = proportional;

  // Compute the difference between the two motor power settings,
  // m1 - m2.  If this is a positive number the robot will turn
  // to the right.  If it is a negative number, the robot will
  // turn to the left, and the magnitude of the number determines
  // the sharpness of the turn.
  int power_difference = proportional * Kp + integral * Ki + derivative * Kd;

  // Compute the actual motor settings.  We never set either motor
  // to a negative value.
  if (power_difference > maximum) {
    power_difference = maximum;
  }
  if (power_difference < - maximum) {
    power_difference = - maximum;
  }
  if (power_difference < 0)
  {
    speedToSetA = maximum + power_difference;
    speedToSetB = maximum;

    va = maximum + power_difference;
    vb = maximum;
  }
  else
  {
    speedToSetA = maximum;
    speedToSetB = maximum - power_difference;

    va = maximum;
    vb = maximum - power_difference;
  }

  stopCheck();

  if (millis() - lasttime_lf > 200) {
    lasttime_lf = millis();
    for (i = 0; i < RGB.numPixels(); i++) {
      RGB.setPixelColor(i, Wheel(((i * 256 / RGB.numPixels()) + j) & 255));
    }
    RGB.show();
    if (j++ > 256 * 4) j = 0;
  }
}
