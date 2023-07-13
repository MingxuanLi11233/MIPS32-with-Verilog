`timescale 1ns / 1ps
`include "define.v"

module ex(
    input   wire                rst,
    input   wire[`AluOpBus]     aluop_i,
    input   wire[`AluSelBus]    alusel_i,
    input   wire[`RegBus]       reg1_i,
    input   wire[`RegBus]       reg2_i,
    input   wire[`RegAddrBus]   wd_i,
    input   wire                wreg_i,
    // 与HI LO相关的输入
    input   wire[`RegBus]       hi_i,
    input   wire[`RegBus]       lo_i,
    input   wire[`RegBus]       mem_hi_i,
    input   wire[`RegBus]       mem_lo_i,
    input   wire                mem_whilo_i,
    input   wire[`RegBus]       wb_hi_i,
    input   wire[`RegBus]       wb_lo_i,
    input   wire                wb_whilo_i,


    output  reg[`RegAddrBus]   wd_o,
    output  reg                wreg_o,
    output  reg[`RegBus]       wdata_o,
    // 与HI LO相关的输出
    output  reg[`RegBus]       hi_o,
    output  reg[`RegBus]       lo_o,
    output  reg                whilo_o

    );

    reg[`RegBus] logicout;
    reg[`RegBus] shiftres;
    reg[`RegBus] arithmeticres;
    reg[`RegBus] moveres;
    reg[`RegBus] HI;
    reg[`RegBus] LO;

    // 算术运算中间结果
    wire            ov_sum;         // 溢出情况
    wire            reg1_eq_reg2;   // 第一个操作数是否等于第二个操作数
    wire            reg1_lt_reg2;   // 第一个操作数是否等于第二个操作数
    wire[`RegBus]   reg2_i_mux;     // 第二个操作数的补码
    wire[`RegBus]   reg2_i_not;     // 第一个操作数的反码
    wire[`RegBus]   result_sum;     // 加法结果


    // 算术运算：计算arithmrticres的值
    assign reg2_i_mux = ( (aluop_i == `EXE_SUB_OP) ||
                          (aluop_i == `EXE_SUBU_OP)||
                          (aluop_i == `EXE_SLT_OP) ||
                          (aluop_i == `EXE_SLTU_OP)||
                          (aluop_i == `EXE_SLTI_OP)||
                          (aluop_i == `EXE_SLTIU_OP) )? 
                          (~reg2_i)+1: reg2_i;
    // 和或差
    assign result_sum = reg1_i + reg2_i_mux;
    // 是否溢出
    assign ov_sum = ((!reg1_i[31] && !reg2_i_mux)&&(result_sum[31]))
                    || ((reg1_i[31] && reg2_i_mux)&&(!result_sum[31]));
    // 是否小于
    assign reg1_lt_reg2 = (aluop_i == `EXE_SLT_OP)?
                          ( (reg1_i[31] &&  !reg2_i[31])||
                            (reg1_i[31] &&   reg2_i[31] && result_sum[31])||
                            (!reg1_i[31] && !reg2_i[31] && result_sum[31])  ) // 有符号比较
                          :(reg1_i < reg2_i); // 无符号比较
    assign reg1_i_not = ~reg1_i;
    always @ (*) begin
        if(rst == `RstEnable) begin
            arithmeticres <= `ZeroWord;
        end else begin
            case(aluop_i)
                // 加减算术运算
                `EXE_ADD_OP,  `EXE_ADDI_OP,
                `EXE_ADDU_OP, `EXE_ADDIU_OP,
                `EXE_SUB_OP,  `EXE_SUBU_OP: begin
                    arithmeticres <= result_sum;
                end
                // 比较算术运算
                `EXE_SLT_OP,  `EXE_SLTU_OP: begin
                    arithmeticres <= reg1_lt_reg2;
                end
                // 预留
                default: begin
                    arithmeticres <= `ZeroWord;
                end
            endcase
        end
    end


    // 逻辑运算：计算logicout的值（因而同属log大类）
    always @ (*) begin
        if(rst == `RstEnable) begin
            logicout <= `ZeroWord;
        end else begin
            case(aluop_i)
                `EXE_OR_OP: begin
                    logicout <= (reg1_i | reg2_i);
                end
                `EXE_AND_OP: begin
                    logicout <= (reg1_i & reg2_i);
                end
                `EXE_XOR_OP: begin
                    logicout <= (reg1_i ^ reg2_i);
                end
                `EXE_NOR_OP: begin
                    logicout <= ~(reg1_i | reg2_i); 
                end
                default: begin
                    logicout <= `ZeroWord;
                end
            endcase
        end
    end


    // 移位运算
    always @ (*) begin
        if(rst == `RstEnable) begin
            shiftres <= `ZeroWord;
        end else begin
            case(aluop_i)
                `EXE_SLL_OP: begin
                    shiftres <= (reg2_i << reg1_i[4:0]);
                end
                `EXE_SRL_OP: begin
                    shiftres <= (reg2_i >> reg1_i[4:0]);
                end
                `EXE_SRA_OP: begin
                    shiftres <= (  ({32{reg2_i[31]}} << (6'd32-{1'b0, reg1_i[4:0]})) | 
                                        (reg2_i >> reg1_i[4:0])   );
                end
                default: begin
                    shiftres <= `ZeroWord;
                end
            endcase
        end
    end

    // 移动指令
    always @ (*) begin
        whilo_o <= `WriteDisable;
        if(rst == `RstEnable) begin
            moveres <= `ZeroWord;
        end else begin
            moveres <= `ZeroWord;
            case(aluop_i)
                `EXE_MFHI_OP: begin
                    moveres <= HI;
                end
                `EXE_MTHI_OP: begin
                    hi_o    <= reg1_i;
                    lo_o    <= LO;
                    whilo_o <= `WriteEnable;
                end
                `EXE_MFLO_OP: begin
                    moveres <= LO;
                end
                `EXE_MTLO_OP: begin
                    hi_o    <= HI;
                    lo_o    <= reg1_i;
                    whilo_o <= `WriteEnable;
                end
                `EXE_MOVZ_OP: begin
                    moveres <= reg1_i;
                end
                `EXE_MOVN_OP: begin
                    moveres <= reg1_i;
                end
            endcase
        end
    end

    // 确定HI，LO的值
    always @ (*) begin
        if(rst == `RstEnable) begin
            {HI, LO} <= {`ZeroWord, `ZeroWord};
        end else if(mem_whilo_i == `WriteEnable) begin
            {HI, LO} <= {mem_hi_i, mem_lo_i};
        end else if(wb_whilo_i == `WriteEnable) begin
            {HI, LO} <= {wb_hi_i, wb_lo_i};
        end else begin
            {HI, LO} <= {hi_i, lo_o};
        end
    end

    // 写入HI LO
    always @ (*) begin
        if(rst == `RstEnable) begin
            whilo_o     <= `WriteDisable;
            hi_o        <= `ZeroWord;
            lo_o        <= `ZeroWord;
        end else if(aluop_i == `EXE_MTHI_OP) begin
            whilo_o     <= `WriteEnable;
            hi_o        <= reg1_i;
            lo_o        <= LO;
        end else if(aluop_i == `EXE_MTLO_OP) begin
            whilo_o     <= `WriteEnable;
            hi_o        <= HI;
            lo_o        <= reg1_i;
        end else begin
            whilo_o     <= `WriteDisable;
            hi_o        <= `ZeroWord;
            lo_o        <= `ZeroWord;
        end
    end

    // 确定运算结果
    always @ (*) begin
        wd_o    <= wd_i;
        if( (ov_sum==1'b1) && 
            ( (aluop_i == `EXE_ADD_OP)||
              (aluop_i == `EXE_ADDI_OP)||
              (aluop_i == `EXE_SUB_OP) )  ) begin
            wreg_o  <= `WriteDisable;
        end else begin
            wreg_o  <= wreg_i;
        end
        case(alusel_i)
            `EXE_RES_LOGIC: begin
                wdata_o <= logicout;
            end
            `EXE_RES_SHIFT: begin
                wdata_o <= shiftres;
            end
            `EXE_RES_ARITHMETIC: begin
                wdata_o <= arithmeticres;
            end
            `EXE_RES_MOVE: begin
                wdata_o <= moveres;
            end
            default: begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end

endmodule
