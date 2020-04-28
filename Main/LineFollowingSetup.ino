//Adafruit_SSD1306 display(OLED_RESET, OLED_SA0);

void lineFollowingSetup() {
  
  int button = 0;
  while(value != 0xEF)  //wait button pressed
  {
    PCF8574Write(0x1F | PCF8574Read());
    button = PCF8574Read() | 0xE0;
  }
   
  analogWrite(PWMA,0);
  analogWrite(PWMB,0);
  digitalWrite(AIN2,HIGH);
  digitalWrite(AIN1,LOW);
  digitalWrite(BIN1,HIGH); 
  digitalWrite(BIN2,LOW);
  
  RGB.begin();
  RGB.setPixelColor(0,0x00FF00 );
  RGB.setPixelColor(1,0x00FF00 );
  RGB.setPixelColor(2,0x00FF00 );
  RGB.setPixelColor(3,0x00FF00);
  RGB.show(); 
  
  delay(500);
  
  analogWrite(PWMA,80);
  analogWrite(PWMB,80);
  
  for (int i = 0; i < 100; i++)  // make the calibration take about 10 seconds
  {
    if(i<25 || i >= 75)
    {
      digitalWrite(AIN1,HIGH);
      digitalWrite(AIN2,LOW);
      digitalWrite(BIN1,LOW); 
      digitalWrite(BIN2,HIGH);  
    }
    else
    {
      digitalWrite(AIN1,LOW);
      digitalWrite(AIN2,HIGH);
      digitalWrite(BIN1,HIGH); 
      digitalWrite(BIN2,LOW);  
    }
    trs.calibrate();       // reads all sensors 100 times
  }
  
  analogWrite(PWMA,0);
  analogWrite(PWMB,0);
  digitalWrite(AIN2,LOW);
  digitalWrite(AIN1,LOW);
  digitalWrite(BIN1,LOW); 
  digitalWrite(BIN2,LOW);  
  
  RGB.setPixelColor(0,0x0000FF );
  RGB.setPixelColor(1,0x0000FF );
  RGB.setPixelColor(2,0x0000FF );
  RGB.setPixelColor(3,0x0000FF);
  RGB.show(); // Initialize all pixels to 'off'
  
  button = 0;
  while(button != 0xEF)  //wait button pressed
  {
    PCF8574Write(0x1F | PCF8574Read());
    button = PCF8574Read() | 0xE0;
  }
  
  delay(500);
  digitalWrite(AIN1,LOW);
  digitalWrite(AIN2,HIGH);
  digitalWrite(BIN1,LOW); 
  digitalWrite(BIN2,HIGH);  
}
