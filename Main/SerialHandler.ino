void handleSerialData() {
  String comdata = "";
  while (Serial.available() > 0) {
    char serialchar = char(Serial.read());
	comdata += serialchar;
	
	if(serialchar == '#') {
	 break;
	}
	
    delay(2); // Small delay to allow BT module to send more information
  }
  if (comdata.length() > 0)
  {
    if(comdata[comdata.length() - 1] == '#') {
       int command = comdata.substring(0,comdata.length() - 1).toInt();
      //bt_maximum = command;
      Serial.println(comdata);
      switch(command) {
        case 1:
          bt_maximum = 60;
          break;
         case 2:
         bt_maximum = 75;
         break;
         case 3:
         bt_maximum = 95;
         break;
         case 4:
         bt_maximum = 115;
         break;
         case 5:
         bt_maximum = 150;
         break;
         default:
         bt_maximum = 0;
      }
    }
  }

}
