`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/12 21:16:15
// Design Name: 
// Module Name: clk_reset
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clk_reset(

    input          logic                     clk_sys                    ,
    output         logic                     clk_100M                   ,
    output         logic                     reset                       //low
    );

clk_wiz_0 CLK_gen
   (
    .clk_out1                           (clk_100M                  ),
    .locked                             (locked                    ),
    .clk_in1                            (clk_sys                   ) 
);
    assign                              reset                       = locked               ;


endmodule
