// 2025/11/4  Modify: flag detect Timer 
// 2023/5/10  Change from 20230412 :ax -> ay, ay -> ax, az -> -az
// 2022/2/13  BLE change RN4020 -> nRF(Timestamp,Red, IR, Temp, accel,gyro)

import java.nio.file.Path;                // File copy
import java.nio.file.Paths;               // File copy
import java.nio.file.Files;               // File copy
import java.nio.file.StandardCopyOption;  // File copy
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.*;
import javax.swing.*;                     // Messagebox
import processing.serial.*;
import controlP5.*;

ControlP5  cp5;  
DropdownList dropdown;
ScrollableList portscroll;
//Toggle toggle;
Serial myPort=null;
List<String> portList;
JPanel panel = new JPanel();                                    // Dialogbox
BoxLayout layout = new BoxLayout( panel, BoxLayout.Y_AXIS );    // Dialogbox layout

//int refavetime = 2*60;         // [min] ⇒ DEMO 60min
int HRfc_avetime = 30;         // [min] fcutoff calculating time default 30 min (3 to 30);
long baseTime;
int h,m,s;

String fileName_1s, file_1s, file_cal;    // Save file name
String fileN =  nf(year(), 2) + nf(month(), 2) + nf(day(), 2) ;
String Error = "";
String ErrorPPG = "";
String Errorangle = "";
String Errorupdate = "";
int Errorupdate_flag = 0;
String svtext;
String namePulldown = "Device name=?";  
String nameportpdwn = "Serial Port?";  

PrintWriter file_ave;           // Ave time file
PrintWriter file_adj;           // Ajust time file
String dirPath;                 // Absolute path of higher hierarchy

void file_println(String filename, String stext){
  filename = sketchPath("") + filename; 
  try {
    FileWriter fw= new FileWriter(filename, true); 
    fw.write(stext);
    fw.close();
  } catch (Exception ex) { 
    ex.printStackTrace();
  }
}

// Serial port
final int SampleRate = 60;      // Update rate
final int BLERate = 50;         // 20ms interval

int Device = 0;                 // Select Device ID
String Devices;                 // Obtained from dialog box
String csvfile;                 // Unused

// Average time[min]
int avetime_sl = 0;             // Unused
float sampling_count_time = 0;  // Unused

// Time adjustment
int Start_h, Start_m, Start_s;  // Start time
int adm_h, adm_m, adm_s;        // Dosing time for DCref 2hours before dosing (calibration 5mins before the concentration decreases)
int time_diff;                  // Start time-Dosing time
float time_old = 0;

// FFT timer flag for Body movement removal
float fft_ts = 10000.0;         // 10sec FFT Body movement removal time !Non-changeable!
float ffta_ts = 0.03;           // [g] 500/2^14; Composite acceleration threshold for FFT !2000 NG!
float active_ts = 0.03;         // [g] 500/2^14; Composite acceleration threshold for Activity amount 
float fft_wait_time = 0.0;      // FFT wait timer
int fft_flag = 0;               // Not moving=0, moving=1 Replaced pulse wave with composite acceleration
int angle_flag = 0;             // Not moving=0, moving=1 Attitude angle flag

// Composite acceleration threshold{ strong, medium, week }
float Threshold[] = {2000.0, 3000.0, 6000.0}; // Use flag_m ![2]=6000!

// Activity amount 
float active_d, active_ave, active_sum;
int active_num;

// SpO2
// Referece DC level
int C_time = 0, C_enable=0, C_timer = 0 ;   // C_time:Calibration in progress C_enable=1:Calculated DCRef SpO2 active
float Redref = 2057;            // Reference for Red
float IRref = 1588;             // Reference for IR
float RedDC_ad, IRDC_ad, RedDC_ad_old, IRDC_ad_old;  // Adjusetment(use noise removel) Cancel each other out
float Red97, IR97;              // RefDC
float Red97_sum, IR97_sum;      // for RefDC
int Red97_num = 0, IR97_num = 0;// for RefDC
float Rdc_def;
float Rdc = 0.0, RdcD = 0.0;    // (IRDC/IR97)/(RedDC/Red97) RdcD display(Tempad_flag On)
float[] RdcT = new float[2];    // Tempad_flag selected ON/OFF
float move_ad_ts = 0.04;        // [g]
float Temp_ad, move_ad;         // Rdc Correction coefficient
float cyc_time=1000, cyc_timer; // [ms] For calculating waveform p-p. Timer for respiratory cycles of 10 bpm or more
int Tempad_flag = 0;                // Temperature compensation ON/OFF

// Pulse wave amplitude for respiration cycle noise reduction
int Red_max = 0, Red_min = 4000, Red_amp;
int IR_max = 0, IR_min = 4000, IR_amp;
float RedDC_cyc, RedDC_c_sum, RedDC, RedDC_sum, RedDC_old;
float IRDC_cyc, IRDC_c_sum, IRDC,IRDC_sum, IRDC_old;
int RedDC_c_num, IRDC_c_num, RedDC_num, IRDC_num; 
int DCamp_noise = 100;          // Pulse wave amplitude threshold 50 or 1000(invalid)

// spo noise reduction 10sec SD
float sposd_time =10000, sposd_timer ; // 10s spo SD calculation time
int spon_num=11;                       // SD Sample count
int spony=0;
float[] spon = new float[spon_num];
float[] spon_arr = new float[spon_num];
float sposdn_sum = 0, sposdn_ave = 0;
float sposdn = 0.0;
int spony_f = 0;
float[] spon_f = new float[spon_num];
float sposdn_sum_f = 0, sposdn_ave_f = 0;
float sposdn_f = 0.0;

// SpO2 Conversion formula  SpO2 = Spo_a * (R- Spo_c) + Spo_b
int SpoID = 0;                  // Select ID
float[][] Spo_k; //<>//
String [] deviceID;

float[] spo = new float[2];
float spoD = 0;
float spoDa = 0;
int gwp = 0;

// Data storage parameters & array **************************************************************************************
// BLE received data
int numData = 3; 
int a_numData = 3;
int g_numData = 3;
int[] data = new int [numData];       
int[] a0_data = new int [a_numData];         // Ver2-> Ver3
int[] a_data = new int [a_numData];          // Acceleration data
int[] g_data = new int [g_numData];          // Gyro data
int Tempdata;                                // Temperature data      
int timestamp=0, timestamp_old=0, stamp_cnt; // BLE timestamp 0 to 65535 (2^16-1)
int firstdata=0;                             // for BLE time adjustment

int data_w = 590;
int data_pos;                                // for Waveform

// File Save
int ts=0, ts_time=0,ts_old=0;                // ts:PC time, ts_time:BLE time 
int file_No;                                 // gwp No.
int[] file_D = new int [numData];            // Row Data
float[] file_Dfill1 = new float [numData];   // Filtered Data
float[] file_Dfill2 = new float [numData];   // Filtered Data
float[] file_Dfill3 = new float [numData];   // Filtered Data

// Temperature *********************************************************************************************************
float T_Data_f = 0;
float T_Data_f_old = 0;
float Temp_k = 0.1;                          // Low-pass filter k parameters
float Temp;

// Biquad Filter *******************************************************************************************************
// float SamplingFreq = 50.0;                // Sampling frequency[Hz]
float ti = 1.0/BLERate;
// Cutoff frequency for Data smoothing 
float fc_ave_time = HRfc_avetime*60*1000.0;  // [ms] Heart rate 30min average for BPF fc
float fc_meas_timer;
int fc_meas_flag;                            // Addition flag add=0, calculation=1
float fc0 = 1.31;                            // 400pbm initial Cutoff freq.[Hz] for Heart rate
float fc = 1.31;                             // 400pbm initial Cutoff freq.[Hz] for Heart rate
float fbrtc = 1.67;                          // 100bpm initial Cutoff freq.[Hz] for respiratory rate
float fc_H = 10.0;                           // Cutoff freq. upper limit [Hz] for Heart rate
float fc_L = 4.3;                            // Cutoff freq. lower limit [Hz] for Heart rate
float fc_L0 = 4.3;                           // Heart rate freq. lower limit 4.66 

