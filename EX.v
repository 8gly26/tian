module EX(
    input wire clk,
    input wire rst,
    input wire [31:0] operand1,       // 操作数1（寄存器数据）
    input wire [31:0] operand2,       // 操作数2（寄存器数据）
    input wire [31:0] imm_data,       // 立即数
    input wire blt,                // 是否为 BLT 指令
    input wire five_rs2,              // 是否为5位
    input wire slt_slti,             // 是否为 SLT 或 SLTI 指令
    input wire [15:0]pc_jal,        // JAL 指令的目标地址
    input wire [15:0] pc_addr,        // 当前 PC 地址
    input wire sra_R,                 // 是否为 SRA 指令
    input wire bltu,                // 是否为 BLTU 指令
    input wire srli,                // 是否为 SRLI 指令
    input wire srai_R,                // 是否为 SRAI 指令
    input wire [2:0] alu_control,     // ALU 控制信号
    input wire auipc,                // 是否为 AUIPC 指令
    input wire use_imm,               // 是否使用立即数作为操作数1
    input wire is_b_type,             // 是否为分支指令
    input wire bge,                // 是否为 BGE 指令
    input wire bgeu,               // 是否为 BGEU 指令
    input wire sltu_sltiu,         // 是否为 SLTU 或 SLTIU 指令
    input wire use_pc,                // 是否使用 PC 地址作为操作数2
    input wire [4:0] ex_dest,         // EX 阶段目标寄存器地址
    input wire is_jal,                // 是否为 JAL 指令
    input wire is_jalr,               // 是否为 JALR 指令
    input wire [4:0] mem_dest,        // MEM 阶段目标寄存器地址
    input wire [4:0] wb_dest,         // WB 阶段目标寄存器地址
    input wire ex_write_enable,       // EX 阶段写使能信号
    input wire mem_write_enable,      // MEM 阶段写使能信号
    input wire wb_write_enable,       // WB 阶段写使能信号

    
    input wire [31:0] mem_data,       // MEM阶段写入的数据
    input wire [31:0] wb_data,        // WB 阶段写入的数据
    input wire [4:0] id_rs1,          // ID 阶段源寄存器1地址
    input wire [4:0] id_rs2,          // ID 阶段源寄存器2地址
    input wire [1:0] branch_control,  // 分支控制信号
    output wire [31:0] corrected_operand1, // 修正后的操作数2
    output wire [31:0] alu_operand2, // 修正后的操作数2
    input wire is_lui,             // 是否为 LUI 指令
    output wire [31:0] corrected_operand2, // 修正后的操作数2
    output wire [31:0] pc_jalr,        // JALR 指令的目标地址
    output wire [31:0] result,    // ALU 计算结果
/* verilator lint_off UNOPTFLAT */    output wire branch_taken          // 分支是否被执行
);
assign pc_jalr = is_jalr?alu_result:0; // JALR 指令的目标地址
    
    wire Zero;
    wire data_sign;
    wire [31:0] alu_result; // ALU 计算结果 


