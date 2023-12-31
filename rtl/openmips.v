`timescale 1ns / 1ps
`include "define.v"

module openmips(
    input   wire            rst,
    input   wire            clk,
    input   wire[`RegBus]   rom_data_i,     // 专指指令存储器
    output  wire[`RegBus]   rom_addr_o,
    output  wire            rom_ce_o
    );

    // 连接IF/ID模块与译码阶段ID模块的变量
    wire[`InstAddrBus]  pc;
    wire[`InstAddrBus]  id_pc_i;
    wire[`InstBus]      id_inst_i;

    // 连接ID模块与RegFile模块的变量
    wire                reg1_read;
    wire                reg2_read;
    wire[`RegAddrBus]   reg1_addr;
    wire[`RegAddrBus]   reg2_addr;
    wire[`RegBus]       reg1_data;
    wire[`RegBus]       reg2_data;

    // 连接ID模块与ID/EX模块的变量
    wire[`AluOpBus]     id_aluop_o;
    wire[`AluSelBus]    id_alusel_o;
    wire[`RegBus]       id_reg1_o;
    wire[`RegBus]       id_reg2_o;
    wire[`RegAddrBus]   id_wd_o;
    wire                id_wreg_o;

    // 连接ID_EX与EX的变量
    wire[`AluOpBus]      ex_aluop_i;
    wire[`AluSelBus]     ex_alusel_i;
    wire[`RegBus]        ex_reg1_i;
    wire[`RegBus]        ex_reg2_i;
    wire[`RegAddrBus]    ex_wd_i;
    wire                 ex_wreg_i;

    // 连接EX与HILO_reg的变量
    wire[`RegBus]       hi_data;
    wire[`RegBus]       lo_data;


    // 连接EX与EX/MEM的变量
    wire[`RegAddrBus]   ex_wd_o;
    wire                ex_wreg_o;
    wire[`RegBus]       ex_wdata_o;
    wire[`RegBus]       ex_hi_o;
    wire[`RegBus]       ex_lo_o;
    wire                ex_whilo_o;

    // 连接EX/MEM与MEM的变量
    wire[`RegAddrBus]   mem_wd_i;
    wire                mem_wreg_i;
    wire[`RegBus]       mem_wdata_i;
    wire[`RegBus]       mem_hi_i;
    wire[`RegBus]       mem_lo_i;
    wire                mem_whilo_i;

    // 连接MEM与MEM/WB的变量
    wire[`RegAddrBus]   mem_wd_o;
    wire                mem_wreg_o;
    wire[`RegBus]       mem_wdata_o;
    wire[`RegBus]       mem_hi_o;
    wire[`RegBus]       mem_lo_o;
    wire                mem_whilo_o;

    // 连接MEM/WB与回写阶段的变量
    wire[`RegAddrBus]   wb_wd_i;
    wire                wb_wreg_i;
    wire[`RegBus]       wb_wdata_i;

    // 连接MEM/WB与hilo_reg的变量
    wire[`RegBus]       hilo_hi_i;
    wire[`RegBus]       hilo_lo_i;
    wire                hilo_whilo_i;


    // pc_reg例化
    pc_reg pc_reg0(
        .clk(clk),  .rst(rst),  .pc(pc),    .ce(rom_ce_o)
    );

    // 外部接口
    assign rom_addr_o = pc;

    // IF/ID模块例化
    if_id if_id0(
        .clk(clk),  .rst(rst),  .if_pc(pc), .if_inst(rom_data_i),
        .id_pc(id_pc_i),    .id_inst(id_inst_i)
    );

    // 译码阶段ID模块例化
    id id0(
        .rst(rst),  .pc_i(id_pc_i),     .inst_i(id_inst_i),
        .reg1_data_i(reg1_data),        .reg2_data_i(reg2_data),

        .reg1_read_o(reg1_read),        .reg1_addr_o(reg1_addr),
        .reg2_read_o(reg2_read),        .reg2_addr_o(reg2_addr),
        
        .wd_o(id_wd_o),                 .wreg_o(id_wreg_o),
        .aluop_o(id_aluop_o),           .alusel_o(id_alusel_o),
        .reg1_o(id_reg1_o),             .reg2_o(id_reg2_o),
        // ex数据前推
        .ex_wd_i(ex_wd_o),              .ex_wreg_i(ex_wreg_o),
        .ex_wdata_i(ex_wdata_o),
        .mem_wd_i(mem_wd_i),            .mem_wreg_i(mem_wreg_i),
        .mem_wdata_i(mem_wdata_i)
    );

    // 通用存储器RegFile模块例化
    regfile regfile0(
        .clk(clk),              .rst(rst),
        .waddr(wb_wd_i),        .wdata(wb_wdata_i),
        .we(wb_wreg_i),
        .raddr1(reg1_addr),     .re1(reg1_read),      
        .rdata1(reg1_data),
        .raddr2(reg2_addr),     .re2(reg2_read),        
        .rdata2(reg2_data)
    );

    // ID/EX模块例化
    id_ex id_ex0(
        .clk(clk),                  .rst(rst),
        .id_aluop(id_aluop_o),      .id_alusel(id_alusel_o),
        .id_reg1(id_reg1_o),        .id_reg2(id_reg2_o),
        .id_wd(id_wd_o),            .id_wreg(id_wreg_o),
        

        .ex_aluop(ex_aluop_i),      .ex_alusel(ex_alusel_i),
        .ex_reg1(ex_reg1_i),        .ex_reg2(ex_reg2_i),
        .ex_wd(ex_wd_i),            .ex_wreg(ex_wreg_i)
    );

    // EX模块例化
    ex ex0(
        .rst(rst),
        .aluop_i(ex_aluop_i),       .alusel_i(ex_alusel_i),
        .reg1_i(ex_reg1_i),         .reg2_i(ex_reg2_i),
        .wd_i(ex_wd_i),             .wreg_i(ex_wreg_i),

        .hi_i(hi_data),        .lo_i(lo_data),
        .mem_hi_i(mem_hi_i),    .mem_lo_i(mem_lo_i),    
        .mem_whilo_i(mem_whilo_i),
        .wb_hi_i(hilo_hi_i),     .wb_lo_i(hilo_lo_i),     
        .wb_whilo_i(hilo_whilo_i),



        .wd_o(ex_wd_o),             .wreg_o(ex_wreg_o),
        .wdata_o(ex_wdata_o),
        .hi_o(ex_hi_o),             .lo_o(ex_lo_o),
        .whilo_o(ex_whilo_o)
    );

    // hilo_reg模块例化
    hilo_reg hilo_reg0(
        .clk(clk),                  .rst(rst),
        .we(hilo_whilo_i),          .hi_i(hilo_hi_i),   
        .lo_i(hilo_lo_i),

        .hi_o(hi_data),             .lo_o(lo_data)
    );

    // EX/MEM模块例化
    ex_mem ex_mem0(
        .clk(clk),                  .rst(rst),
        .ex_wd(ex_wd_o),            .ex_wreg(ex_wreg_o),
        .ex_wdata(ex_wdata_o),
        .ex_hi(ex_hi_o),            .ex_lo(ex_lo_o),
        .ex_whilo(ex_whilo_o),

        .mem_wd(mem_wd_i),          .mem_wreg(mem_wreg_i),
        .mem_wdata(mem_wdata_i),
        .mem_hi(mem_hi_i),      .mem_lo(mem_lo_i),
        .mem_whilo(mem_whilo_i)
    );

    // MEM模块例化
    mem mem0(
        .rst(rst),
        .wd_i(mem_wd_i),        .wreg_i(mem_wreg_i),
        .wdata_i(mem_wdata_i),
        .hi_i(mem_hi_i),    .lo_i(mem_lo_i),
        .whilo_i(mem_whilo_i),
        
        .wd_o(mem_wd_o),        .wreg_o(mem_wreg_o),
        .wdata_o(mem_wdata_o),
        .hi_o(mem_hi_o),        .lo_o(mem_lo_o),
        .whilo_o(mem_whilo_o)
    );

    // MEM/WB模块例化
    mem_wb mem_wb(
        .clk(clk),              .rst(rst),
        .mem_wd(mem_wd_o),      .mem_wreg(mem_wreg_o),
        .mem_wdata(mem_wdata_o),
        .mem_hi(mem_hi_o),      .mem_lo(mem_lo_o),
        .mem_whilo(mem_whilo_o),

        .wb_wd(wb_wd_i),        .wb_wreg(wb_wreg_i),
        .wb_wdata(wb_wdata_i),
        .wb_hi(hilo_hi_i), .wb_lo(hilo_lo_i),
        .wb_whilo(hilo_whilo_i)
    );
endmodule
