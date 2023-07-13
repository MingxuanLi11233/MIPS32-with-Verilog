`timescale 1ns / 1ps
`include "define.v"

module mem(
    // mem 模块的输入
    input   wire                rst,
    input   wire[`RegAddrBus]   wd_i,
    input   wire                wreg_i,
    input   wire[`RegBus]       wdata_i,
    // 与HILO相关的输入
    input   wire[`RegBus]       hi_i,
    input   wire[`RegBus]       lo_i,
    input   wire                whilo_i,


    // mem 模块的输出
    output  reg[`RegAddrBus]    wd_o,
    output  reg                 wreg_o,
    output  reg[`RegBus]        wdata_o,
    // 与HILO相关的输出
    output  reg[`RegBus]       hi_o,
    output  reg[`RegBus]       lo_o,
    output  reg                whilo_o



    );
    always @ (*) begin
        if(rst == `RstEnable) begin
            wd_o    <= `NOPRegAddr;
            wreg_o  <= `WriteDisable;
            wdata_o <= `ZeroWord;
        end else begin
            wd_o    <= wd_i;
            wreg_o  <= wreg_i;
            wdata_o <= wdata_i;
            hi_o    <= hi_i;
            lo_o    <= lo_i;
            whilo_o <= whilo_i;
        end
    end
endmodule
