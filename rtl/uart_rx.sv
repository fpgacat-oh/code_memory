`timescale 1ns / 1ps
module uart_rx #(
    parameter                           CLK_FREQ                    = 50000000             , // 时钟频率
    parameter                           BAUD_RATE                   = 115200               , // 波特率
    parameter                           DATA_WIDTH                  = 8                    , // 数据位宽
    parameter                           STOP_BITS                   = 1                    , // 停止位宽 1 或 2
    parameter                           CHACK_TYPE                  = 0 // 0 无校验；1 奇校验；2 偶校验
)(
    input  logic                           clk                        ,
    input  logic                           reset                      ,
    input  logic                           uart_rxd                   , // 串口接收 RX
    output logic                           uart_rx_en                 , // 接收数据使能（单拍脉冲）
    output logic          [DATA_WIDTH-1:0] uart_rx_data               // 接收的数据
);

    localparam                          BAUD_CNT_MAX                = CLK_FREQ / BAUD_RATE ; // 复位之前已经计算好了，只需要计算一次
    localparam                          BAUD_CNT_MAX_HALF           = BAUD_CNT_MAX / 2     ; // 同上

   logic                                            uart_rxd_d0              ;
   logic                                            uart_rxd_d1              ;
   logic                                            rx_flag                  ;
   logic                  [$clog2(BAUD_CNT_MAX)-1:0]baud_cnt                 ;
   logic                  [   3:0]                  bit_cnt                  ;


    always @(posedge clk) begin
        uart_rxd_d0 <= uart_rxd;
        uart_rxd_d1 <= uart_rxd_d0;
    end


    always @(posedge clk) begin
        if (reset)
            baud_cnt <= 13'd0;
        else if (~rx_flag || baud_cnt == BAUD_CNT_MAX)
            baud_cnt <= 13'd0;
        else if (rx_flag)
            baud_cnt <= baud_cnt + 1'b1;
        else
            baud_cnt <= baud_cnt;
    end

    always @(posedge clk) begin
        if (reset)
            bit_cnt <= 'd0;
        else if (~rx_flag)
            bit_cnt <= 'd0;
        else if (baud_cnt == BAUD_CNT_MAX)
            bit_cnt <= bit_cnt + 1'b1;
        else
            bit_cnt <= bit_cnt;
    end

    always @(posedge clk) begin
        if (bit_cnt >= 1 && bit_cnt <= DATA_WIDTH && baud_cnt == BAUD_CNT_MAX_HALF)
            uart_rx_data <= {uart_rxd_d1, uart_rx_data[DATA_WIDTH-1:1]};
        else
            uart_rx_data <= uart_rx_data;
    end

    generate
        if (CHACK_TYPE == 0) begin

            // 起始位下降沿置位，整帧收完清零
            always @(posedge clk) begin
                if (baud_cnt == BAUD_CNT_MAX && bit_cnt == DATA_WIDTH )
                    rx_flag <= 1'b0;
                else if (~uart_rxd_d0 && uart_rxd_d1)
                    rx_flag <= 1'b1;
            end

            always @(posedge clk) begin
                if (reset)
                    uart_rx_en <= 1'b0;
                else if (baud_cnt == BAUD_CNT_MAX_HALF + 2 && bit_cnt == DATA_WIDTH )
                    uart_rx_en <= 1'b1;
                else
                    uart_rx_en <= 1'b0;
            end

        end
        else if (CHACK_TYPE == 1) begin
    reg                                 rx_chack                 ;

            always @(posedge clk) begin
                if (baud_cnt == BAUD_CNT_MAX && bit_cnt == DATA_WIDTH + 1)
                    rx_flag <= 1'b0;
                else if (~uart_rxd_d0 && uart_rxd_d1)
                    rx_flag <= 1'b1;
            end

            always @(posedge clk) begin
                if (reset)
                    rx_chack <= 1'b0;
                else if (baud_cnt == BAUD_CNT_MAX && bit_cnt == DATA_WIDTH + 1)
                    rx_chack <= 1'b0;
                else if (bit_cnt >= 1 && bit_cnt <= DATA_WIDTH + 1 && baud_cnt == BAUD_CNT_MAX_HALF)
                    rx_chack <= rx_chack ^ uart_rxd_d1;
            end

            always @(posedge clk) begin
                if (reset)
                    uart_rx_en <= 1'b0;
                else if (baud_cnt == BAUD_CNT_MAX_HALF + 2 && bit_cnt == DATA_WIDTH + 1 && rx_chack)
                    uart_rx_en <= 1'b1;
                else
                    uart_rx_en <= 1'b0;
            end

        end
        else if (CHACK_TYPE == 2) begin
    reg                                 rx_chack                 ;

            always @(posedge clk) begin
                if (baud_cnt == BAUD_CNT_MAX && bit_cnt == DATA_WIDTH + 1)
                    rx_flag <= 1'b0;
                else if (~uart_rxd_d0 && uart_rxd_d1)
                    rx_flag <= 1'b1;
            end

            always @(posedge clk) begin
                if (reset)
                    rx_chack <= 1'b0;
                else if (baud_cnt == BAUD_CNT_MAX && bit_cnt == DATA_WIDTH + 1)
                    rx_chack <= 1'b0;
                else if (bit_cnt >= 1 && bit_cnt <= DATA_WIDTH + 1 &&
                         baud_cnt == BAUD_CNT_MAX_HALF)
                    rx_chack <= rx_chack ^ uart_rxd_d1;
            end

            always @(posedge clk) begin
                if (reset)
                    uart_rx_en <= 1'b0;
                else if (baud_cnt == BAUD_CNT_MAX_HALF + 2 && bit_cnt == DATA_WIDTH + 1 && ~rx_chack)
                    uart_rx_en <= 1'b1;
                else
                    uart_rx_en <= 1'b0;
            end

        end
    endgenerate

    ila_rx ila_rx_inst (
	.clk(clk), // input wire clk
	.probe0(uart_rxd     ), // input wire [0:0]  probe0  
	.probe1(uart_rx_en   ), // input wire [0:0]  probe1 
	.probe2(uart_rx_data ), // input wire [7:0]  probe2 
	.probe3(uart_rxd_d0  ), // input wire [0:0]  probe3 
	.probe4(uart_rxd_d1  ), // input wire [0:0]  probe4 
	.probe5(rx_flag      ), // input wire [0:0]  probe5 
	.probe6(baud_cnt     ), // input wire [15:0]  probe6 
	.probe7(bit_cnt      ) // input wire [3:0]  probe7
);
endmodule