// Heart rate & Respiratory rate **************************************************************************************
int DATASIZE = 512;                          // fft data size 2^N
float [] x = new float[DATASIZE];            // for graph x:time
float [] y1 = new float[DATASIZE];           // for graph y:voltage
float [] y2 = new float[DATASIZE];           // for graph y:voltage
float [] y3 = new float[DATASIZE];           // for graph y:voltage
// FFT
int fftdatasize = DATASIZE;
FFT fft = new FFT(fftdatasize);
float[] fftdata1r = new float[fftdatasize];  // data1 Real part
float[] fftdata1i = new float[fftdatasize];  // data1 Imaginary part
float[] fftdata2r = new float[fftdatasize];  // data2 Real part
float[] fftdata2i = new float[fftdatasize];  // data2 Imaginary part
float[] fftdata3r = new float[fftdatasize];  // data3 Real part
float[] fftdata3i = new float[fftdatasize];  // data3 Imaginary part
float[] fftdata1 = new float[fftdatasize];   // data1 absolute value
float[] fftdata2 = new float[fftdatasize];   // data2 absolute value
float[] fftdata3 = new float[fftdatasize];   // data3 absolute value
int ima = 0;
float imaa1 = 0.0, imaa2 = 0.0;
float ftdma = 0.0;
float bp=0.0, bp1 = 0.0, bp2 = 0.0;
int imb = 0;
float imbb = 0.0;
float ftdmabr = 0.0;
float brt = 0.0;

// Moving average 1min
int max, max_i;
int Nma = 10;                                // SpO2 data count 10sec
int Nma_my = 3000;                           // Ave sample num for HR 60×50 about 1min
int Nma_kky = 3000;                          // Ave sample num for BR 60×50 about 1min
int spoy = 0;
int my1 = 0, my2 = 0, my4 = 0;
int kky1 = 0, kky2 = 0, kky4 = 0;
float[] spoDave = new float[Nma];            // SpO2 for display
float[] my = new float[Nma_my];
float[] kky = new float[Nma_kky];
int[] myc = new int[Nma_my];
int[] kkyc = new int[Nma_kky];
int[] count = new int[10];
int[] county = new int[50];
float mysumt= 0.0, myavet = 0.0, mysumtfc= 0.0, myavetfc = 0.0;
float kkysumt= 0.0, kkyavet = 0.0, kkysumtfc= 0.0, kkyavetfc = 0.0;
float kkyavetfc_old = fbrtc*60;
float spoDsum = 0.0;
int spoDc = 0;
float mysum = 0.0, kkysum = 0.0;
float myave = 0.0, kkyave = 0.0;
int bo = 0, bot = 0, botfc = 0;
int bro = 0, brot = 0, brotfc = 0;

// Data smoothing using a histogaram
int mode = 20;                               // [bpm] Mode rage BR
int bp_mode = 50;                            // [bpm] Mode rage HR
int bpth_L0 = 44 ;                           // HR FFT lower Min(fixed)
int bpth_H0 = 110;                           // HR FFT upper Max(fixed)
int bpth_L = 44;                             // HR FFT lower 
int bpth_H = 110;                            // HR FFT upper
int bpth_La = 44;                            // HR FFT lower
int bpth_Ha = 110;                           // HR FFT upper
int bp_L = 30;                              // HR FFT upper

float a_angle = 1.2;                         // HR filter magnification correction based on attidude angle
float a_arbig = 1.4;                         // HR filter magnification correction based on a_data_flag[2]

// Exponential moving average ************************************************************************************
float a_data_sum  = 0.0;                     // Resultant acceleration (absolute value)
float a_data_sum_g  = 0.0;                   // [g] 
float alpha = 0.8;                           // filter coefficient 
float[] gravity = new float [3];
float[] a_data_no_g = new float [3];
float[] a_data_ts = new float[3];
float[] a_data_sum_ts = new float[3];
int[] a_data_time = new int[3];              // Timer
int a_data_time_ts = 3000;                   // [ms] Timer threthold
int[] a_data_flag = new int[3];              // Moving flag

float a_data_sum_ave = 0.0;                  // Ave Resultant acceleration for SpO2 SD
int a_data_num = 0;                          // Ave Resultant acceleration for SpO2 SD
float a_data_sum_c = 0.0;                    // 
float a_data_sum_ave_s = 0.0;                // Ave Resultant acceleration 1s
float a_sum_ave_s_g = 0.0;                   // Ave Resultant acceleration 1s [g] 
int a_data_num_s = 0;                        // Ave Resultant acceleration 1s
float a_data_sum_s = 0.0;                    // Ave Resultant acceleration 1s
float angle_ud, angle_rl, angle_ud90, angle_rl90, angle_ud90_LPF; // Attitude angle head ud=+, right side up rl=+
String angle_ud0 = "", angle_rl0 = "";       // Attitude angle at Resultant acceleration < 500
float motionS_sum = 0.0, motionS_ave = 0.0;  // Motion sensor test
int motionS_num = 0;

float sleep_time;                            // Standing time
float sleep_counter;
float f_sleep_mave, sleep_mave = 0.0;
int delay_time = 0;                          // Delta BLE time (timestamp)
int ts_delay_time = 0;                       // Delta PC time

// Average timer for Resultant acceleration & Temperature 1min
int meas_timer;                           
int meas_flag;                            
int ave_time = 60000;                        // [ms] 1min
float temp_sum1m = 0.0;
float temp_ave1m = 0.0;
int temp_num1m = 0;
//********************************************************************************************************************************************

// Graph design parameter ****************************************************************************************
final int line_graph_w = 360;      // Width of pulse wave graph [dot = display sample num]
final int wideline_graph_w = 180;  // Width of the magnified pulse wave graph[dot = display sample num]
final int wideline_graph_h = 60;  // Height of the magnified pulse wave graph
final int data_graph_w = 360;      // Width of data graph [dot]
final int data_graph_h = 180;      // Height of data graph [dot]
final int vallabel_w = 40;         // Width of the numerical display for the y-axis auxiliary line[dot]
final int vallabel_h = 30;         // Width of the numerical display for the x-axis auxiliary line[dot]
final int valmargin_w = 10;        // Left and right margins of the graph area[dot]
final int valmargin_h = 10;        // Top and bottom margins of the graph area[dot]
final int label_w = 700;           // Position of the average value display label[dot]
final int label_h = 30;            // Position of the average value display label[dot]

final float wide_rate = 1.0;

// Height of pulse wave graph [dot]
final int line_graph_h = data_graph_h*2 + valmargin_h - vallabel_h;
final int graph_widedata_max = int(wideline_graph_h/2/wide_rate);
final int graph_widedata_min = int(-wideline_graph_h/2/wide_rate);
// Width of Screen size[dot]
final int screen_w = wideline_graph_w+line_graph_w + data_graph_w + vallabel_w*3 + valmargin_w*2 + 200;
// Height of Screen size[dot]
final int screen_h = data_graph_h*3 + vallabel_h + valmargin_h*3;


final float max_data_val = 3750.0f;     // Maximum data
final float a_max_data_val = 16384.0f;  // Maximum acceleration data
final boolean signed_data = false;      // minus data ?
final int num_axuline = 5;              // auxiliary line num x-axis
final int num_axuline_wide = 6;         // auxiliary line num x-axis for magnified pulse wave 
final int num_axuline_spo = 4;          // auxiliary line num x-axis forSpO2
final int num_axuline_pulse = 4;        // auxiliary line num x-axis for HR
final int num_axuline_breath = 4;       // auxiliary line num x-axis for BR
final int num_axuline_temp = 4;         // auxiliary line num x-axis for Temp
final int num_axuline_move = 4;         // auxiliary line num x-axis for Activity amount

final float graph_time = 1.5f;          // time magnification
final float graph_spo_min = 50.0f;      // SpO2 lower limit
final float graph_spo_range = 50.0f;    // Spo2 data width
final float graph_pulse_min = 200.0f;   // HR lower limit
final float graph_pulse_range = 400.0f; // HR data width
final float graph_breath_min = 0.0f;    // BR lower limit
final float graph_breath_range = 200.0f;// BR data width
final float graph_temp_min = 20.0f;     // Temp lower limit
final float graph_temp_range = 20.0f;   // Temp data width

// Number of auxiliary lines (Signed or not)
final int num_net_axuline = (signed_data? 2: 1) * num_axuline;
// The index of the auxiliary line where Y=0.0
final int main_axis = num_axuline;
// Data range considering (the data is signed or not)
final float plotarea_range = (signed_data? 2.0f: 1.0f) * max_data_val;
// Acceleration data range
final float a_plotarea_range = 2.0f * a_max_data_val;
final float as_plotarea_range = 30000.0;
// Left coordinate of the pulse wave graph plotting area
final int line_graph_x =wideline_graph_w+vallabel_w*2;
// Left coordinate of the plotting area of the magnified pulse wave graph 1
final int wideline_graph1_x = vallabel_w;
// Left coordinate of the plotting area of the magnified pulse wave graph 2
final int wideline_graph2_x = vallabel_w;
// Left coordinate of the three data graph plotting areas on the right
final int right_data_graph_x = line_graph_x+line_graph_w + vallabel_w;
// Left coordinates of the data graph plotting area in the lower left
final int left_data_graph_x = line_graph_x+line_graph_w - data_graph_w;
// Upper coordinate of the pulse wave graph plotting area
final int line_graph_y = valmargin_h;
// Upper coordinate of the plotting area of ​​the magnified pulse wave graph 1
final int wideline_graph1_y = valmargin_h;
// Upper coordinate of the plotting area of ​​the magnified pulse wave graph 2
final int wideline_graph2_y = valmargin_h*2+wideline_graph_h;
// Top coordinates of the plotting area for the SpO2 graph (upper right).
final int spo_graph_y = valmargin_h;
// Top coordinate of the pulse graph (center right) drawing area
final int pulse_graph_y = data_graph_h + valmargin_h*2;
// upper coordinates of the drawing area of the breath graph (bottom right)
final int breath_graph_y = data_graph_h*2 + valmargin_h*3;
// Top coordinates of the plotting area of the temp graph (bottom left)
final int temp_graph_y = breath_graph_y;

