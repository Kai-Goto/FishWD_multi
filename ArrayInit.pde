void ArrayInit()
{
  for( int i = 0; i <2; i++ ) {
    for( int j = 0; j < line_graph_w; j++ ) {
      graph_data[i][j] = 0;
      yout1[i][j] = 0.0;
      yout2[i][j] = 0.0;
      yout3[i][j] = 0.0;
    }
  }
 

  for( int i=0; i<spon_num; i++ ){
    spon[i] = 0.0;
    spon_arr[i] = 0.0;
  }
  
  for ( int i=0; i<3; i++ ) {  
    // Acceleration data threshold setting
    a_data_sum_ts[i] = Threshold[i];
    a_data_time[i] = 0;
    a_data_flag[i] = 0;
  }
}
