// Dual secondary filter

//sinh 
public float sinh(float x){
   return ((exp(x)-exp(-x))/2);
}

void filter() {
  int gwp_3 = 0, gwp_4 = 0, gwp_5 = 0; // 算出用 過去データ座標(-3,-4,-5)
  
  /*バターワースフィルタ
  float wn=2*PI*fc_L*ti; //呼吸用LPF　未使用
  float wc=2*tan(wn/2);
  float b1=-(2*wc*wc-8)/(wc*wc+2*1.4142*wc+4);
  float b2=-(wc*wc-2*1.4142*wc+4)/(wc*wc+2*1.4142*wc+4);
  float a1=wc*wc/(wc*wc+2*1.4142*wc+4);
  float a2=2*wc*wc/(wc*wc+2*1.4142*wc+4);
  float a3=wc*wc/(wc*wc+2*1.4142*wc+4);*/

  float bw = 1.0;  //帯域幅
  float alpha;

// High pass filter　未使用
// float samplerate サンプリング周波数
// float freq カットオフ周波数
/*  float q =1.0; //フィルタのQ値  
  float omega = 2.0*PI*fc_L*ti;  //心拍 IR HPF 呼吸波除く
  alpha = sin(omega) / (2.0f * q);
  float a0h =   1.0f + alpha;
  float a1h =  -2.0f * cos(omega);
  float a2h =   1.0f - alpha;
  float b0h =  (1.0f + cos(omega)) / 2.0f;
  float b1h = -(1.0f + cos(omega));
  float b2h =  (1.0f + cos(omega)) / 2.0f;
*/
  // Band pass filter for IR
  float w0 = 2.0*PI*fc0*ti;      // 心拍 IR BPF 呼吸波除く
  alpha = sin(w0) * sinh(log(2.0)/2.0 *bw*w0/sin(w0));
  float a0h =  1.0f + alpha;
  float a1h = -2.0f * cos(w0);
  float a2h =  1.0f - alpha;
  float b0h =  alpha;
  float b1h =  0.0f;
  float b2h = -alpha;

// Band pass filter
  float w = 2.0*PI*fc*ti;        // 心拍 合成加速度用
  alpha = sin(w) * sinh(log(2.0)/2.0 *bw*w/sin(w));
  float a0b =  1.0f + alpha;
  float a1b = -2.0f * cos(w);
  float a2b =  1.0f - alpha;
  float b0b =  alpha;
  float b1b =  0.0f;
  float b2b = -alpha;
  
  bw=1.0;
  float wbrt = 2.0*PI*fbrtc*ti;  // 呼吸 IR
  alpha = sin(wbrt) * sinh(log(2.0)/2.0 *bw*wbrt/sin(wbrt));
  float a0b1=  1.0f + alpha;
  float a1b1 = -2.0f * cos(wbrt);
  float a2b1 =  1.0f - alpha;
  float b0b1 =  alpha;
  float b1b1 =  0.0f;
  float b2b1 = -alpha;
  
// 　float input[]  …入力信号の格納されたバッファ。
// 　flaot output[] …フィルタ処理した値を書き出す出力信号のバッファ。
// 　float in1, in2, out1, out2  …フィルタ計算用のバッファ変数。初期値は0。
// 　float a0, a1, a2, b0, b1, b2 …フィルタの係数。 別途算出する。
//    output[i] = b0/a0 * input[i] + b1/a0 * in1  + b2/a0 * in2 - a1/a0 * out1 - a2/a0 * out2;
//  in2  = in1;       // 2つ前の入力信号を更新
//  in1  = input[i];  // 1つ前の入力信号を更新
//  out2 = out1;      // 2つ前の出力信号を更新
//  out1 = output[i]; // 1つ前の出力信号を更新
  
  for( int i=0; i < numData; i++ ) {
    file_D[i] = 0;
    file_Dfill1[i] = 0.0;
    file_Dfill2[i] = 0.0;
    file_Dfill3[i] = 0.0;
  }

  gwp_3 = (graph_write_pos-3 < 0)? line_graph_w + graph_write_pos-3: graph_write_pos-3 ;  // 0 to 589
  gwp_4 = (graph_write_pos-4 < 0)? line_graph_w + graph_write_pos-4: graph_write_pos-4 ;
  gwp_5 = (graph_write_pos-5 < 0)? line_graph_w + graph_write_pos-5: graph_write_pos-5 ;
  
  file_No = gwp_3;

  for( int i = 0; i < numData; i++ ) {
    file_D[i] = graph_data[i][gwp_3];   // File storage (ADC data)

    if( graph_data[i][gwp_3]>0&&graph_data[i][gwp_3]<max_data_val ) {
      //yout[i][gwp_3]=b1*graph_data[i][gwp_3]+a1*yout[i][gwp_4]+a2*yout[i][gwp_5];
      //yout1[i][gwp_3]=b1*yout1[i][gwp_4]+b2*yout1[i][gwp_5]+a1*graph_data[i][gwp_3]+a2*graph_data[i][gwp_4]+a3*graph_data[i][gwp_5];
      yout1[i][gwp_3] = -a1b1/a0b1*yout1[i][gwp_4]-a2b1/a0b1*yout1[i][gwp_5]+b0b1/a0b1*graph_data[i][gwp_3]+b1b1/a0b1*graph_data[i][gwp_4]+b2b1/a0b1*graph_data[i][gwp_5];
      //yout2[i][gwp_3]=b12*yout2[i][gwp_4]+b22*yout2[i][gwp_5]+a12*graph_data[i][gwp_3]+a22*graph_data[i][gwp_4]+a32*graph_data[i][gwp_5]; 
      yout2[i][gwp_3] = -a1h/a0h*yout2[i][gwp_4]-a2h/a0h*yout2[i][gwp_5]+b0h/a0h*graph_data[i][gwp_3]+b1h/a0h*graph_data[i][gwp_4]+b2h/a0h*graph_data[i][gwp_5];
      yout3[i][gwp_3] = -a1b/a0b*yout3[i][gwp_4]-a2b/a0b*yout3[i][gwp_5]+b0b/a0b*graph_data[i][gwp_3]+b1b/a0b*graph_data[i][gwp_4]+b2b/a0b*graph_data[i][gwp_5];
    }else{
      yout1[i][gwp_3] = 0.0;
      yout2[i][gwp_3] = 0.0;
      yout3[i][gwp_3] = 0.0;
    }
    file_Dfill1[i] = yout1[i][gwp_3]; // File storage BR by IR BPF
    file_Dfill2[i] = yout2[i][gwp_3]; // File storage HR by IR BPF
    file_Dfill3[i] = yout3[i][gwp_3]; // File storage HR by a_sum BPF
  }
}