wire [31:0] sra_result;
assign sra_result = $signed(alu_operand1) >>> alu_operand2;  // 使用系统函数实现算术右移
wire [31:0] srai_result;
assign srai_result = $signed(alu_operand1) >>> alu_operand1;  // 使用系统函数实现算术右移
wire [31:0] corrected_result;
assign corrected_result=slt_slti?((alu_operand1[31]==1'b1 && alu_operand2[31]==1'b0 && alu_control==3'b001 && alu_result[31]==1'b0)?{1'b1,alu_result[30:0]}:
                        (alu_operand1[31]==1'b0 && alu_operand2[31]==1'b1 && alu_control==3'b001 && alu_result[31]==1'b1)?{1'b0,alu_result[30:0]}:
                        (alu_operand1[31]==1'b0 && alu_operand2[31]==1'b0 && alu_control==3'b000 && alu_result[31]==1'b1)?{1'b0,alu_result[30:0]}:
                        (alu_operand1[31]==1'b1 && alu_operand2[31]==1'b1 && alu_control==3'b000 && alu_result[31]==1'b0)?{1'b1,alu_result[30:0]}:
                        alu_result):alu_result;
  wire bgeu_bge;
  assign bgeu_bge = (alu_operand1[31]==1'b1 && alu_operand2[31]==1'b1  && alu_result[31]==1'b0)?1'b0:
                    (alu_operand1[31]==1'b1 && alu_operand2[31]==1'b1  && alu_result[31]==1'b1)?1'b1:
                    (alu_operand1[31]==1'b1 && alu_operand2[31]==1'b0  )?1'b0:
                    (alu_operand1[31]==1'b0 && alu_operand2[31]==1'b1  )?1'b1:
                    (alu_operand1[31]==1'b0 && alu_operand2[31]==1'b0  && alu_result[31]==1'b1)?1'b1:
                    (alu_operand1[31]==1'b0 && alu_operand2[31]==1'b0  && alu_result[31]==1'b0)?1'b0:
                    (Zero==1'b0)?1'b1:
                    1'b0;
wire sltu_sltiu_xuanze;
 assign sltu_sltiu_xuanze =(alu_operand1[31]==1'b1 && alu_operand2[31]==1'b1  && alu_result[31]==1'b0)?1'b0:
                           (alu_operand1[31]==1'b1 && alu_operand2[31]==1'b1  && alu_result[31]==1'b1)?1'b1:
                           (alu_operand1[31]==1'b1 && alu_operand2[31]==1'b0  )?1'b0:
                           (alu_operand1[31]==1'b0 && alu_operand2[31]==1'b1  )?1'b1:
                           (alu_operand1[31]==1'b0 && alu_operand2[31]==1'b0  && alu_result[31]==1'b1)?1'b1:
                           (alu_operand1[31]==1'b0 && alu_operand2[31]==1'b0  && alu_result[31]==1'b0)?1'b0:
                           1'b0;
wire [31:0] sltu_sltiu_result;
assign sltu_sltiu_result = (sltu_sltiu_xuanze ==1) ? 32'b1 : 32'b0; // SLTU 或 SLTIU 指令
wire [31:0]slt_slti_result;
assign slt_slti_result   = (corrected_result[31] == 1'b1 && Zero==1) ? 32'b1:  32'b0; 
wire [31:0]jalr_result;
assign jalr_result = pc_addr +4;
assign result = sra_R ? sra_result :
                srai_R ? srai_result:
                is_jalr? jalr_result :
                slt_slti ? slt_slti_result :
                sltu_sltiu ? sltu_sltiu_result :
                alu_result;
assign corrected_operand1 =  (mem_write_enable && id_rs1 == mem_dest) ? mem_data :
                             (wb_write_enable  && id_rs1 == wb_dest) ?wb_data:
                             operand1 ;

assign corrected_operand2 = (mem_write_enable && id_rs2 == mem_dest) ?mem_data:
                            (wb_write_enable  && id_rs2 == wb_dest) ?wb_data:
                            operand2;
   // 根据输入信号选择操作数
    wire [31:0] alu_operand1 ;
    assign alu_operand1 = is_lui ? 32'b0 : // LUI 指令
                          use_pc ? corrected_operand1: pc_addr ;// AUIPC 指令; 

    assign alu_operand2 = auipc ? {imm_data[31:12], 12'b0} :  // AUIPC: imm20 << 12
                          is_jal?  4 :
                          use_imm ? (five_rs2 ? {27'b0, corrected_operand2[4:0]} : corrected_operand2) :  
                                    (five_rs2 ? {27'b0, imm_data[4:0]} :  imm_data); 
    // ALU 模块实例化
    ALU alu(
        .operand1(alu_operand1),
        .operand2(alu_operand2),
        .alu_control(alu_control),
        .result(alu_result),
        .Zero(Zero),
        .data_sign(data_sign)
    );
reg  branch_taken_jicunqi;
    // 分支判断逻辑
    assign branch_taken =~branch_taken_jicunqi &&(((branch_control == 2'b01 && !Zero) ||                  // BEQ: 等于
                         (branch_control == 2'b00 && Zero) ||                // BNE: 不等于 ZERO=1
                         (branch_control == 2'b10 && !data_sign && bge) ||           // BGE: 大于等于（有符号）
                         (branch_control == 2'b11 && data_sign && blt) ||            // BLT: 小于（有符号）
                         (branch_control == 2'b11 && bgeu_bge && bltu ) ||  // BLTU: 小于（无符号）
                         (branch_control == 2'b10 && !bgeu_bge && bgeu  ))&&(is_b_type)?1:0);    // BGEU: 大于等于（无符号）

always @(posedge clk or negedge rst) 
    if (rst) 
        branch_taken_jicunqi <= 1'b0; // 复位时将分支信号清零
    else begin
        branch_taken_jicunqi <= branch_taken; // 保持分支信号不变
    end
endmodule
// ALU 模块
module ALU(
    input wire [31:0] operand1,       
    input wire [31:0] operand2,     
    input wire [2:0] alu_control,    // ALU 控制信号
    output wire Zero,                // 零标志
    output wire data_sign,           // 数据符号位
    output reg [31:0] result          // ALU 计算结果
);
    always @(*) begin
        case (alu_control)
            3'b000: result = operand1 + operand2;  // 加法
            3'b001: result = operand1 - operand2;  // 减法
            3'b010: result = operand1 & operand2;  // 按位与
            3'b011: result = operand1 | operand2;  // 按位或
            3'b100: result = operand1 ^ operand2;  // 按位异或
            3'b101: result = operand1 << operand2; // 左移5sll
            3'b110: result = operand1 >> operand2; // 右移5srl
            3'b111: result = (operand1 < operand2) ? 3'b001 : 3'b000; // 比较
            default: result = 32'b0;              // 默认值
        endcase
    end

    // 设置 Zero 标志，如果结果为零
    assign Zero = (result == 32'b0) ? 1'b0 : 1'b1;
    
    // 数据符号位（最高位）
    assign data_sign = result[31];


endmodule

