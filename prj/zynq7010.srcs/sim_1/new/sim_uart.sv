`timescale 1ns / 1ps

//==============================================================================
// UART 直连回环验证 testbench（修改前 / 修改后 共用同一套）
//   连接关系就是板卡上的用法： rx_en = tx_en , rx_data = tx_data
//   理想 PC 连续发 10 字节 00..09（按 CHACK 决定是否带校验位）
//       -> uart_rx -> 直连 -> uart_tx -> 理想接收器解析 TX 发出的字节
//   切换校验模式： vsim -G/CHACK=0|1|2
//==============================================================================
module tb_uart_loop;

  localparam CLK_FREQ=100_000_000, BAUD_RATE=115200, DATA_WIDTH=8, STOP_WIDTH=1;
  parameter integer CHACK = 1;          // 0=无校验 1=奇校验 2=偶校验

  logic clk=1'b0; always #5 clk=~clk;   // 100MHz
  logic reset, rxd, txd;
  logic rx_en, tx_en, busy;
  logic [7:0] rx_data, tx_data;

  uart_rx #(.CLK_FREQ(CLK_FREQ),.BAUD_RATE(BAUD_RATE),
            .DATA_WIDTH(DATA_WIDTH),.STOP_WIDTH(STOP_WIDTH),.CHACK_TYPE(CHACK))
    u_rx(.clk(clk),.reset(reset),.uart_rxd(rxd),
         .uart_rx_en(rx_en),.uart_rx_data(rx_data));

  // ---- 板卡直连：接收数据/使能 直接接到发送端 ----
  assign tx_data = rx_data;
  assign tx_en   = rx_en;

  uart_tx #(.CLK_FREQ(CLK_FREQ),.BAUD_RATE(BAUD_RATE),
            .DATA_WIDTH(DATA_WIDTH),.STOP_WIDTH(STOP_WIDTH),.CHACK_TYPE(CHACK))
    u_tx(.clk(clk),.reset(reset),.uart_txd(txd),
         .uart_tx_en(tx_en),.uart_tx_data(tx_data),.uart_tx_busy(busy));

  real T = 1000000000.0 / BAUD_RATE;   // 一个位时间 8680.5ns

  // 理想 PC 发送一字节：起始位 + 8数据(LSB先) + 校验位 + 停止位
  task send_byte(input [7:0] d);
    integer i; logic par;
    begin
      par = 1'b0;
      for (i=0;i<8;i++) par = par ^ d[i];
      rxd = 1'b0; #(T);                 // 起始位
      for (i=0;i<8;i++) begin rxd = d[i]; #(T); end
      if      (CHACK==1) rxd = ~par;    // 奇校验
      else if (CHACK==2) rxd =  par;    // 偶校验
      if (CHACK!=0) #(T);               // 校验位
      rxd = 1'b1; #(T);                 // 停止位
    end
  endtask

  // 理想接收器解析 TX 输出（含校验检查），统计实际发出的字节
  integer tx_bytes[$];
  integer nerr = 0;
  integer rx_cnt = 0;
  task automatic parse_one;
    logic [7:0] v; integer i; logic ptot;
    begin
      @(negedge txd);
      #(T*1.5);                         // 到 bit0 中点(跳过起始位)
      v = 8'd0; ptot = 1'b0;
      for (i=0;i<8;i++) begin v[i]=txd; ptot=ptot^txd; #(T); end
      if (CHACK!=0) begin ptot=ptot^txd; #(T); end   // 校验位中点
      if (CHACK==1 && ptot!==1'b1) nerr=nerr+1;
      if (CHACK==2 && ptot!==1'b0) nerr=nerr+1;
      tx_bytes.push_back(v);
      $display("  [%0t] TX byte[%0d] = %02h", $time, tx_bytes.size()-1, v);
    end
  endtask

  // 统计 RX 收到的字节数（rx_en 脉冲数）
  initial begin
    forever begin
      @(posedge clk);
      if (rx_en === 1'b1) rx_cnt = rx_cnt + 1;
    end
  end

  initial fork
    forever parse_one();
  join_none

  initial begin
    reset=1'b1; rxd=1'b1;
    repeat(50) @(posedge clk);
    reset=1'b0;
    repeat(2000) @(posedge clk);
    $display("========== CHACK=%0d  send 00..09 (10 bytes) ==========", CHACK);
    for (int i=0;i<10;i++) send_byte(i[7:0]);
    repeat(20000) @(posedge clk);
    $display(">>> CHACK=%0d  RX=%0d bytes | TX=%0d bytes (expect 10) | parity_err=%0d",
             CHACK, rx_cnt, tx_bytes.size(), nerr);
    $display(">>> RESULT: %s", (tx_bytes.size()==10 && nerr==0) ? "PASS" : "FAIL");
    $finish;
  end
endmodule