// Graph colors
final int graph_color[][] = {
  { 0, 255, 0 }, {255, 0, 0 }, { 0, 255, 0 }, { 255, 0, 0 }, { 0, 255, 0 }, { 255, 0, 0 }
};

final int a_graph_color[][] = {
  {222, 82, 133}, {240, 230, 140}, {65, 105, 225}
};

final int num_bar = 2;             // Number of numerical bars
final int bar_graph_w = 10;        // Width of the bar graph plotting area
final int bar_size = 70;           // Width of the numerical bar [%]
// Bar width
final int bar_w = bar_size * bar_graph_w / (100 * num_bar);
// Height coordinate where Y=0.0
final int bar_y = (signed_data? ((line_graph_y+line_graph_h)/2): (line_graph_y+line_graph_h));
// Left coordinate of the bar graph plotting area
final int bar_graph_x = (line_graph_x + line_graph_w);

//*****************************************************************************************************************************

// Ring buffer for graph display
int graph_write_pos;      // pulse waves
int widegraph_write_pos;  // pulse waves
int graph_write_possp;    // others
int[][] graph_data = new int[numData][line_graph_w]; 
int[][] widegraph_data = new int[numData][wideline_graph_w]; 
float[] a_graph_data = new float[line_graph_w];
int[] a_graph_datasp = new int[line_graph_w];
float[][] graph_datasp = new float[4][line_graph_w];

float[][] yout1 = new float[3][line_graph_w];
float[][] yout2 = new float[3][line_graph_w];
float[][] yout3 = new float[3][line_graph_w];
//*****************************************************************************************************************************

int btnWidth = 160;
int btnHeight = 40;
int cp_positionX = wideline_graph_w+line_graph_w + data_graph_w + vallabel_w*3 + valmargin_w*2;

//*****************************************************************************************************************************
int update_nn = 1;
int update_ncounter = 0;

int file_timer = 0;
int graph_timer = 0;

int timer_flag = 0;
int ave_flag =1;
int fontSize = 16;
  
// Initialization
void settings() {
  dirPath = sketchPath();
  size(screen_w, screen_h);       // Create window
}

