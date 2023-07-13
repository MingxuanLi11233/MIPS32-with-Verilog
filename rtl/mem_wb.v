`timescale 1ns / 1ps
`include "define.v"

// mem_wb 流水线寄存器
module mem_wb(
    
    // mem_wb 的输入
    input   wire                clk,
    input   wire                rst,
    input   wire[`RegAddrBus]   mem_wd,
    input   wire                mem_wreg,
    input   wire[`RegBus]       mem_wdata,
    // 与HILO相关的输入
    input   wire[`RegBus]       mem_hi,
    input   wire[`RegBus]       mem_lo,
    input   wire                mem_whilo,


    // mem_wb 的输出
    output  reg[`RegAddrBus]    wb_wd,
    output  reg                 wb_wreg,
    output  reg[`RegBus]        wb_wdata,
    // 与HILO相关的输出 
    output   reg[`RegBus]       wb_hi,
    output   reg[`RegBus]       wb_lo,
    output   reg                wb_whilo


    );

    always @ (posedge clk) begin
        if(rst == `RstEnable) begin
            wb_wd    <= `NOPRegAddr;
            wb_wreg  <= `WriteDisable;
            wb_wdata <= `ZeroWord;
        end else begin
            wb_wd       <= mem_wd;
            wb_wreg     <= mem_wreg;
            wb_wdata    <= mem_wdata;
            wb_hi       <= mem_hi;
            wb_lo       <= mem_lo;
            wb_whilo    <= mem_whilo;
        end
    end
endmodule
