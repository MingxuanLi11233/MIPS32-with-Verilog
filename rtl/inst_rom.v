`timescale 1ns / 1ps
`include "define.v"

module inst_rom(
    input   wire[`InstAddrBus]     addr,
    input   wire                   ce,
    output  reg[`InstBus]        inst
    );

    reg[`InstBus]   inst_mem[0: `InstMemNum-1];

    // initial begin
    // inst_mem[0]=      32'h34011100;
    // inst_mem[1]=      32'h34210020;
    // inst_mem[2]=      32'h34214400;
    // inst_mem[3]=      32'h34210044;
    // end
    initial $readmemh ("F:/Programm_File/Xilinx/Project_self/Vivado/CPU/Five_level_CPU/rtl/inst_rom.data", inst_mem);
    
    always @ (*) begin
        if(ce == `ChipDisable) begin
            inst <= `ZeroWord;
        end else begin
            inst <= inst_mem[addr[`InstMemNumLog2+1:2]];
        end
    end


endmodule
