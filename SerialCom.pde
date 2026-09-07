//int comspeed = 115200;   //通信速度 [4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200]
int comspeed = 1000000;    //通信速度
int noupdate_time = 0;

void Serial_port(int n) {
  // 既に接続されていれば、切断して新しい選択項目は、index n で接続する  未使用
  // if ( myPort != null ) myPort.stop();
  
  try{
    myPort = new Serial(this, portList.get(n), comspeed);  // Connect to the selected port
    println(portList.get(n));
    setLock(cp5.getController("Serial_port"), true);       // Lock
    surface.setTitle(portList.get(n)+": "+ fileN + ": Monitoring multiple vital signs");  
  }
  catch(Exception e) {      // Error occur
    println(e);
    println("failed");

    int m1=e.toString().indexOf(":");
    String errm =e.toString().substring(m1+2);
    println(errm);

    Object[] options = { "OK", "CANCEL" };
    int r = JOptionPane.showOptionDialog(null, errm +"\r\nClick OK to continue. Please select another port.\r\nClick Cancel to exit", "Warning",
             JOptionPane.DEFAULT_OPTION, JOptionPane.WARNING_MESSAGE,
             null, options, options[0]);

    if ( r == 0 ) {         // OK, continue
    }  
    else if ( r == 1 ) {
      exit();
    }  
  }
}

boolean readFromSerial()
{
  // シリアルポートが空なら何もしない
  boolean updateData = false;
  if (myPort.available() > 0){
    // シリアルから1行読み込み
    String str = myPort.readStringUntil('\r');
    if (str != null)
    {
      str = trim(str);
      if (str.length()==37 || str.length()==25) {     
        timestamp=int(unhex(str.substring(0, 4)));   // timestamp
        Tempdata=int(unhex(str.substring(4,7)));     // Temp data(0,3) 4,7
        data[0]=int(unhex(str.substring(7,10)));     // Red data(3,6) 7,10
        data[1]=int(unhex(str.substring(10,13)));    // IR data(6,9) 10.13
        
        data[0] = (data[0] < 4000)? data[0]: 0;
        data[1] = (data[1] < 4000)? data[1]: 0;
        
        for( int i = 0; i < a_numData; i++ ) {
          a0_data[i]=int(unhex(str.substring(4*i+13, 4*(i+1)+13)));        //ax(9,13) ay(13,17) az(17,21);
          if( a0_data[i]>32767 ){
            a0_data[i] = a0_data[i]-65536;
          }
        }
        a_data[0] = a0_data[1];
        a_data[1] = a0_data[0];
        a_data[2] = - a0_data[2];
        
        if( str.length()==37 ) {                     // Gyro data
          for( int i = 0; i < g_numData; i++ ) {
            g_data[i] = int(unhex(str.substring(4*i+21+4, 4*(i+1)+21+4))); //gx(21,25) gy(25,29) gz(29,33);
            if( g_data[i]>32767 ){
              g_data[i] = g_data[i]-65536;
            }
          }
        }
        if( timestamp != noupdate_time )
        {
          updateData = true;
          noupdate_time = timestamp;
        }
      }
    }
  }
  return updateData;
}
