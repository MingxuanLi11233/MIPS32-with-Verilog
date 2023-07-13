`timescale 1ns / 1ps
`include "define.v"

module openmips_min_sopc(
    input   wire    clk,
    input   wire    rst
    );

    wire[`InstAddrBus]    inst_addr;
    wire[`InstBus]        inst;
    wire                  rom_ce;
    openmips openmips0(
        .rst(rst),      .clk(clk),
        .rom_data_i(inst),
        .rom_addr_o(inst_addr),
        .rom_ce_o(rom_ce)
    );
    inst_rom inst_rom(
        .addr(inst_addr),
        .ce(rom_ce),
        .inst(inst)
    );
endmodule
