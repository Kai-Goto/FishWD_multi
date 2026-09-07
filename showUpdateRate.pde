
// データ更新カウンタ(1秒ごとにリセット)
int update_counter;
// 直前の1秒間のデータ更新数
int update_rate;
// 直前のリセット時のリアルタイムクロック[ミリ秒]
int update_timer0;
// プログラムの動作インジケータのアニメーションカウンタ
int update_anim;


// データ更新頻度表示
int showUpdateRate(boolean update)
{
  // データ更新をカウントアップ
  if (update)
  {
    update_counter++;
  }

  // 1秒おきに表示を更新  タイマー時刻はt加算
  int t = millis();
  if (1000 <= (t - update_timer0))
  {
    update_rate = update_counter;
    update_counter = 0;
    update_timer0 = t;
  }

  // 更新頻度の表示
  textSize(12);
  textAlign(RIGHT, TOP);
  fill(192);
  String str = "Update/Sec:" +  update_rate;
  text(str, right_data_graph_x-45, 10);
  // プログラムの動作インジケータアニメーションの表示
  String[] anim = { "-", "|", "-", "|" };
  text(anim[update_anim/8], screen_w-4, 0);
  update_anim = (update_anim < 4*8-1)? update_anim+1: 0;
  return update_rate;
}
