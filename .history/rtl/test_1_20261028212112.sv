`timescale 1ns / 1ps
//****************************************VSCODE PLUG-IN**********************************//
//----------------------------------------------------------------------------------------
// IDE :                   VSCODE
// VSCODE plug-in version: Verilog-Hdl-Format-4.9.20261007
// VSCODE plug-in author : Jiang Percy
//----------------------------------------------------------------------------------------
//****************************************Copyright (c)***********************************//
// Copyright(C)            Please Write Company name
// All rights reserved
// File name:
// Last modified Date:     2026/10/28 21:05:28
// Last Version:           V1.0
// Descriptions:
//----------------------------------------------------------------------------------------
// Created by:             Please Write You Name
// Created date:           2026/10/28 21:05:28
// mail      :             Please Write mail
// Version:                V1.0
// TEXT NAME:              test_1.sv
// PATH:                   D:\class\class_00\rtl\test_1.sv
// Descriptions:
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

// `define DATA_1
module test_1(
    input        clk     ,
    input        rst_n
    `ifdef DATA_1
    ,
    output [7:0] data_out
    `endif // DATA_1
    );

endmodule