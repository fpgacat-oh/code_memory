module SYS_TOP(
    input  logic       clk_50M ,
    // output logic [3:0] led_out ,
    input  logic       uart_rxd,
    output logic       uart_txd
);
 

    parameter CNT_MAX    = 10_0000_0000;
    parameter CLK_FREQ   = 50000000   ;
    parameter BAUD_RATE  = 115200      ;
    parameter DATA_WIDTH = 8           ;
    parameter STOP_BITS  = 1           ;
    parameter CHACK_TYPE = 0           ;

    logic clk_125M    ;
    logic clk_100M    ;
    logic reset_125M  ;
    logic reset_100M  ;
    logic dds_en      ;
    logic led_en      ;
    logic uart_send_en;

    // 时钟与复位：外部 50 MHz 晶振经 MMCM 派生 100 MHz / 125 MHz
    clk_reset U0(
        .clk_sys    (clk_50M   ),
        // .clk_125M   (clk_125M  ),
        .clk_100M   (clk_100M  ),
        // .reset_125M (reset_125M),
        .reset (reset_100M)
    );


    // 串口收发物理层
    logic [DATA_WIDTH-1:0] uart_tx_data;
    logic [DATA_WIDTH-1:0] uart_rx_data;
    logic                  uart_rx_en  ;
    logic                  uart_tx_en  ;
    logic                  uart_tx_busy;

    uart_top #(
        .CLK_FREQ   (CLK_FREQ  ),
        .BAUD_RATE  (BAUD_RATE ),
        .DATA_WIDTH (DATA_WIDTH),
        .STOP_BITS  (STOP_BITS),
        .CHACK_TYPE (CHACK_TYPE)
    ) U1(
        .clk          (clk_100M    ),
        .reset        (~reset_100M  ),
        .uart_rxd     (uart_rxd    ),
        .uart_txd     (uart_txd    ),
        .uart_rx_en   (uart_rx_en  ),
        .uart_rx_data (uart_rx_data),
        .uart_tx_en   (uart_tx_en  ),
        .uart_tx_data (uart_tx_data),
        .uart_tx_busy (uart_tx_busy)
    );

assign uart_tx_en=uart_rx_en;
assign uart_tx_data=uart_rx_data;
    // // 串口命令解析：把收到的字节解析成寄存器写
    // uart_analysis U4(
    //     .clk_100M   (clk_100M    ),
    //     .reset_100M (reset_100M  ),
    //     .uart_en    (uart_rx_en  ),
    //     .uart_data  (uart_rx_data),
    //     .dds_en     (dds_en      ),
    //     .led_en     (led_en      ),
    //     .uart_send  (uart_send_en)
    // );

endmodule