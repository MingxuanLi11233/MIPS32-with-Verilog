`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/08 12:24:17
// Design Name: 
// Module Name: rom
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


module rom(

    input   wire[5:0]   addr,
    input   wire        ce,
    output  reg[31:0]   inst

    );

    reg[31:0]   rom[63:0];

    initial begin
    rom[0]=      32'h00000000;
    rom[1]=      32'h01010101;
    rom[2]=      32'h02020202;
    rom[3]=      32'h03030303;
    rom[4]=      32'h04040404;
    rom[5]=      32'h05050505;
    rom[6]=      32'h06060606;
    rom[7]=      32'h07070707;
    rom[8]=      32'h08080808;
    rom[9]=      32'h09090909;
    rom[10]=     32'h10101010;
    rom[11]=     32'h11111111;
    end

    always @ (*)
    begin
        if (ce == 1'b0)
        begin
            inst <= 32'h012345;
        end
        else
        begin
            inst <= rom[addr];
        end
    end
endmodule
