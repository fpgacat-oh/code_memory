`timescale 1ns / 1ps
module uart_tx #(
    parameter                           CLK_FREQ                    = 50000000             , // 时钟频率
    parameter                           BAUD_RATE                   = 115200               , // 波特率
    parameter                           DATA_WIDTH                  = 8                    , // 数据位宽
    parameter                           STOP_BITS                   = 1                    , // 停止位宽 1 或 2
    parameter                           CHACK_TYPE                  = 0 // 0 无校验；1 奇校验；2 偶校验
)(
    input  logic                            clk                        , // 时钟
    input  logic                            reset                      , // 复位，高有效
    output logic                            uart_txd                   , // 串口发送 TX
    input  logic                            uart_tx_en                 , // 发送数据使能
    input  logic          [DATA_WIDTH-1:0]  uart_tx_data               , // 发送的数据
    output logic                            uart_tx_busy                // 正在发送标志
);

    localparam                          BAUD_CNT_MAX                = CLK_FREQ / BAUD_RATE ; // 复位之前已经计算好了，只需要计算一次
    localparam                          BAUD_CNT_MAX_HALF           = BAUD_CNT_MAX / 2     ; // 同上

    logic                  [DATA_WIDTH-1:0]               uart_tx_data_d1          ;
    logic                                                 tx_flag                  ;
    logic                  [$clog2(BAUD_CNT_MAX)-1:0]     baud_cnt                 ; // $clog2 自动计算最小位宽
    logic                  [   3:0]                       bit_cnt                  ;
    //补充调整
    logic                                                 pending_vld          ;
    logic                  [DATA_WIDTH-1:0]               pending_data         ;

    // always @(posedge clk) begin
    //     if (~tx_flag && uart_tx_en)
    //         uart_tx_data_d1 <= uart_tx_data;
    //     else if (baud_cnt == BAUD_CNT_MAX && bit_cnt <= DATA_WIDTH - 1)
    //         uart_tx_data_d1 <= uart_tx_data_d1 >> 1;                // 每发一位右移，取最低位
    // end
    always @(posedge clk) begin
        if (reset==0)begin
            uart_tx_data_d1 <= 0;
            pending_vld <= 1'b0;
            pending_data <= 0;  
        end
        else if (CHACK_TYPE==0 && baud_cnt == BAUD_CNT_MAX && bit_cnt ==DATA_WIDTH+STOP_BITS && pending_vld)begin
            uart_tx_data_d1 <= pending_data;
            pending_vld <= 1'b0;
        end
        else if (baud_cnt == BAUD_CNT_MAX && bit_cnt <= DATA_WIDTH - 1)begin
            uart_tx_data_d1 <= uart_tx_data_d1 >> 1;                // 每发一位右移，取最低位
        end
        else if(uart_tx_en)begin
            if(~tx_flag)begin
                uart_tx_data_d1<=uart_tx_data;
            end
            else if(CHACK_TYPE==0 && ~pending_vld)begin
                pending_data<=uart_tx_data;
                pending_vld<=1;
            end
        end
    end

    always @(posedge clk) begin
        if (reset==0)
            baud_cnt <= 0;
        else if (~tx_flag || baud_cnt == BAUD_CNT_MAX)
            baud_cnt <= 0;
        else if (tx_flag)
            baud_cnt <= baud_cnt + 1'b1;
    end

    // always @(posedge clk) begin
    //     if (reset==0)
    //         bit_cnt <= 4'd0;
    //     else if (~tx_flag)
    //         bit_cnt <= 4'd0;
    //     else if (baud_cnt == BAUD_CNT_MAX)
    //         bit_cnt <= bit_cnt + 1'b1;
    //     else
    //         bit_cnt <= bit_cnt;
    // end
    always @(posedge clk) begin
        if (reset==0)
            bit_cnt <= 4'd0;
        else if (~tx_flag)
            bit_cnt <= 4'd0;
        else if (baud_cnt == BAUD_CNT_MAX && CHACK_TYPE==0 && bit_cnt==DATA_WIDTH+STOP_BITS && pending_vld)
            bit_cnt <= 4'd0;
        else if(baud_cnt == BAUD_CNT_MAX)
            bit_cnt <= bit_cnt + 1'b1;   
        else
            bit_cnt <= bit_cnt;
    end
    generate
        if (CHACK_TYPE == 0) begin

            always @(posedge clk) begin
                if (reset==0)
                    tx_flag <= 1'b0;
                // else if (bit_cnt == DATA_WIDTH + STOP_BITS && baud_cnt == BAUD_CNT_MAX  )
                else if (bit_cnt == DATA_WIDTH + STOP_BITS && baud_cnt == BAUD_CNT_MAX && ~pending_vld)
                    tx_flag <= 1'b0;
                // else if (uart_tx_en )
                else if (uart_tx_en || pending_vld)   
                    tx_flag <= 1'b1;
            end

            always @(posedge clk) begin
                if (reset==0)
                    uart_txd <= 1'b1;                               // 空闲状态，高电平
                else if (uart_tx_en && ~tx_flag)
                    uart_txd <= 1'b0;                               // 发送起始位
                else if (baud_cnt == BAUD_CNT_MAX  && bit_cnt==DATA_WIDTH+STOP_BITS && pending_vld)
                    uart_txd <= 1'b0;  
                else if (baud_cnt == BAUD_CNT_MAX && bit_cnt <= DATA_WIDTH - 1)
                    uart_txd <= uart_tx_data_d1[0];                 // 发送数据位
                else if (baud_cnt == BAUD_CNT_MAX && bit_cnt >= DATA_WIDTH && bit_cnt <= DATA_WIDTH + STOP_BITS - 1)
                    uart_txd <= 1'b1;                               // 发送停止位
            end

        end else if (CHACK_TYPE == 1) begin
    logic                                tx_chack                 ;

            always @(posedge clk) begin
                if (reset==0)
                    tx_chack <= 1'b0;
                else if (bit_cnt == DATA_WIDTH + 2)
                    tx_chack <= 1'b0;
                else if (bit_cnt <= DATA_WIDTH - 1 && baud_cnt == BAUD_CNT_MAX_HALF)
                    tx_chack <= tx_chack ^ uart_tx_data_d1[0];      // 逐位异或得奇偶信息
            end

            always @(posedge clk) begin
                if (reset==0)
                    tx_flag <= 1'b0;
                else if (bit_cnt == DATA_WIDTH + STOP_BITS + 1 && baud_cnt == BAUD_CNT_MAX)
                    tx_flag <= 1'b0;
                else if (uart_tx_en)
                    tx_flag <= 1'b1;
            end

            always @(posedge clk) begin
                if (reset==0)
                    uart_txd <= 1'b1;                               // 空闲状态
                else if (~tx_flag && uart_tx_en)
                    uart_txd <= 1'b0;                               // 发送起始位
                else if (baud_cnt == BAUD_CNT_MAX && bit_cnt <= DATA_WIDTH - 1)
                    uart_txd <= uart_tx_data_d1[0];                 // 发送数据位
                else if (baud_cnt == BAUD_CNT_MAX && bit_cnt == DATA_WIDTH)
                    uart_txd <= tx_chack;                           // 发送奇校验位
                else if (baud_cnt == BAUD_CNT_MAX && bit_cnt >= DATA_WIDTH + 1 &&
                         bit_cnt <= DATA_WIDTH + STOP_BITS)
                    uart_txd <= 1'b1;                               // 发送停止位
            end

        end else if (CHACK_TYPE == 2) begin
    logic                                tx_chack                 ;

            always @(posedge clk) begin
                if (reset==0)
                    tx_chack <= 1'b0;
                else if (bit_cnt == DATA_WIDTH + 2)
                    tx_chack <= 1'b0;
                else if (bit_cnt <= DATA_WIDTH - 1 && baud_cnt == BAUD_CNT_MAX_HALF)
                    tx_chack <= tx_chack ^ uart_tx_data_d1[0];
            end

            always @(posedge clk) begin
                if (reset==0)
                    tx_flag <= 1'b0;
                else if (bit_cnt == DATA_WIDTH + STOP_BITS + 1 && baud_cnt == BAUD_CNT_MAX)
                    tx_flag <= 1'b0;
                else if (uart_tx_en)
                    tx_flag <= 1'b1;
            end

            always @(posedge clk) begin
                if (reset==0)
                    uart_txd <= 1'b1;                               // 空闲状态
                else if (~tx_flag && uart_tx_en)
                    uart_txd <= 1'b0;                               // 发送起始位
                else if (baud_cnt == BAUD_CNT_MAX && bit_cnt <= DATA_WIDTH - 1)
                    uart_txd <= uart_tx_data_d1[0];                 // 发送数据位
                else if (baud_cnt == BAUD_CNT_MAX && bit_cnt == DATA_WIDTH)
                    uart_txd <= ~tx_chack;                          // 发送偶校验位
                else if (baud_cnt == BAUD_CNT_MAX && bit_cnt >= DATA_WIDTH + 1 &&
                         bit_cnt <= DATA_WIDTH + STOP_BITS)
                    uart_txd <= 1'b1;                               // 发送停止位
            end

        end
    endgenerate


    always @(posedge clk) begin
        if (reset==0)
            uart_tx_busy <= 1'b0;
        else
            uart_tx_busy <= tx_flag;
    end

    ila_tx ila_tx_inst (
    .clk                                (clk                       ), // input wire clk
    .probe0                             (uart_txd                  ), // input wire [0:0]  probe0  
    .probe1                             (uart_tx_data              ), // input wire [7:0]  probe1 
    .probe2                             (uart_tx_en                ), // input wire [0:0]  probe2 
    .probe3                             (uart_tx_busy              ), // input wire [0:0]  probe3 
    .probe4                             (uart_tx_data_d1           ), // input wire [7:0]  probe4 
    .probe5                             (baud_cnt                  ), // input wire [14:0]  probe5 
    .probe6                             (bit_cnt                   ), // input wire [3:0]  probe6 
    .probe7                             (tx_flag                   ) // input wire [0:0]  probe7
);
endmodule