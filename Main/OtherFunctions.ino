void PCF8574Write(byte data)
{
  Wire.beginTransmission(Addr);
  Wire.write(data);
  Wire.endTransmission(); 
}

byte PCF8574Read()
{
  int data = -1;
  Wire.requestFrom(Addr, 1);
  if(Wire.available()) {
    data = Wire.read();
  }
  return data;
}

uint32_t Wheel(byte WheelPos) {
  if(WheelPos < 85) {
   return RGB.Color(WheelPos * 50, 255 - WheelPos * 50, 0);
  } else if(WheelPos < 170) {
   WheelPos -= 85;
   return RGB.Color(255 - WheelPos * 50, 0, WheelPos * 50);
  } else {
   WheelPos -= 170;
   return RGB.Color(0, WheelPos * 50, 255 - WheelPos * 50);
  }
}
