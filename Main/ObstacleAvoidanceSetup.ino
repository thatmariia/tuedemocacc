void obstacleAvoidanceSetup () {
  pinMode(ECHO, INPUT);    // Define the ultrasonic echo input pin
  pinMode(TRIG, OUTPUT);   // Define the ultrasonic trigger input pin 

  PulseInZero::setup(pulseInComplete);
}
