`timescale 1ns / 1ps
`include "define.v"

module regfile(
    input   wire    clk,
    input   wire    rst,
    //写端口
    input   wire[`RegAddrBus]    waddr,
    input   wire[`RegBus]        wdata,
    input   wire                 we,
    //读端口1
    input   wire[`RegAddrBus]    raddr1,
    input   wire                 re1,
    output  reg[`RegBus]         rdata1,
    //读端口2
    input   wire[`RegAddrBus]    raddr2,
    input   wire                 re2,
    output  reg[`RegBus]         rdata2
    );

    //32个32位寄存器
    reg[`RegBus] regs[0:`RegNum-1];

    //写操作
    always @ (posedge clk) begin
        if(rst == `RstDisable) begin
            if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
                regs[waddr] <= wdata;
            end
        end
    end

    //读端口1的操作
    always @ (*) begin
        if(rst == `RstEnable) begin
            rdata1 <= `ZeroWord;
        end else if(raddr1 == `RegNumLog2'h0) begin
            rdata1 <= `ZeroWord;
        end else if((raddr1 == waddr) && (re1 == `ReadEnable) && (we == `WriteEnable)) begin
            rdata1 <= wdata;
        end else if(re1 == `ReadEnable) begin
            rdata1 <= regs[raddr1];
        end else begin
            rdata1 <= `ZeroWord;
        end
    end

    //读端口2的操作
    always @ (*) begin
        if(rst == `RstEnable) begin
            rdata2 <= `ZeroWord;
        end else if(raddr2 == `RegNumLog2'h0) begin
            rdata2 <= `ZeroWord;
        end else if((raddr2 == waddr) && (re2 == `ReadEnable) && (we == `WriteEnable)) begin
            rdata2 <= wdata;
        end else if(re2 == `ReadEnable) begin
            rdata2 <= regs[raddr2];
        end else begin
            rdata2 <= `ZeroWord;
        end
    end
endmodule