void setup(){ 
  surface.setTitle("Wearable device for monitoring multiple vital signs");  
  frameRate(SampleRate);          // Set the screen refresh frequency
  PFont font = createFont("Meiryo", 50);
  textFont(font);
  //surface.setResizable(true);   // Window resize 
  
  panel.setLayout(layout);        // Apply layout to panel
  panel.add( new JLabel( "Serial Port Error" ) );    // Add the message content as a string component to the panel
  
  ArrayInit();
  FileSetup();
  delay(20);
  
  ControlFont tfont = new ControlFont(createFont("Arial",fontSize));
  cp5 = new ControlP5(this);
  portList = Arrays.asList(Serial.list());
  portscroll = cp5.addScrollableList("Serial_port",cp_positionX,10,btnWidth, 120)  // position
               .setFont(tfont)
               .setBarHeight(20)
               .setItemHeight(30)
               .addItems(portList)
               .setCaptionLabel(nameportpdwn);
  portscroll.getCaptionLabel()
      .toUpperCase(false)
      .getStyle().marginTop = 4;   // Character position adjustment
  portscroll.getValueLabel()
      .toUpperCase(false)
      .getStyle().marginTop = 4;   // Character position adjustment
      
  String[] lines = loadStrings("\\ID\\deviceID.csv");           // ID Conversion formula
  int rowCount = lines.length;
  int colCount = split(lines[0], ",").length;
  println(rowCount);
  println(colCount);
  deviceID = new String[rowCount];
  Spo_k = new float[rowCount-1] [colCount-1];
  for (int datacount = 1; datacount < rowCount; datacount++) {  // Data starts from the second row
    println(lines[datacount]);
    String[] cols= split(lines[datacount], ',');
    deviceID[datacount-1]=trim(cols[0]);
    for(int j=1; j < colCount;j++){ 
      Spo_k[datacount-1][j-1]=float(trim(cols[j]));
    }
  }
  
  dropdown = cp5.addDropdownList(namePulldown)
               .setPosition(cp_positionX, 140)  // position
               .setSize(btnWidth, 120)          // Width and height when the menu is fully extended
               .setBarHeight(20)                // Height of the top box
               .setItemHeight(30)               // Set the height of the selection box
               .setFont(tfont)
               .setColorForeground(#ffbb00);    // Mouse weight background
  dropdown.getCaptionLabel()
      .toUpperCase(false)
      .getStyle().marginTop = 4;
  dropdown.getValueLabel()
      .toUpperCase(false)
      .getStyle().marginTop = 4;
 
  // Add CSV content to dropdown
  for (int i = 0; i < rowCount-1; i++) {
    dropdown.addItem(deviceID[i], i);           // Label & value(ID)
  }            

/*  cp5.addToggle("toggle")
     .setLabel("ON   OFF")
     .setPosition(cp_positionX, 250)
     .setValue(true)
     .setSize(40, 20)
     .setMode(ControlP5.SWITCH);  
  setLock(cp5.getController("toggle"), true); */
  
  cp5.addButton("Calibration")
      .setSize(btnWidth, btnHeight)
      .setPosition(cp_positionX,300)
      .setColorForeground(#ffbb00)
      .getCaptionLabel().toUpperCase(false)
      .setFont(tfont);

  cp5.addButton("Dosing")
      .setSize(btnWidth, btnHeight)
      .setPosition(cp_positionX,360)
      .setColorForeground(#ffbb00)
      .getCaptionLabel().toUpperCase(false)
      .setFont(tfont); 
      
  cp5.addButton("Close")
      .setSize(btnWidth, btnHeight)
      .setPosition(cp_positionX,540)
      .setColorForeground(#ffbb00)
      .getCaptionLabel().toUpperCase(false)
      .setFont(tfont);
         
  ts_time = millis();      // Data update time
  file_timer = ts_time;
  meas_timer = ts_time;
  fc_meas_timer = ts_time;
  cyc_timer = ts_time;
}

void controlEvent(ControlEvent event) {
  // Check the events in the pull-down menu
  boolean is_controller = event.isController();
  boolean is_dropdown = event.getName().equals(namePulldown);
  if (is_controller && is_dropdown) {
    Device = (int) event.getController().getValue(); // Get the index of the selected item
    setLock(cp5.getController(namePulldown), true);  // Botton Lock
    println("Selected device number: " + Device);
    Devices = deviceID[Device]; 
    move_ad_ts = 0.04; 
    SpoID = Device;
    Rdc_def = (99-Spo_k[SpoID][3])/Spo_k[SpoID][2];
    println("Device=" + Device + ", SpO_a=" + Spo_k[SpoID][0] + ", SpO_b=" + Spo_k[SpoID][1]+ ",SpO_al=" + Spo_k[SpoID][2] + ", SpO_bl=" + Spo_k[SpoID][3]+ ", move_ad_ts=" + move_ad_ts );
    println("99%ad=" + Rdc_def);
  }
}

// Medication time
public void Dosing() {
  if( timer_flag == 0 ){
    timer_flag = 1;                             // only once
    setLock(cp5.getController("Dosing"), true); // Botton Lock
    adm_h = hour();
    adm_m = minute();
    adm_s = second();
    cp5.getController("Dosing").setColorBackground(color(#0000ff));
    cp5.getController("Dosing").setCaptionLabel("Dosing: "+ nf(adm_h,2)+ ":"+  nf(adm_m,2) +":"+  nf(adm_s,2));
    time_diff = ((adm_h*60*60+adm_m*60+adm_s))-(Start_h*60*60+Start_m*60+Start_s); //sec
    //println("Timediff=" + time_diff);
    //println("Dosing Time:"+ adm_h+ ":"+  adm_m +":"+  adm_s);
    
    ControlFont tfont = new ControlFont(createFont("Arial",fontSize));
    cp5.addButton("Analysis")
     .setPosition(cp_positionX,420)
     .setSize(btnWidth, btnHeight)
     .setColorForeground(#ffbb00)
     .getCaptionLabel().toUpperCase(false)
     .setFont(tfont); 
  }
}

// Calibration ON/OFF
public void Calibration(){
  C_enable =1;
  if( C_time == 0 ){         // Measurement ON = 1
    C_time = 1;
    C_timer = ts;
    setLock(cp5.getController("Calibration"), true); 
    cp5.getController("Calibration").setColorBackground(color(#ff0000));
  } else {  
    C_time = 0;
  }
}

public void Analysis() {
  println(dirPath);
  file_cal = fileN + "-"+ Devices + "-"+ time_diff + "-"+ ave_flag + ".cal";
  Path p1 = Paths.get(dirPath + file_1s);
  Path p2 = Paths.get(dirPath+"/cal/"+file_cal);

  try{
    Files.copy(p1, p2,StandardCopyOption.REPLACE_EXISTING); // File copy for analysis
    cp5.getController("Analysis").setColorBackground(color(#0000ff));
    ave_flag ++;
  }catch(IOException e){
    System.out.println(e);
  }
}

public void Close() {
  if( timer_flag == 1 ){
    Analysis();
  }
  setLock(cp5.getController("Close"), true); // Botton Lock
  file.close();
  file2.close();
  exit();
}

public void toggle(boolean theFlag) {
  if( theFlag == true ){
    Tempad_flag = 1; //Temp_ad ON
    println("Temp_ad ON");
  } else {
    Tempad_flag = 0; //Temp_ad OFF 
    println("Temp_ad OFF");
  }
}

void setLock(Controller theController, boolean theValue) {
  theController.setLock(theValue);
  if(theValue) {
    theController.setColorBackground(color(#ffbb00));
  } else {
    theController.setColorBackground(color(255));
  }
  theController.setMouseOver(false);
  theController.setLock(theValue); 
}

// Main
void draw(){
  background(0);                            // Display clear
  
  if( myPort != null ){ 
    timestamp_old = timestamp;
    boolean updateData = readFromSerial();  // Recieved data from BLE
 
    ts = millis();                          // Time update
    // Stored in ring buffer
    if ( updateData ){
      ts_delay_time = ts - ts_old;          // Delta PC time
      if( update_rate < 40 ){               // Data reception count per 1 sec (=50)
        if( Errorupdate_flag == 0 ){
          Errorupdate_flag = 2;             // Update error poor reception
        }
      }
      ts_old = ts;                          // for Delay time
 
      for (int i = 0; i < numData; i++) {
        graph_data[i][graph_write_pos] = data[i];
        widegraph_data[i][widegraph_write_pos] = int(file_Dfill2[i]);
      }
    }
      
    if( timestamp != timestamp_old ){       // *1 Data update
    
      if ( timestamp > timestamp_old ) {    // Delta = plus
        stamp_cnt = timestamp - timestamp_old ;
      }else{                                // Delta = minus
        stamp_cnt = (timestamp - timestamp_old) + 65536 ;
      }
      
      if( firstdata == 0 ){                 // Initial time set
        ts_time = ts;
        file_timer = ts_time;
        meas_timer = ts_time;
        fc_meas_timer = ts_time;
        cyc_timer = ts_time;
        firstdata = 1;
      }else{                                // timestamp 0 to 65535=21.8min
        if( timestamp == 0 ){
          if( timestamp_old == 65535 ){     // Normal countup
            delay_time = 20;
          }else{                            // Data drop & reset   
            delay_time = ts_delay_time;     // PC delay time
            Errorupdate_flag = 1;           // Reset occur
          }
        }else{
          if( stamp_cnt < 1000){            // Normal & Minor data loss  
            delay_time = stamp_cnt * 20;
          }else{                            // Data loss
            delay_time = ts_delay_time;            
          }
        }
        
        if( ts_delay_time >= 65535*20 ){    // Long-term data loss occerred(Battery dead)
          delay_time = ts_delay_time;
          Errorupdate_flag = 3;
        }      
        ts_time += delay_time;
      }
     
      data_pos = (data_pos < data_w-1)? data_pos+1: 0;
      graph_write_pos = (graph_write_pos < line_graph_w-1)? graph_write_pos+1: 0;
      widegraph_write_pos = (widegraph_write_pos < wideline_graph_w-1)? widegraph_write_pos+1: 0;
    
      // Average timer flag 
      if( ts_time - meas_timer < ave_time ){ 
        meas_flag = 0;
      }else{                                
        meas_flag = 1;
        meas_timer += ave_time;
        if( ts_time > meas_timer ){
          meas_timer = ts_time;
        }
      }
      
      // fc average timer flag
      if( ts_time - fc_meas_timer < fc_ave_time ){ 
        fc_meas_flag = 0;
      }else{
        fc_meas_flag = 1;
        fc_meas_timer += fc_ave_time;
        if( ts_time > fc_meas_timer ){
          fc_meas_timer = ts_time;
        }
      }

      // Body temperature ********************************************************************************
      if ( Tempdata!=0 ) {              // Low pass filter
        T_Data_f = (1-Temp_k)*T_Data_f_old + Temp_k*Tempdata;
        T_Data_f_old = T_Data_f;
      } else {
        T_Data_f = 0;
      }
      if ( T_Data_f!=0 ) {
        Temp = 254.26-36.66*log(T_Data_f*3.6/3.3/4.0);
      } else {
        Temp = 0;
      }
      if( Temp > 50 ){                  // Abnormal data removal
        Temp=0;
      }

      // Motion detection *********************************************************************************
      // High Pass Filter (Gravity acceleration removal)by Android SensorEvent
      for (int i = 0; i < 3; i++) {
        gravity[i] = alpha*gravity[i]+(1-alpha)*a_data[i];  // LPF
        a_data_no_g[i] = a_data[i]-gravity[i];              // HPF = Row data - LPF data
      }

      // Resultant acceleration (After removing gravitational acceleration)
      a_data_sum = sqrt(a_data_no_g[0]*a_data_no_g[0]+a_data_no_g[1]*a_data_no_g[1]+a_data_no_g[2]*a_data_no_g[2]);
      a_data_sum_g = a_data_sum/pow(2, 14);
      data[2] = int(a_data_sum);                            // Composite acceleration data excluding gravity
      a_graph_data[graph_write_pos] = a_data_sum;
      graph_data[2][graph_write_pos] = data[2];
    
      // Attitude angle calculation (x, y swapped data)
      angle_ud = atan2(a_data[1],a_data[2])*180.000/PI;
      angle_rl = atan2(a_data[0],a_data[2])*180.000/PI;
      angle_ud90 = atan2(a_data[1],sqrt(a_data[0]*a_data[0]+a_data[2]*a_data[2]))*180.000/PI;          // ±90-degree
      angle_rl90 = atan2(a_data[0],sqrt(a_data[1]*a_data[1]+a_data[2]*a_data[2]))*180.000/PI;
    
      angle_ud90_LPF = atan2(gravity[1],sqrt(gravity[0]*gravity[0]+gravity[2]*gravity[2]))*180.000/PI; // for ±90-degree posture bars 
    
      // Motion flag for HR filter correction
      for (int i = 0; i < 3; i ++) {
        if ( a_data_sum > a_data_sum_ts[i] ) { 
          a_data_flag[i] = 1;           // Flag on
          a_data_time[i] = ts_time;     // Timwer set
        }else{
          if ( ts_time - a_data_time[i] > a_data_time_ts ) { 
            a_data_flag[i] = 0;
          }
        }
      }
      
      // Motion flag for FFT  IR or a_sum
      if ( a_data_sum_g > ffta_ts ) {   
        fft_flag = 1;                   // Flag on: Active
        fft_wait_time = ts_time;        // Timer set
      }else{
        if (ts_time - fft_wait_time > fft_ts) { 
          fft_flag = 0;                 // HR by IR
        }
      }

      if( a_data_flag[2] == 1 ){        // Large body movements 
        fc = fc0*a_arbig;
      }

      if ( a_data_sum_g <= ffta_ts ) {  // Insert spaces into the CSV file
        angle_ud0 = nf(angle_ud, 0, 3);
        angle_rl0 = nf(angle_rl, 0, 3);
       
        if( abs(angle_ud) >= 30 || abs(angle_rl)>= 60 ){  // Heart rate correction based on posture angle
          fc = fc0*a_angle;
          angle_flag = 1;
        } else {
          fc = fc0;
          angle_flag = 0;        
        }

      } else {                          // Data while stationary
        angle_ud0 = "";                 // ver2 device
        angle_rl0 = "";                 // ver1 device
      }
      
      filter();

      //↑↑↑↑↑↑↑↑↑↑↑↑↑*******************************************************************************************************

      // HR & BR(FFT)↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓**********************************************************************************
      for ( int i = 0; i < fftdata1r.length; i++ ){
        float[] wnd = fft.getWindow();
        fftdata1[i] = sqrt(fftdata1r[i]*fftdata1r[i]+fftdata1i[i]*fftdata1i[i])/fftdatasize*2; 
        fftdata2[i] = sqrt(fftdata2r[i]*fftdata2r[i]+fftdata2i[i]*fftdata2i[i])/fftdatasize*2;
        fftdata3[i] = sqrt(fftdata3r[i]*fftdata3r[i]+fftdata3i[i]*fftdata3i[i])/fftdatasize*2;
        fftdata1r[i] = y1[i] * wnd[i];
        fftdata2r[i] = y2[i] * wnd[i];
        fftdata3r[i] = y3[i] * wnd[i];
        fftdata1i[i] = fftdata2i[i] = fftdata3i[i]=0;
      }
      fft.fft(fftdata1r, fftdata1i);
      fft.fft(fftdata2r, fftdata2i);
      fft.fft(fftdata3r, fftdata3i);
      for ( int i = 0; i < y1.length - 1; i++ ) {
        y1[i] = y1[i+1];  
        y2[i] = y2[i+1];
        y3[i] = y3[i+1];  
      }

      y1[y1.length - 1] = file_Dfill2[1];    // HR by IR BPF
      y2[y2.length - 1] = file_Dfill3[2];    // HR by a_sum BPF
      y3[y3.length - 1] = file_Dfill1[1];    // BR by IR BPF

      ftdma = 0.0;
      ima = 0;
    
      // HR by IR (fftdata1)
      for ( int i =  bpth_L; i < bpth_H; i++ ) {   // 40 to 90 → 48 to 108(×1.2)
        if ( ftdma<fftdata1[i] && fftdata1[i-1]<fftdata1[i] ) {   
          ftdma = fftdata1[i];
          ima = i;
        }
      }
      
      // HR by IR (fftdata1)
      if ( ima > 0 ) {
        int im1 = ima -1;
        int im2 = ima +1;
        imaa1 =ima + (fftdata1[im1]-fftdata1[im2])/(2*(fftdata1[im1]+fftdata1[im2]-2*fftdata1[ima]));
      } else {
        imaa1 = 0;
      }
    
      ftdma = 0.0;
      ima = 0;
    
      // HR by a_sum (fftdata2)
      for ( int i = bpth_La; i < bpth_Ha; i++ ) {     // 40 to 90 → 48 to 108(×1.2)
        if ( ftdma < fftdata2[i] && fftdata2[i-1] < fftdata2[i] ) {
          ftdma = fftdata2[i];
          ima = i;
        }
      }
      if ( ima > 0 ) {
        int im1 = ima -1;
        int im2 = ima +1;
        imaa2 =ima + (fftdata2[im1]-fftdata2[im2])/(2*(fftdata2[im1]+fftdata2[im2]-2*fftdata2[ima]));
      } else {
        imaa2 = 0;
      }
    
      ftdmabr = 0.0;
      imb = 0;
      
      // BR by IR (fftdata3)
      for ( int i = 2; i< 36; i++ ) {                 // 3 to 30 → 3.6 to 36(×1.2)
        if ( ftdmabr < fftdata3[i] && fftdata3[i-1] < fftdata3[i] ) {
          ftdmabr = fftdata3[i];
          imb = i;
        }
      }
      if ( imb > 0 ) {
        int im1 = imb -1;
        int im2 = imb +1;
        imbb = imb + (fftdata3[im1]-fftdata3[im2])/(2*(fftdata3[im1]+fftdata3[im2]-2*fftdata3[imb]));
      } else {
        imbb = 0;
      }

      bp1 = (float) imaa1 * 60 * BLERate / DATASIZE;  // FFT-> bpm HR by IR
      bp2 = (float) imaa2 * 60 * BLERate / DATASIZE;  // FFT-> bpm HR by a_sum
      brt = (float) imbb * 60 * BLERate / DATASIZE;   // FFT-> bpm BR by IR
      
      if( fft_flag == 1 ){                            // Active: a_sum
        bp = 0;
        if( bp2 < 650 && bp2 > bp_L ){
          bp = bp2;
        }
      }else if( fft_flag == 0 ){                      // Stillness 
        bp = 0;
        if( bp1 < 650 && bp1 > bp_L ){
          bp = bp1;
        }
      }

      // HR by IR 1min Mode → Mean 
      if ( bp >= bp_L && bp <= 100.0 ){               // from 202208
        my[my1] = bp;
        myc[my1] = round(bp/bp_mode);     

        if( myc[my1] > 16 ){                          // Mode outlier removal
          myc[my1] = 0;
        } 

        for( int j = 0; j < Nma_my-1; j++ ){
          county[myc[j]] ++ ;
        }
        max=0;
        max_i = 0;
        for( int k=1; k < abs(800/bp_mode); k++ ){
          if( max < county[k] ){
            max = county[k];
            max_i = k;
            county[k]=0;
          }
        }
        mysum = 0;
        bo = 0;
        mysumt = 0;
        bot = 0;

        // HR Mean within the range of Mode value ±1
        for( int i = 0; i < Nma_my-1; i++ ){
          if( (max_i-1)*bp_mode <= my[i] && my[i] < (max_i+1)*bp_mode ) {
            mysumt += my[i];
            bot++;           
          }
          if( my[i] > bp_L ){
            mysum += my[i];
            bo++;
          }
        }
      
        myavet = (bot > 0)? mysumt/bot: 0;
        myave = (bo > 0)? mysum/bo: 0;
           
        my1 = (my1 < Nma_my-1)? my1+1: 0;
      }

      // BR Mean within the range of Mode value ±1 
      if ( brt >= 21.0 && brt <= 200.0 ) {            // from 202208
        kky[kky1] = brt;
        kkyc[kky1] = round(brt/mode);

        if(kkyc[kky1] > 20){                          // Mode outlier removal
          kkyc[kky1] = 0;
        } 

        for( int j = 0; j < Nma_kky; j++ ){
          county[kkyc[j]] ++ ;
        }
        max = 0;
        max_i = 0;
        for( int k=1; k <= 20; k++ ){
          if( max < county[k] ){
            max = county[k];
            max_i = k;
            county[k]=0;
          }
        }

        kkysumt = 0;
        brot = 0;
        kkysum = 0;
        bro = 0;

        for( int i = 0; i < Nma_kky; i++ ){
          if( (max_i-1)*mode <= kky[i] && kky[i] < (max_i+1)*mode ) {
            kkysumt += kky[i];
            brot++;           
          }
          if( kky[i] >= 21.0 ){
            kkysum += kky[i];
            bro ++;
          }
        }
      
        kkyavet = ( brot > 0 )? kkysumt/brot : 0;
        kkyave = ( bro > 0 )? kkysum/bro : 0;

        kky1 = (kky1 < Nma_kky-1)? kky1+1: 0;
      }
      //↑↑↑↑↑↑↑↑↑↑↑↑↑************************************************************************************************

      // SpO2calculation ↓↓↓↓↓↓↓↓↓↓↓↓↓↓******************************************************************************
      // Average in the respiratory cycle
      RedDC_c_sum += data[0];
      IRDC_c_sum += data[1];
      RedDC_c_num ++;
      IRDC_c_num ++;
      
      // Waveform amplitude (Peak to Peak)     
      if ( data[1]>IR_max ){
        IR_max = data[1];
      }
      if ( data[1]<IR_min ){
        IR_min = data[1];
      }
      if ( data[0]>Red_max ){
        Red_max = data[0];
      }
      if ( data[0]<Red_min ){
        Red_min = data[0];
      }
        
      if( ts_time - cyc_timer >= cyc_time ){          // Respiratory cycle counter 1s
        IR_amp = IR_max-IR_min;
        Red_amp = Red_max-Red_min;
        IR_max=0;
        IR_min=4000;
        Red_max=0;
        Red_min=4000;
        // Removal of waveforms with large amplitude  use the old data.
        if((IR_amp > 0 && IR_amp <= DCamp_noise) || (Red_amp > 0 && Red_amp <= DCamp_noise)){
          if( RedDC_c_num > 0 && IRDC_c_num > 0 ){
            RedDC = RedDC_c_sum/RedDC_c_num;
            IRDC = IRDC_c_sum/IRDC_c_num;
            RedDC_old = RedDC;
            IRDC_old = IRDC;
          } else {
            RedDC = RedDC_old;
            IRDC = IRDC_old;
          }
        } else {
          RedDC = RedDC_old;
          IRDC = IRDC_old;
        }
        RedDC_c_sum = 0;
        RedDC_c_num = 0;
        IRDC_c_sum = 0;
        IRDC_c_num = 0;
         
        cyc_timer += cyc_time;
        if( ts_time > cyc_timer ){
          cyc_timer = ts_time;
        }
      }
      
      // Reference DC for display
      if( C_enable == 1 ){
        if( ts - C_timer < ave_time ){      
          if( RedDC > 0 && a_data_sum_g < move_ad_ts && abs(angle_ud90) <= 10 ){ 
            Red97_sum += RedDC;
            Red97_num ++;
          }
          if( IRDC > 0 && a_data_sum_g < move_ad_ts && abs(angle_ud90) <= 10 ){
            IR97_sum += IRDC;
            IR97_num ++;
          }
          motionS_sum += a_data_sum;
          motionS_num ++;
        }else{
          if( Red97_num>0 && IR97_num >0 ){
            Red97 = Red97_sum/Red97_num;
            IR97 = IR97_sum/IR97_num;
            Red97_sum = 0.0;
            IR97_sum = 0.0;
            Red97_num = 0;
            IR97_num = 0;
            Errorangle = "";
          } else {
            Errorangle = "Attitude Angle Error!";
            Red97 = 0;
            IR97 = 0;
          }
          if( Red97 > 3000 || Red97 < 700 || IR97 > 3000 || IR97 < 700){
            ErrorPPG = "PPG sensor Error!";
            String Serrm = "PPG sensor Error!";

            Object[] options = { "Retry", "Exit" };
              int r = JOptionPane.showOptionDialog(null, Serrm +"\r\nClick Retry to continue. Please retry Calibration.\r\nClick Exit to exit.Please adjust the detected level of LEDs.", "Warning",
                JOptionPane.DEFAULT_OPTION, JOptionPane.WARNING_MESSAGE,
                null, options, options[0]);

            if ( r == 0 ) {        // OK, continue
            }  
            else if ( r == 1 ) {
              exit();
            }  
          }else{
            ErrorPPG = "";
          }
        
          motionS_ave = motionS_sum/motionS_num;
          motionS_sum = 0;
          motionS_num = 0;
          if( motionS_ave > 500 ){
            Error = "Motion sensor Error!";

            String Serrm = "Motion sensor Error!";

            Object[] options = { "Retry", "Exit" };
            int r = JOptionPane.showOptionDialog(null, Serrm +"\r\nClick Retry to continue. Please retry Calibration.\r\nClick Exit to exit.Please change the Device.", "Warning",
               JOptionPane.DEFAULT_OPTION, JOptionPane.WARNING_MESSAGE,
               null, options, options[0]);

            if ( r == 0 ) {       // OK, continue
            }  
            else if ( r == 1 ) { 
              exit();
            }  
          }else{
            Error = "";
          }

          C_time = 0;
          C_enable = 2;
          cp5.getController("Calibration").setLock(false);
          cp5.getController("Calibration").setColorBackground(color(#0000FF));
          //println("Red97= "+Red97);
          //println("IR97= "+IR97);
          //println("C_enable= "+C_enable);
          //println("C_time= "+C_time);
          //println("a_data= "+motionS_ave);
        }
      }
    } // *1
    // Redref = Red97;
    // IRref = IR97;

    //////////////////////////////////////////////////
    // Time average (1 min) Temp & a_sum ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓// 
    if( meas_flag == 0 ){
      a_data_sum_c += a_data_sum;
      a_data_num ++;
      temp_sum1m += Temp;
      temp_num1m ++ ;
    }
  
    if( meas_flag == 1 ){
      if( a_data_num > 0 ){
        a_data_sum_ave = a_data_sum_c/a_data_num;
        a_data_sum_c =0.0;
        a_data_num = 0;
      }else{
        a_data_sum_ave=0;
      }
      temp_ave1m = ( temp_num1m > 0 )? temp_sum1m/temp_num1m : 0;
      temp_sum1m = 0;
      temp_num1m = 0;
    }
    
    // Time average (default 30 min) fcutoff ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓// 
    if( fc_meas_flag == 0 ){                  
      if( fft_flag == 0 && angle_flag == 0 ){               // Only stillness & horizontal
        if( bp >= bp_L && bp <= 100.0 ){
          mysumtfc += bp;
          botfc ++;
        }
        if( brt >= 21.0 && brt <= 200.0 ){
          kkysumtfc += brt;
          brotfc ++;
        }
      }
    }
    if( fc_meas_flag == 1 ){ 
      if( botfc > 0 ){
        myavetfc = mysumtfc/botfc;
        mysumtfc = 0.0;
        botfc = 0;
        fc0 = myavetfc/60;                                  // BPF Cutoff: HR by IR
        fc_H = fc0*1.1;
        fc_L = fc0*0.8;
        fc_H = ( fc_H > 10.83 )? 10.83: fc_H;               // Outlier handling
        fc_L = ( fc_L < fc_L0 )? fc_L0: fc_L;               // Outlier handling
        bpth_H = int(fc0 /50 * 512 * 1.5);                  // Threshold FFT: HR by IR
        bpth_L = int(fc0 /50 * 512 * 0.7);
        bpth_H = ( bpth_H > bpth_H0 )? bpth_H0: bpth_H;     // Outlier handling
        bpth_L = ( bpth_L < bpth_L0 )? bpth_L0: bpth_L;     // Outlier handling
        bpth_Ha = int(fc0 /50 * 512 * 1.5);                 // Threshold FFT: HR by a_sum
        bpth_La = int(fc0 /50 * 512 * 0.5);
        bpth_Ha = ( bpth_Ha > bpth_H0 )? bpth_H0: bpth_Ha;  // Outlier handling
        bpth_La = ( bpth_La < bpth_L0 )? bpth_L0: bpth_La;  // Outlier handling 
      }
      if( brotfc > 0 ){                                     // Respiratory frequency
        kkyavetfc = kkysumtfc/brotfc;
        // Respiratory rate outlier countermeasures
        if( kkyavetfc > kkyavetfc_old*1.3 || kkyavetfc < kkyavetfc_old*0.7){  
          kkyavetfc = kkyavetfc_old;
        }
        fbrtc = kkyavetfc/60;                               // BPF fCutoff: BPF by IR
        kkyavetfc_old = kkyavetfc;
        kkysumtfc = 0.0;
        brotfc = 0;
      }
    }
    //↑↑↑↑↑↑↑↑↑↑↑↑↑****************************************************************************************************************************************************************************

    if( updateData ) {
      file.print(ts + ",");             // PC time               1 fix
      file.print(ts_time + ",");        // BLE time(timestamp)   2
      file.print(file_No + ",");        // No.(-3 to 586)        3
      file.print(file_D[0] + ",");      // Red data              4 fix
      file.print(file_D[1] + ",");      // IR  data              5 fix
      file.print(file_Dfill1[1]+ ",");  // filtered IR for BR    6
      file.print(file_Dfill2[1] + ","); // fileterd IR for HR    7
      file.print(file_Dfill3[2] + ","); // filtered asum for HR  8
      file.print(bp1 + ",");            // HR(FFT)IR             9
      file.print(bp2 + ",");            // HR(FFT)a_sum          10
      file.print(brt + ",");            // BR(FFT)IR             11
      file.print(myave + ",");          // Ave HR of all data    12
      file.print(kkyave + ",");         // Ave BR of all data    13
      file.print(myavet + ",");         // Hist mean HR          14
      file.print(kkyavet + ",");        // Hist mean BR          15
      file.print("" + ",");             //                       16
      file.print(timestamp + ",");      // BLE timestamp         17
      file.print("" + ",");             //                       18
      file.print(Temp + ",");           // Temp degree           19 fix
      file.print(Tempdata + ",");       // Temp data             20
      file.print(timer_flag + ",");     // Dosing flag           21
      file.print(a_data[0] + ",");      // Accelaration          22 fix
      file.print(a_data[1] + ",");      //                       23 fix
      file.print(a_data[2] + ",");      //                       24 fix
      file.print(a_data_no_g[0] + ","); // Acceleration excluding gravity 25 fix
      file.print(a_data_no_g[1] + ","); //                       26 fix
      file.print(a_data_no_g[2] + ","); //                       27 fix
      file.print(a_data_flag[0] + ","); // Motion flag           28 
      file.print(a_data_flag[1] + ","); //                       29 
      file.print(a_data_flag[2] + ","); //                       30 
      file.print(g_data[0] + ",");      // Gyro                  31 fix
      file.print(g_data[1] + ",");      //                       32 fix
      file.print(g_data[2] + ",");      //                       33 fix
      file.print(a_data_sum + ",");     // a_sum                 34 fix
      file.println();                    
      file.flush();
  
      //1secファイル
      a_data_sum_s += a_data_sum;
      a_data_num_s ++;
    
      if ( ts_time - file_timer >= 1000 ) { // BLE時間 1sファイル      
        a_data_sum_ave_s = a_data_sum_s/a_data_num_s;
        a_sum_ave_s_g = a_data_sum_ave_s/pow(2, 14);
        a_data_sum_s =0.0;
        a_data_num_s = 0;
        if( a_sum_ave_s_g < active_ts ){
          active_d = 0;
        } else {
          active_d = a_sum_ave_s_g;
        }
      
        // SpO2 
        // Temperature correction for Rdc: Difference from initial state based on 1-min average
        Temp_ad = ( temp_ave1m > 36.5 )? (temp_ave1m/36.5) * ( 1 + 0.3 ) - 0.3 : 1.0;
        // Motion correction for Rdc
        move_ad = ( a_sum_ave_s_g > move_ad_ts )? 0.9 : 1.0;
             
        if( IR97 > 0 && Red97 > 0 ){
          RedDC_ad = RedDC*Redref/Red97;
          IRDC_ad = IRDC*IRref/IR97;
          RedDC_ad_old = RedDC_ad;
          IRDC_ad_old = IRDC_ad;
            
          if( RedDC_ad > Redref * 1.5 ){        // Outlier handling
            RedDC_ad = RedDC_ad_old;
            IRDC_ad = IRDC_ad_old;
          }
          Rdc = (IRDC_ad/IRref)/(RedDC_ad/Redref);
        } else {
          Rdc = 0 ;
        }
       // println(RedDC_ad+"  "+IRDC_ad+"  "+Redref+"  "+IRref+"  "+Rdc);
        RdcT[0] = Rdc * move_ad * Rdc_def;
        RdcT[1] = ( Temp_ad > 0 )? Rdc/Temp_ad * move_ad * Rdc_def : Rdc * move_ad * Rdc_def;

        for( int i=0; i <2; i++ ){ 
          if( RdcT[i] > 1 ){                    // Selection of conversion formula RdcT>1 or not (Not Rdc_def:Don't change)
            spo[i] =  Spo_k[SpoID][0] * RdcT[i] + Spo_k[SpoID][1];  
          }else if( RdcT[i]==0 ) {
            spo[i] = 0;                                              
          }else {
            spo[i] = Spo_k[SpoID][2] * RdcT[i] + Spo_k[SpoID][3];   
          }
          if( spo[i] > 100 ){
            spo[i] = 100;
          }
        }

        if( Tempad_flag==1 ){                   // Temp_ad On
          RdcD = RdcT[1];
          spoD = spo[1];
        }else{                                  // Temp_ad Off
          RdcD = RdcT[0];
          spoD = spo[0];
        }
        // spo[num] Calculate the SD for 10 units = 1sec (correction)
        spon[spony] = spoD;  
        spony = ( spony < spon_num-1 )? spony+1: 0;
        sposdn_sum = 0; 
        for( int i = 0; i < spon_num; i++ ){
          sposdn_sum +=  spon[i];
        }
        sposdn_ave = sposdn_sum / spon_num;
        sposdn_sum = 0;
        for( int i = 0; i < spon_num; i++ ){
          sposdn_sum += (spon[i]-sposdn_ave)*(spon[i]-sposdn_ave);
        }
        sposdn = sqrt(sposdn_sum/(spon_num));
        if( sposdn > 10 ){
          spoD = 0;
        }
      
        //1-min moving average for SpO2 display
        spoDave[spoy] = spoD;
        spoDsum = 0;
        spoDc = 0;

        for( int i = 0; i < Nma; i++ ){
          if( spoDave[i] >= 60.0){              // Average of all data (for graph and data display)
            spoDsum += spoDave[i];
            spoDc++;
          }
        }
        if( spoDc > 0 ){
          spoDa = spoDsum/spoDc;
        } else {
          spoDa = 0;
        }
        spoy = (spoy < Nma-1)? spoy+1: 0;
      
        float second_timer = ts_time/1000.0;  // [sec]
        float PC_sec =  ts/1000.0;            // [sec]
        float currentTime = baseTime + second_timer;
        // Conver to time
        h = int(currentTime / 3600);          
        m = int((currentTime / 60) % 60);     
        s = int(currentTime % 60);            
      
        file2.print(second_timer + ",");      // BLE time
        file2.print(timer_flag + ",");        // Dosing flag
        file2.print(RedDC + ",");             // DC revel 1s ave
        file2.print(IRDC + ",");              // DC revel 1s ave
        file2.print(Temp + ",");              // Temp  
        file2.print(myavet+ ",");             // Pulse rate
        file2.print(kkyavet + ",");           // Breath rate 
        file2.print(a_sum_ave_s_g + ",");     // [g] 
        file2.print(active_d  + ",");         // Activity amount 
        file2.print(angle_ud0 + ",");         // Angle ud
        file2.print(angle_rl0 + ",");         // Angle rl
        file2.print(angle_flag + ",");        // Angle flag     
        file2.print(Red97 + ",");             // Ref level Red
        file2.print(IR97 + ",");              // Ref level IR
        file2.print(Rdc + ",");               // Rdc
        file2.print(RdcD + ",");              // RdcT (selected)   
        file2.print(spoD + ",");              // selected SpO2
        file2.print(sposdn + ",");            // selected SpO2 sd
        file2.print(spoDa + ",");             // 選択SpO2 1分平均      
        file2.print(fft_flag + ",");          // 
        file2.print(bp +  ",");               // Pulse Rate all
        file2.print(bp1 +  ",");              // Pulse rate IR
        file2.print(bp2 +  ",");              // Pulse rate a_sum
        file2.print(fc0 + ",");               // fc0 Heart rate cutoff frequency IR
        file2.print(fc_L + ",");              // 
        file2.print(fc_H + ",");              //
        file2.print(brt +  ",");              // Breath rate
        file2.print(fbrtc +  ",");            // fc Respiratory cutoff frequency
        file2.println();
        file2.flush();   
      
        // 1s CSV file writing for analysis
        svtext = str(second_timer) + ","+ str(RedDC) + ","+str(IRDC) + ","+str(Temp_ad) + ","+str(move_ad) + ","+str(myavet) + ","+str(kkyavet)  + ","+
               str(Temp) + ","+  str(a_sum_ave_s_g) + ","+  str(active_d)+","+ str(angle_ud90)+","+ str(timer_flag)+","+str(PC_sec)+","+ str(update_rate)+","+str(Errorupdate_flag)+'\n';
        file_println(file_1s,svtext);
        Errorupdate_flag=0;                   // Errorupdate_flag reset
        
        file_timer += 1000;
        if( ts_time > file_timer ){      
          file_timer = ts_time;
        }
      }
    }
       
    if (ts_time - graph_timer > 1000 * graph_time) {
      graph_timer = ts_time;
      graph_datasp[0][graph_write_possp] = (spoDa > graph_spo_min)? spoDa-graph_spo_min: 0;
      graph_datasp[1][graph_write_possp] = (myave > graph_pulse_min)? myave-graph_pulse_min: 0;
      graph_datasp[2][graph_write_possp] = (kkyave > graph_breath_min)? kkyave-graph_breath_min: 0;
      graph_datasp[3][graph_write_possp] = (Temp > graph_temp_min)? Temp-graph_temp_min: 0;
      //graph_datasp[3][graph_write_possp] = (Temp < graph_temp_min+graph_temp_range)? Temp-graph_temp_min: graph_temp_range;
      a_graph_datasp[graph_write_possp] = a_data_flag[2];
      graph_write_possp = (graph_write_possp < data_graph_w-1)? graph_write_possp+1: 0;
    }

    // Display of auxiliary lines and labels
    drawAxuLine_SPBT();

    // Data update frequency display
    update_nn = showUpdateRate(updateData);

    textSize(16);
    textAlign(LEFT, TOP);
    text(ErrorPPG,vallabel_w,490);          // Error message waveform level
    text(Error,vallabel_w,510);             // Error message Sensor
    text(Errorangle,vallabel_w,530);        // Error message angle
    if( update_rate < 40 ){                  
      Errorupdate = "Poor reception";
    }else{
      Errorupdate = "";
    }
    text(Errorupdate,vallabel_w,550);
    text("BLE: "+nf(h,2) + ":" + nf(m, 2) + ":" + nf(s, 2),vallabel_w,570);
    text(int(angle_ud90_LPF)+"°",150, 440);
    text("Rdc="+ nf(RdcD,0,3), label_w , screen_h-480);
    textSize(20);
    text(nf(Temp,0,1)+" ℃", vallabel_w+250 , screen_h-70);
    if( spoDa >= 70 ){
      text(nf(spoDa,0,1)+" %", label_w , screen_h-450); 
    }
    text(round(myave)+"bpm", label_w, screen_h-260);
    text(round(kkyave)+"bpm", label_w, screen_h-70);
    textSize(12);
    text(round(RedDC), line_graph_x+60, 30);
    text(round(IRDC), line_graph_x+60, 50);
    if( file_cal != null ){
      textSize(12);
      text(file_cal, cp_positionX, 470,180,120);
    }
    // Graph display
    textSize(8);
    textAlign(CENTER, TOP);
    for ( int i = 0; i < 2; i++ ) {
      // Calculate the center coordinates and height of the bar graph
      int x = bar_graph_x + ((2 * i + 1) * bar_graph_w / (2 * num_bar));
      int y = int(-line_graph_h * data[i] / plotarea_range);

      // Drawing a bar graph
      int c = (i % 6) + 1; 
      fill(graph_color[c][0], graph_color[c][1], graph_color[c][2]);
      noStroke();
      rect(x-(bar_w/2), bar_y, bar_w, y);
    
      // Display data values
      int ty = bar_y + y + ((0.0f <= data[i])? -16: +0);
      text(nf(data[i], 1, 1), x, ty);
    
      // Displaying a line graph
      stroke(graph_color[c][0], graph_color[c][1], graph_color[c][2]);
      int k = graph_write_pos;
      y = bar_y + int(-line_graph_h * graph_data[i][k] / plotarea_range);
      for ( int j = 0; j < line_graph_w-1; j++ ){
        k = (k < line_graph_w-1)? k+1: 0;
        int yy = bar_y + int(-line_graph_h * graph_data[i][k] / plotarea_range);
        line(line_graph_x+j, y, line_graph_x+j+1, yy);
        y = yy;
      }
    }

    // Display of enlarged line graph 1
    int c1 = (0 % 6) + 1; //1
    stroke(graph_color[c1][0], graph_color[c1][1], graph_color[c1][2]);
    int l = widegraph_write_pos;
    int center1_y = int(widegraph_data[0][l]);
    int wideline1_y = 0;
    int wideline1_yy = 0;
    for ( int j = 0; j < wideline_graph_w-1; j++ ) {
      l = (l < wideline_graph_w-1)? l+1: 0;
      wideline1_yy= int(widegraph_data[0][l])-center1_y;
      if( wideline1_yy>graph_widedata_max ){
        wideline1_yy=graph_widedata_max;
      } else if ( wideline1_yy<graph_widedata_min ){
        wideline1_yy=graph_widedata_min;
      }
      line(wideline_graph1_x+j, wideline_graph1_y+graph_widedata_max-wideline1_y, wideline_graph1_x+j+1, wideline_graph1_y+graph_widedata_max-wideline1_yy);
      wideline1_y = wideline1_yy;
    }
  
    // Display of enlarged line graph 2
    int c2 = (1 % 6) + 1;//2
    stroke(graph_color[c2][0], graph_color[c2][1], graph_color[c2][2]);
    int m = widegraph_write_pos;
    int center2_y = int(widegraph_data[1][m]);
    int wideline2_y = 0;
    int wideline2_yy = 0;
    for ( int j = 0; j < wideline_graph_w-1; j++ ) {
      m = (m < wideline_graph_w-1)? m+1: 0;
      wideline2_yy= int(widegraph_data[1][m])-center2_y;
      if( wideline2_yy>graph_widedata_max ){
        wideline2_yy=graph_widedata_max;
      } else if ( wideline2_yy<graph_widedata_min ){
        wideline2_yy=graph_widedata_min;
      }
      line(wideline_graph2_x+j, wideline_graph2_y+graph_widedata_max-wideline2_y, wideline_graph2_x+j+1, wideline_graph2_y+graph_widedata_max-wideline2_yy);
      wideline2_y = wideline2_yy;
    }

    stroke(255, 255, 0);
    int ay = bar_y + int(-line_graph_h * a_data_sum / as_plotarea_range);
    int q = graph_write_pos;
    for ( int j = 0; j < line_graph_w-1; j++ ){
      q = (q < line_graph_w-1)? q+1: 0;
      int ayy = bar_y + int(-line_graph_h * a_graph_data[q] / as_plotarea_range);
      line(line_graph_x+j, ay, line_graph_x+j+1, ayy);
      ay = ayy;
    }

    for ( int i = 0; i < 3; i++ ){     // Acceleration sensors
      // Calculate the center coordinates and height of the bar graph
      int x = bar_graph_x + ((2 * i + 1) * bar_graph_w / (2 * 3)) - 350;
      int y = int(-line_graph_h * a_data[i] / a_plotarea_range);

      // Drawing a bar graph
      fill(a_graph_color[i][0], a_graph_color[i][1], a_graph_color[i][2]);
      noStroke();
      rect(x-(bar_w/2), bar_y, bar_w, y);

      // Display data values
      int ty = bar_y + y + ((0.0f <= a_data[i])? -16: +0);
      text(nf(a_data[i], 1, 1), x, ty);
    }

    for ( int i = 0; i < 3; i++ ){     // Gyro sensors
      // Calculate the center coordinates and height of the bar graph
      int x = bar_graph_x + ((2 * i + 1) * bar_graph_w / (2 * 3)) - 330;
      int y = int(-line_graph_h * g_data[i] / a_plotarea_range);

      // Drawing a bar graph
      fill(a_graph_color[i][0], a_graph_color[i][1], a_graph_color[i][2]);
      noStroke();
      rect(x-(bar_w/2), bar_y, bar_w, y);

      // Display data values
      int ty = bar_y + y + ((0.0f <= g_data[i])? -16: +0);
      text(nf(g_data[i], 1, 1), x, ty);
    }

    // Body motion flag
    if ( a_data_flag[2] == 0 ) {
      noStroke();
      fill(255, 255, 255);
      circle(line_graph_x+20, 50, 20);
    } else {
      noStroke();
      fill(222, 82, 133);
      circle(line_graph_x+20, 50, 20);
    }
  
    // Attitude angle bar
    // rectMode(CENTER);    // Drawing based on the center of the rectangle
    pushMatrix();
    translate(100, 450);    // Move the center of rotation
    rotate(radians(int(angle_ud90_LPF)));
    fill(150, 150, 150);
    if( C_enable==1 &&  abs(angle_ud90_LPF)>10 ){
      fill(200,0,0);
    }
    rect(-40, -5, 80, 10);  // Draw with the center as the origin

    popMatrix();

    // The bottom 3 data points are displayed as line graphs.
    int k = graph_write_possp;
    int y0 = spo_graph_y  + data_graph_h + int(-data_graph_h * graph_datasp[0][k]/graph_spo_range);
    int y1 = pulse_graph_y + data_graph_h + int(-data_graph_h * graph_datasp[1][k]/graph_pulse_range);
    int y2 = breath_graph_y + data_graph_h + int(-data_graph_h * graph_datasp[2][k]/graph_breath_range);
    int y3 = temp_graph_y + data_graph_h + int(-data_graph_h * graph_datasp[3][k]/graph_temp_range);
    for (int j = 0; j < data_graph_w-1; j++){
      k = (k < data_graph_w-1)? k+1: 0;
      int yy0 =  spo_graph_y  + data_graph_h + int(-data_graph_h * graph_datasp[0][k]/graph_spo_range);
      int yy1 =  pulse_graph_y + data_graph_h + int(-data_graph_h * graph_datasp[1][k]/graph_pulse_range);
      int yy2 =  breath_graph_y + data_graph_h + int(-data_graph_h * graph_datasp[2][k]/graph_breath_range);
      int yy3 = temp_graph_y + data_graph_h + int(-data_graph_h * graph_datasp[3][k]/graph_temp_range);

      if( a_graph_datasp[k] == 0 ) {  
        strokeWeight(4);
        stroke(30, 144, 255);
        //line(right_data_graph_x+j, y0, right_data_graph_x+j+1, yy0);
        ellipse(right_data_graph_x+j, y0, 3,3);
        stroke(255, 165, 0);
        line(right_data_graph_x+j, y1, right_data_graph_x+j+1, yy1);
        stroke(138, 43, 226);
        line(right_data_graph_x+j, y2, right_data_graph_x+j+1, yy2);
        stroke(205, 92, 92);
        line(left_data_graph_x+j, y3, left_data_graph_x+j+1, yy3);
        strokeWeight(1);
      } else {
        strokeWeight(4);
        stroke(180, 180, 180);
        // line(right_data_graph_x+j, y0, right_data_graph_x+j+1, yy0);
        ellipse(right_data_graph_x+j, y0, 3,3);
        stroke(180, 180, 180);
        line(right_data_graph_x+j, y1, right_data_graph_x+j+1, yy1);
        stroke(180, 180, 180);
        line(right_data_graph_x+j, y2, right_data_graph_x+j+1, yy2);
        stroke(180, 180, 180);
        line(left_data_graph_x+j, y3, left_data_graph_x+j+1, yy3);
        strokeWeight(1);
      }

      y0 = yy0;
      y1 = yy1;
      y2 = yy2;
      y3 = yy3;
    }
  }
}
