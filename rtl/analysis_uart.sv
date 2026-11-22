`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/16 22:05:32
// Design Name: 
// Module Name: analysis_uart
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


module analysis_uart(

    input clk,
    input reset,
    input [7:0] uart_data,
    input uart_en
    );

logic [15:0] shift_uart; 
always@(posedge clk)begin
    if(reset==0)begin
        shift_uart<=0;
    end
    else if(uart_en)begin
        shift_uart<={shift_uart[7:0],uart_data};
    end
end

logic flag;
logic [15:0] cnt_data;
always @(posedge clk )           
    begin                                        
        if(reset==0)                               
            flag<=0; 
        else if(cnt_data==7)begin
            flag<=0; 
        end                                 
        else if(shift_uart==16'hFF55)                                
            flag<=1;                                  
        else
            flag<=flag;                                    
    end


    always @(posedge clk)           
        begin                                        
            if(reset==0)                               
               cnt_data<=0; 
            else if(flag==0)begin
                cnt_data<=0
            end                                    
            else if(uart_en && flag)begin                               
               cnt_data<=cnt_data+1'b1  ;
            end                                       
            else
                cnt_data<=cnt_data;                                     
        end                                          
                                         
endmodule
