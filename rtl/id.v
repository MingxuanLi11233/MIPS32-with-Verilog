`timescale 1ns / 1ps
`include "define.v"


module id(
    input   wire                    rst,
    input   wire[`InstAddrBus]      pc_i,
    input   wire[`InstBus]          inst_i,
    // ID阶段读出的寄存器内容，通过ID传到流水线
    input   wire[`RegBus]           reg1_data_i,
    input   wire[`RegBus]           reg2_data_i,
    // ID阶段读取寄存器堆的信号，对应两个端口，包括使能信号和读地址
    output  reg                 reg1_read_o,
    output  reg[`RegAddrBus]    reg1_addr_o,
    output  reg                 reg2_read_o,
    output  reg[`RegAddrBus]    reg2_addr_o,
    // ID阶段分析出的指令的写寄存器信息，使能信号和写地址，数据在后面决定
    output  reg[`RegAddrBus]    wd_o,
    output  reg                 wreg_o,
    // 指令类型和子类型
    output  reg[`AluOpBus]      aluop_o,
    output  reg[`AluSelBus]     alusel_o,
    // 读出的寄存器内容，传递给下一个阶段
    output  reg[`RegBus]    reg1_o,
    output  reg[`RegBus]    reg2_o,
    // 处理ex型数据相关，数据前推判断信息的输入
    input   wire[`RegAddrBus]  ex_wd_i,
    input   wire               ex_wreg_i,
    input   wire[`RegBus]      ex_wdata_i,
    input   wire[`RegAddrBus]  mem_wd_i,
    input   wire               mem_wreg_i,
    input   wire[`RegBus]      mem_wdata_i
);

    //取得指令的指令码，功能码
    wire[5:0]   op  = inst_i[31:26];
    wire[4:0]   op2 = inst_i[10:6];
    wire[5:0]   op3 = inst_i[5:0];
    wire[4:0]   op4 = inst_i[20:16];

    //保存指令执行需要的立即数
    reg[`RegBus]    imm;

    //指示指令是否有效
    reg instvalid;


    //**********************对指令进行译码*********************//
    always @ (*) begin
        if(rst == `RstEnable) begin
            aluop_o     <=  `EXE_NOP_OP;
            alusel_o    <=  `EXE_RES_NOP;
            wd_o        <=  `NOPRegAddr;
            wreg_o      <=  `WriteDisable;
            instvalid   <=  `InstValid;
            reg1_read_o <=  1'b0;
            reg2_read_o <=  1'b0;
            reg1_addr_o <=  `NOPRegAddr;
            reg2_addr_o <=  `NOPRegAddr;
            imm         <=  `ZeroWord;
        end else begin      // 设置一下wd，以及两个读地址，其余全部归零
            aluop_o     <=  `EXE_NOP_OP;
            alusel_o    <=  `EXE_RES_NOP;
            wd_o        <=  inst_i[15:11];
            wreg_o      <=  `WriteDisable;
            instvalid   <=  `InstInvalid;
            reg1_read_o <=  1'b0;
            reg2_read_o <=  1'b0;
            reg1_addr_o <=  inst_i[25:21];
            reg2_addr_o <=  inst_i[20:16];
            imm         <=  `ZeroWord;
            // op condition 1
            // *********** ALU imm类型的八条指令 *********** //
            if((op & `ALU_IMM_OP_MASK) == `ALU_IMM_OP) begin
                reg1_read_o <= 1'b1;
                reg2_read_o <= 1'b0;
                wd_o        <= inst_i[20:16];
                wreg_o      <= `WriteEnable;    
                instvalid   <= `InstValid;
                imm         <= {16'h0, inst_i[15:0]};
                // 在八条指令内进一步判断(4/8)
                case(op)
                    `EXE_ADDI:  begin
                        imm         <= {{16{inst_i[15]}}, inst_i[15:0]};
                        aluop_o     <= `EXE_ADDI_OP;
                        alusel_o    <= `EXE_RES_ARITHMETIC;
                    end
                    `EXE_ADDIU: begin
                        imm         <= {{16{inst_i[15]}}, inst_i[15:0]};
                        aluop_o     <= `EXE_ADDIU_OP;
                        alusel_o    <= `EXE_RES_ARITHMETIC;
                    end
                    `EXE_SLTI:  begin
                        imm         <= {{16{inst_i[15]}}, inst_i[15:0]};
                        aluop_o     <= `EXE_SLT_OP;
                        alusel_o    <= `EXE_RES_ARITHMETIC;
                    end
                    `EXE_SLTIU: begin
                        imm         <= {{16{inst_i[15]}}, inst_i[15:0]};
                        aluop_o     <= `EXE_SLTU_OP;
                        alusel_o    <= `EXE_RES_ARITHMETIC;
                    end
                    `EXE_ORI:   begin
                        aluop_o     <= `EXE_OR_OP;
                        alusel_o    <=  `EXE_RES_LOGIC;
                    end
                    `EXE_ANDI:  begin
                        aluop_o     <= `EXE_AND_OP;
                        alusel_o    <=  `EXE_RES_LOGIC;
                    end
                    `EXE_XORI:  begin
                        aluop_o     <= `EXE_XOR_OP;
                        alusel_o    <=  `EXE_RES_LOGIC;
                    end
                    `EXE_LUI:   begin
                        imm         <= {inst_i[15:0], 16'h0};
                        aluop_o     <= `EXE_OR_OP;
                        alusel_o    <=  `EXE_RES_LOGIC;
                    end
                    default: begin
                    end
                endcase
            // op condition 2
            // ************** op为0 SPRCIAL *************** //
            end else if(op == `EXE_SPECIAL_INST) begin
                case(op3[5:3])
                    // 000：
                    `SPECIAL_FIRST_ROW: begin
                        reg1_read_o     <= 1'b1;
                        reg2_read_o     <= 1'b1;
                        instvalid       <= `InstValid;
                        wreg_o          <= `WriteEnable;
                        case(op3)
                        `EXE_SLL:   begin
                            wreg_o      <= `WriteEnable;
                            aluop_o     <= `EXE_SLL_OP;
                            alusel_o    <= `EXE_RES_SHIFT;
                            reg1_read_o <= 1'b0;
                            reg2_read_o <= 1'b1;
                            imm[4:0]    <= inst_i[10:6];
                            wd_o        <= inst_i[15:11];
                            instvalid   <= `InstValid;
                        end
                        `EXE_SRL:   begin
                            wreg_o      <= `WriteEnable;
                            aluop_o     <= `EXE_SRL_OP;
                            alusel_o    <= `EXE_RES_SHIFT;
                            reg1_read_o <= 1'b0;
                            reg2_read_o <= 1'b1;
                            imm[4:0]    <= inst_i[10:6];
                            wd_o        <= inst_i[15:11];
                            instvalid   <= `InstValid;
                        end
                        `EXE_SRA:   begin
                            wreg_o      <= `WriteEnable;
                            aluop_o     <= `EXE_SRA_OP;
                            alusel_o    <= `EXE_RES_SHIFT;
                            reg1_read_o <= 1'b0;
                            reg2_read_o <= 1'b1;
                            imm[4:0]    <= inst_i[10:6];
                            wd_o        <= inst_i[15:11];
                            instvalid   <= `InstValid;
                        end
                        `EXE_SLLV:  begin
                            aluop_o     <= `EXE_SLL_OP;
                            alusel_o    <= `EXE_RES_SHIFT;
                        end
                        `EXE_SRLV:  begin
                            aluop_o     <= `EXE_SRL_OP;
                            alusel_o    <= `EXE_RES_SHIFT;
                        end
                        `EXE_SRAV:  begin
                            aluop_o     <= `EXE_SRA_OP;
                            alusel_o    <= `EXE_RES_SHIFT;
                        end
                        default:    begin
                            wd_o        <=  `NOPRegAddr;
                            reg1_addr_o <=  `NOPRegAddr;
                            reg2_addr_o <=  `NOPRegAddr;
                        end
                        endcase
                    end
                    `SPECIAL_SECOND_ROW: begin
                        case(op3)
                        `EXE_MOVZ:  begin
                            aluop_o     <= `EXE_MOVZ_OP;
                            alusel_o    <= `EXE_RES_MOVE;
                            reg1_read_o <=  1'b1;
                            reg2_read_o <=  1'b1;
                            instvalid   <=  `InstValid;
                            wreg_o      <= (reg2_o == `ZeroWord)? 
                                            `WriteEnable: `WriteDisable;
                        end
                        `EXE_MOVN:  begin
                            aluop_o     <= `EXE_MOVZ_OP;
                            alusel_o    <= `EXE_RES_MOVE;
                            reg1_read_o <=  1'b1;
                            reg2_read_o <=  1'b1;
                            instvalid   <=  `InstValid;
                            wreg_o      <= (reg2_o != `ZeroWord)? 
                                            `WriteEnable: `WriteDisable;
                        end
                        `EXE_SYNC:  begin
                            wreg_o      <= `WriteDisable;
                            aluop_o     <= `EXE_NOP_OP;
                            alusel_o    <= `EXE_RES_NOP;
                            reg1_read_o <= 1'b0;
                            reg2_read_o <= 1'b0;
                            instvalid   <= `InstValid;
                        end
                        endcase
                    end
                    // 010: HI LO
                    `SPECIAL_THIRD_ROW: begin
                        alusel_o <= `EXE_RES_MOVE;
                        case(op3)
                        `EXE_MFHI: begin
                            wreg_o    <= `WriteEnable;
                            aluop_o   <= `EXE_MFHI_OP;
                            instvalid <= `InstValid;
                        end
                        `EXE_MTHI: begin
                            reg1_read_o <=  1'b1;
                            aluop_o   <= `EXE_MTHI_OP;
                            instvalid <= `InstValid;
                        end
                        `EXE_MFLO: begin
                            wreg_o    <= `WriteEnable;
                            aluop_o   <= `EXE_MFLO_OP;
                            instvalid <= `InstValid;
                        end
                        `EXE_MTLO: begin
                            reg1_read_o <=  1'b1;
                            aluop_o   <= `EXE_MTLO_OP;
                            instvalid <= `InstValid;
                        end
                        endcase
                    end
                    // 011：乘除
                    `SPECIAL_FORTH_ROW: begin
                    end
                    // 100：完成 5、6行是同类
                    `SPECIAL_FIFTH_ROW: begin
                        reg1_read_o     <= 1'b1;
                        reg2_read_o     <= 1'b1;
                        instvalid       <= `InstValid;
                        wreg_o          <= `WriteEnable;
                        case(op3)
                        `EXE_ADD:   begin
                            aluop_o     <= `EXE_ADD_OP;
                            alusel_o    <= `EXE_RES_ARITHMETIC;
                        end   
                        `EXE_ADDU:  begin
                            aluop_o     <= `EXE_ADDU_OP;
                            alusel_o    <= `EXE_RES_ARITHMETIC;
                        end  
                        `EXE_SUB:   begin
                            aluop_o     <= `EXE_SUB_OP;
                            alusel_o    <= `EXE_RES_ARITHMETIC;
                        end  
                        `EXE_SUBU:  begin
                            aluop_o     <= `EXE_SUBU_OP;
                            alusel_o    <= `EXE_RES_ARITHMETIC;
                        end
                        `EXE_OR:    begin
                            aluop_o     <= `EXE_OR_OP;
                            alusel_o    <= `EXE_RES_LOGIC;
                        end
                        `EXE_AND:   begin
                            aluop_o     <= `EXE_AND_OP;
                            alusel_o    <= `EXE_RES_LOGIC;
                        end
                        `EXE_XOR:   begin
                            aluop_o     <= `EXE_XOR_OP;
                            alusel_o    <= `EXE_RES_LOGIC;
                        end
                        `EXE_NOR:   begin
                            aluop_o     <= `EXE_NOR_OP;
                            alusel_o    <= `EXE_RES_LOGIC;
                        end
                        default:    begin
                            wd_o        <=  `NOPRegAddr;
                            reg1_addr_o <=  `NOPRegAddr;
                            reg2_addr_o <=  `NOPRegAddr;
                        end
                        endcase
                    end
                    // 101：完成
                    `SPECIAL_SIXTH_ROW: begin
                        reg1_read_o     <= 1'b1;
                        reg2_read_o     <= 1'b1;
                        instvalid       <= `InstValid;
                        wreg_o          <= `WriteEnable;
                        case(op3)
                        `EXE_SLT:   begin
                            aluop_o     <= `EXE_SLT_OP;
                            alusel_o    <= `EXE_RES_ARITHMETIC;
                        end 
                        `EXE_SLTU:   begin
                            aluop_o     <= `EXE_SLTU_OP;
                            alusel_o    <= `EXE_RES_ARITHMETIC;
                        end
                        endcase
                    end
                    `SPECIAL_SEVENTH_ROW: begin
                    end
                    `SPECIAL_EIGHTH_ROW: begin
                    end
                    default: begin
                    end
                endcase

                if(inst_i == `ZeroWord) begin
                    wreg_o      <= `WriteEnable;
                    aluop_o     <= `EXE_NOP_OP;
                    alusel_o    <= `EXE_RES_NOP;
                    reg1_read_o <= 1'b0;
                    reg2_read_o <= 1'b0;
                    instvalid   <= `InstInvalid;
                end
            // ****************  SPRCIAL2 **************** //
            end else if(op == `EXE_SPECIAL2_INST) begin
                case(op3)

                endcase
            // other conditions: reserved
            end else begin
                //********预留*******//
            end
        end
    end

    //**********************确定源操作数1*********************//
    always @ (*) begin
        if(rst == `RstEnable) begin
            reg1_o <= `ZeroWord;
        end else if ((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1)
                    && (reg1_addr_o == ex_wd_i)) begin   // 寄存器读端口1使能
            reg1_o <= ex_wdata_i;
        end else if ((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1)
                    && (reg1_addr_o == mem_wd_i)) begin
            reg1_o <= mem_wdata_i;
        end else if (reg1_read_o == 1'b1) begin
            reg1_o <= reg1_data_i;
        end else if (reg1_read_o == 1'b0) begin   // 寄存器读端口1关闭
            reg1_o <= imm; 
        end else begin
            reg1_o <= `ZeroWord;
        end
    end

    //**********************确定源操作数2*********************//
    always @ (*) begin
        if(rst == `RstEnable) begin
            reg2_o <= `ZeroWord;
        end else if ((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1)
                    && (reg2_addr_o == ex_wd_i)) begin
            reg2_o <= ex_wdata_i;
        end else if ((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1)
                    && (reg2_addr_o == mem_wd_i)) begin
            reg2_o <= mem_wdata_i;
        end else if (reg2_read_o == 1'b1) begin
            reg2_o <= reg2_data_i;
        end else if(reg2_read_o == 1'b0) begin
            reg2_o <= imm;
        end else begin
            reg2_o <= `ZeroWord;
        end
    end

endmodule
