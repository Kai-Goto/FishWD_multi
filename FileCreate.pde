PrintWriter file;       // CSV file
PrintWriter file2;      // CSV file 1sec
//PrintWriter file_1s;  

private static boolean checkBeforeWritefile(File file){
  if( file.exists() ){
    if( file.isFile() && file.canWrite() ){
      return true;
    }
  }
  return false;
}

void FileSetup(){
  Start_h = hour();  
  Start_m = minute();
  Start_s = second();
  fileN += "-"+ nf(Start_h,2)+ nf(Start_m,2)+ nf(Start_s,2);
  baseTime = Start_h*3600+Start_m*60+Start_s;
  // File creation
  String fileName = createFileName();
  String fileName2 = createFileName2();
  file_1s = createFileName_1s();
  
  file = createWriter(fileName);
  file2 = createWriter(fileName2);
      
  svtext = "Time[s],RedDC,IRDC,Temp_ad,move_ad,Pulse Rate,Breath Rate,Temp,a_sum_ave_s_g,active_d,angle_ud90,timer_flag,PC_time[s],update_rate[/s],update_flag"+'\n';
  file_println(file_1s,svtext);
   
  file.print("Time[ms],BLE_time[ms],No.,Red,IR,IR_BR(filtered),IR_HR(filtered),asum_HR(filterd),bp1,bp2,brt,HR(old),BR(old),HR(hist),BR(hist),,timestamp,,Temp[degreeC],Tempdata,Timer,");
  file.println("AccelData0,AccelData1,AccelData2,AccelDataNoG0,AccelDataNoG1,AccelDataNoG2,MotionFlag_t0,MotionFlag_t1,MotionFlag_t2,gx,gy,gz,AccelDataSum"); 
  file2.print("second_timer[s],timer_flag,RedDC,IRDC,Temp,Pulse Rate,Breth rate,a_sum_ave[g/s],active_d,angle_ud0, angle_rl0,angle_flag,Red97,IR97,Rdc,RdcD,spoD,sposd,spoDave,fft_flag,");
  file2.println("bp,bp1,bp2,fc0,fc_L,fc_H,brt,fbrtc,");
}

String createFileName() {
  String fileName = "/data/" + fileN + ".csv";
  return fileName;
}

String createFileName2() {
  String fileName= "/data/"+fileN + "-2data.csv";
  return fileName;
}

String createFileName_1s() {
  String fileName= "/data/"+ fileN + "-1s.csv";
  return fileName;
}
