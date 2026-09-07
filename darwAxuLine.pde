// 補助線とラベルの表示

int under_time = 0;

void drawAxuLine_SPBT()
{
  //拡大脈波グラフ1の描画************************************************************************************************************************
  for (int y = 0; y<=num_axuline_wide; y++)
  {
    // 補助線のy座標を計算
    int yy = wideline_graph1_y + (y * wideline_graph_h / num_axuline_wide);
    // 補助線の色を決める(Y=0.0が明るく、他は暗い灰色)
    stroke(64);
    //fill(64);
    // 補助線を引く
    line(wideline_graph1_x, yy, wideline_graph1_x + wideline_graph_w, yy);
    // ラベルを書く
    float val = wideline_graph_h/ wide_rate / 2 - (y *  wideline_graph_h / wide_rate / num_axuline_wide);
    fill(192);
    textSize(14);
    textAlign(RIGHT, CENTER);
    if (y == num_axuline_wide) {
      text(nf(val, 1, 0), wideline_graph1_x-2, yy-5);
    } else if (y == 0) {
      text(nf(val, 1, 0), wideline_graph1_x-2, yy+5);
    } else {
      text(nf(val, 1, 0), wideline_graph1_x-2, yy);
    }
  }
  strokeWeight(1);
  stroke(32);
  for (int t = 0; t <= wideline_graph_w; t += 60)
  {
    int x = wideline_graph1_x + wideline_graph_w - t;
    if (t != 0 || t != wideline_graph_w) {
      line(x, wideline_graph1_y, x, wideline_graph1_y+wideline_graph_h);
    }
  }

  //拡大脈波グラフ2の描画************************************************************************************************************************
  for (int y = 0; y<=num_axuline_wide; y++)
  {
    // 補助線のy座標を計算
    int yy = wideline_graph2_y + (y * wideline_graph_h / num_axuline_wide);
    // 補助線の色を決める(Y=0.0が明るく、他は暗い灰色)
    stroke(64);
    //fill(64);
    // 補助線を引く
    line(wideline_graph2_x, yy, wideline_graph2_x + wideline_graph_w, yy);
    // ラベルを書く
    float val = wideline_graph_h/ wide_rate / 2 - (y *  wideline_graph_h / wide_rate / num_axuline_wide);
    fill(192);
    textSize(14);
    textAlign(RIGHT, CENTER);
    if (y == num_axuline_wide) {
      text(nf(val, 1, 0), wideline_graph2_x-2, yy-5);
    } else if (y == 0) {
      text(nf(val, 1, 0), wideline_graph2_x-2, yy+5);
    } else {
      text(nf(val, 1, 0), wideline_graph2_x-2, yy);
    }
  }
  strokeWeight(1);
  stroke(32);
  for (int t = 0; t <= wideline_graph_w; t += 60)
  {
    int x = wideline_graph2_x + wideline_graph_w - t;
    if (t != 0 || t != wideline_graph_w) {
      line(x, wideline_graph2_y, x, wideline_graph2_y+wideline_graph_h);
    }
    textSize(14);
    textAlign(CENTER, TOP);
    fill(192);
    text(nf(under_time, 1, 0), x, wideline_graph2_y+wideline_graph_h);
    under_time++;
  }
  text("Time [s]", wideline_graph2_x + wideline_graph_w/2, wideline_graph2_y+wideline_graph_h+13);
  under_time = 0;

  //脈波グラフの描画************************************************************************************************************************
  for (int y = 0; y <= num_net_axuline; y++)
  {
    // 補助線のy座標を計算
    int yy = line_graph_y + (y * line_graph_h / num_net_axuline);
    // 補助線の色を決める(Y=0.0が明るく、他は暗い灰色)
    int c = (y == main_axis)? 192: 64;
    stroke(c);
    fill(c);
    // 補助線を引く
    line(line_graph_x, yy, line_graph_x+line_graph_w, yy);
    // ラベルを書く
    float val = max_data_val - (y * max_data_val / num_axuline);
    fill(192);
    textSize(14);
    textAlign(RIGHT, CENTER);
    if (y == main_axis) {
      text(nf(val, 1, 0), line_graph_x-2, yy-5);
    } else {
      text(nf(val, 1, 0), line_graph_x-2, yy);
    }
  }
  // 脈波グラフの1秒間隔の補助線を引く
  stroke(32);
  for (int t = 0; t <= line_graph_w; t += 60)
  {
    int x = line_graph_x + line_graph_w - t;
    line(x, line_graph_y, x, line_graph_y+line_graph_h);
    textSize(14);
    textAlign(CENTER, TOP);
    fill(192);
    text(nf(under_time, 1, 0), x, line_graph_y+line_graph_h);
    under_time++;
  }
  text("Time [s]", line_graph_x+line_graph_w/2, line_graph_y+line_graph_h+13);
  under_time = 0;
  //****************************************************************************************************************************************

  //データグラフの描画**********************************************************************************************************************

  //spo2(右上)グラフの描画******************************************************************
  for (int y = 0; y<=num_axuline_spo; y++)
  {
    // 補助線のy座標を計算
    int yy = spo_graph_y + (y * data_graph_h / num_axuline_spo);
    // 補助線の色を決める(Y=0.0が明るく、他は暗い灰色)
    int c = (y == num_axuline_spo)? 192: 64;
    stroke(c);
    fill(c);
    // 補助線を引く
    line(right_data_graph_x, yy, right_data_graph_x + data_graph_w, yy);
    // ラベルを書く
    float val = graph_spo_min + graph_spo_range - (y * graph_spo_range / num_axuline_spo);
    fill(192);
    textSize(14);
    textAlign(RIGHT, CENTER);
    if (y == num_axuline_spo) {
      text(nf(val, 1, 0), right_data_graph_x-2, yy-5);
    } else if (y == 0) {
      text(nf(val, 1, 0), right_data_graph_x-2, yy+5);
    } else {
      text(nf(val, 1, 0), right_data_graph_x-2, yy);
    }
  }
  strokeWeight(1);
  stroke(32);
  for (int t = 0; t <= data_graph_w; t += int(60 / graph_time))
  {
    int x = right_data_graph_x + data_graph_w - t;
    line(x, spo_graph_y, x, spo_graph_y + data_graph_h);
  }

  //pulse(右中央)グラフの描画*************************************************************
  for (int y = 0; y<=num_axuline_pulse; y++)
  {
    // 補助線のy座標を計算
    int yy = pulse_graph_y + (y * data_graph_h / num_axuline_pulse);
    // 補助線の色を決める(Y=0.0が明るく、他は暗い灰色)
    int c = (y == num_axuline_pulse)? 192: 64;
    stroke(c);
    fill(c);
    // 補助線を引く
    line(right_data_graph_x, yy, right_data_graph_x + data_graph_w, yy);
    // ラベルを書く
    float val = graph_pulse_min + graph_pulse_range - (y * graph_pulse_range / num_axuline_pulse);
    fill(192);
    textSize(14);
    textAlign(RIGHT, CENTER);
    if (y == num_axuline_pulse) {
      text(nf(val, 1, 0), right_data_graph_x-2, yy-5);
    } else if (y == 0) {
      text(nf(val, 1, 0), right_data_graph_x-2, yy+5);
    } else {
      text(nf(val, 1, 0), right_data_graph_x-2, yy);
    }
  }
  strokeWeight(1);
  stroke(32);
  for (int t = 0; t <= data_graph_w; t += int(60 / graph_time))
  {
    int x = right_data_graph_x + data_graph_w - t;
    line(x, pulse_graph_y, x, pulse_graph_y + data_graph_h);
  }

  //breath(右下)グラフの描画*************************************************************
  for (int y = 0; y<=num_axuline_breath; y++)
  {
    // 補助線のy座標を計算
    int yy = breath_graph_y + (y * data_graph_h / num_axuline_breath);
    // 補助線の色を決める(Y=0.0が明るく、他は暗い灰色)
    int c = (y == num_axuline_breath)? 192: 64;
    stroke(c);
    fill(c);
    // 補助線を引く
    line(right_data_graph_x, yy, right_data_graph_x + data_graph_w, yy);
    // ラベルを書く
    float val = graph_breath_min + graph_breath_range - (y * graph_breath_range / num_axuline_breath);
    fill(192);
    textSize(14);
    textAlign(RIGHT, CENTER);
    if (y == num_axuline_breath) {
      text(nf(val, 1, 0), right_data_graph_x-2, yy-5);
    } else if (y == 0) {
      text(nf(val, 1, 0), right_data_graph_x-2, yy+5);
    } else {
      text(nf(val, 1, 0), right_data_graph_x-2, yy);
    }
  }
  strokeWeight(1);
  stroke(32);
  for (int t = 0; t <= data_graph_w; t += int(60 / graph_time))
  {
    int x = right_data_graph_x + data_graph_w - t;
    line(x, breath_graph_y, x, breath_graph_y + data_graph_h);
    textSize(14);
    textAlign(CENTER, TOP);
    fill(192);
    text(nf(under_time, 1, 0), x, breath_graph_y + data_graph_h );
    under_time++;
  }
  text("Time [min]", right_data_graph_x + data_graph_w/2, breath_graph_y + data_graph_h + 12);
  under_time = 0;

  //temp(左下)グラフの描画*************************************************************
  for (int y = 0; y<=num_axuline_temp; y++)
  {
    // 補助線のy座標を計算
    int yy = temp_graph_y + (y * data_graph_h / num_axuline_temp);
    // 補助線の色を決める(Y=0.0が明るく、他は暗い灰色)
    int c = (y == num_axuline_temp)? 192: 64;
    stroke(c);
    fill(c);
    // 補助線を引く
    line(left_data_graph_x, yy, left_data_graph_x + data_graph_w, yy);
    // ラベルを書く
    float val = graph_temp_min + graph_temp_range - (y * graph_temp_range / num_axuline_temp);
    fill(192);
    textSize(14);
    textAlign(RIGHT, CENTER);
    if (y == num_axuline_temp) {
      text(nf(val, 1, 0), left_data_graph_x-2, yy-5);
    } else if (y == 0) {
      text(nf(val, 1, 0), left_data_graph_x-2, yy+5);
    } else {
      text(nf(val, 1, 0), left_data_graph_x-2, yy);
    }
  }
  strokeWeight(1);
  stroke(32);
  for (int t = 0; t <= data_graph_w; t += int(60 / graph_time))
  {
    int x = left_data_graph_x + data_graph_w - t;
    line(x, temp_graph_y, x, temp_graph_y + data_graph_h);
    textSize(14);
    textAlign(CENTER, TOP);
    fill(192);
    text(nf(under_time, 1, 0), x, temp_graph_y + data_graph_h );
    under_time++;
  }
  text("Time [min]", left_data_graph_x + data_graph_w/2, temp_graph_y + data_graph_h + 12);
  under_time = 0;
  //****************************************************************************************************************************************

  textSize(14);
  textAlign(LEFT, TOP);
  fill(192);
  text("Pulse", line_graph_x+2, line_graph_y);
  text("Red", wideline_graph1_x+2, wideline_graph1_y);
  text("IR", wideline_graph2_x+2, wideline_graph2_y);
  text("SpO2", right_data_graph_x+2, spo_graph_y);
  text("PulseRate", right_data_graph_x+2, pulse_graph_y);
  text("BreathRate", right_data_graph_x+2, breath_graph_y);
  text("Temperature", left_data_graph_x+2, temp_graph_y);

  //グラフ領域の描画************************************************************************************************************************
  noFill();
  stroke(192);
  strokeWeight(1);
  rect(line_graph_x, line_graph_y, line_graph_w, line_graph_h);
  rect(wideline_graph1_x, wideline_graph1_y, wideline_graph_w, wideline_graph_h);
  rect(wideline_graph2_x, wideline_graph2_y, wideline_graph_w, wideline_graph_h);
  rect(right_data_graph_x, spo_graph_y, data_graph_w, data_graph_h);
  rect(right_data_graph_x, pulse_graph_y, data_graph_w, data_graph_h);
  rect(right_data_graph_x, breath_graph_y, data_graph_w, data_graph_h);
  rect(left_data_graph_x, temp_graph_y, data_graph_w, data_graph_h);
}
