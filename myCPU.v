module myCPU(
    input wire clk,
    input wire rst,
    input wire [31:0] instruction_spo, // 指令
    output wire branch_taken, // 分支跳转信号
    output wire is_jalr, // 是否为 JALR 指令
    output wire [15:0] if_pc_addr, // PC 地址
    output wire [4:0]rd,
    output wire rd_enable, // 寄存器堆写使能信号
    output wire [31:0] read_data, // 写回数据
    output wire [15:0] wb_addr, // 写回寄存器地址
    output wire wb_enable, // 写回使能信号
    output wire if_jump_error, // 跳转错误信号
    output wire [31:0] wb_value, // 写回值
    output wire [15:0]addr,
    // 外部存储器接口
    output wire [15:0] ext_mem_addr,
    output wire [31:0] ext_mem_wdata,
    output wire ext_mem_write,
    output wire ext_mem_read,
    input wire [31:0] ext_mem_rdata,
    input wire ext_mem_ready
);
reg [60:0]sign_3;
reg [60:0]sign_1;
    assign rd=sign_1[26:22];
    assign rd_enable=sign_2[12];
    // IF 阶段信号
    wire [15:0] if_jump_fix_addr;
    // ID 阶段信号
    wire [31:0] id_reg_data1;
    wire [31:0] id_reg_data2;
    wire [31:0] id_imm_data;



    // EX 阶段信号
    wire [31:0] ex_alu_result;
    // wire ex_data_conflict;


    // MEM 阶段信号
    wire mem_ready;


    // WB 阶段信号
    wire wb_reg_write_enable;
    wire [31:0] wb_write_data;
    wire [4:0] wb_write_addr;
/* verilator lint_off MULTIDRIVEN */wire [60:0]sign;
wire [15:0] next_addr;


    // IF 模块实例化
     IF if_stage(
         .clk(clk),
         .rst(rst),
         .ex_pc(pc_jalr), // JALR 指令的目标地址
         .branch_taken(branch_taken), // 分支是否被执行
         .rs1(id_reg_data1), // 寄存器 rs1 的值
         .is_jalr(is_jalr), // 是否为 JALR 指令
         .instruction_in(instruction_spo),
         .jump_error(if_jump_error),//output
         .pc_next_out(if_pc_addr)
     );
 assign addr=if_pc_addr;  
     reg  [15:0]IF_jicunqi;
    //第一级流水线
    always @(posedge clk or negedge rst) 
        if(rst)
         IF_jicunqi<=16'b0;
        else if(branch_taken||sign_1[52]) // 如果复位或分支跳转或是 JALR 指令
         IF_jicunqi<=0;
        else
         IF_jicunqi<=addr;

    // ID 模块实例化
    ID id_stage(
        .clk(clk),
        .rst(rst),
        .instruction(instruction_spo),
        .write_data(wb_write_data),
        .write_addr(wb_write_addr),
        .reg_write_enable(wb_reg_write_enable),
        .reg_data1(id_reg_data1),//output
        .reg_data2(id_reg_data2),
        .imm_data(id_imm_data)
    );
reg [95:0]ID_jicuqi;
//第二级流水线
always@(posedge clk or negedge rst)
    if(rst || branch_taken||sign_1[52]) // 如果复位或分支跳转或是 JALR 指令
      ID_jicuqi<=96'b0;
    else 
      ID_jicuqi<={id_reg_data1,id_reg_data2,id_imm_data};
reg [31:0]MEM_jicunqi;
    // EX 模块实例化

    Control control_unit(
        .Instruction(instruction_spo),       // 输入指令
        .sign(sign)           // 输出控制信号
    );
    always @(posedge clk or negedge rst) begin
        if(rst)
            sign_1<=61'b0;
        else
            sign_1<=sign;
    end
wire [31:0] mem_data;
wire [31:0]corrected_operand1;
wire [31:0]corrected_operand2;
wire [31:0]pc_jalr;
reg  [60:0]sign_4;
    EX ex_stage(
        .clk(clk),
        .rst(rst),
        .pc_jalr(pc_jalr), // JALR 指令的目标地址
        .operand1(ID_jicuqi[95:64]),                                   
        .operand2(ID_jicuqi[63:32]),  
        .imm_data(ID_jicuqi[31:0]),
        .pc_addr(IF_jicunqi),
        .alu_control(sign_1[15:13]),
        .five_rs2(sign_1[33]),
        .use_imm(sign_1[18]),
        .corrected_operand1(corrected_operand1),
        .alu_operand2(alu_operand2), // 修正后的操作数2
        .is_jalr(sign_1[52]), // 是否为 JALR 指令
        .use_pc(sign_1[16]),
        .ex_dest(sign_1[26:22]),
        .mem_dest(sign_2[26:22]), 
        .sltu_sltiu(sign_1[46]), // 是否为 SLTU 或 SLTIU 指令
        .srai_R(sign_1[42]),
        .sra_R(sign_1[42]),
        .srli(sign_1[44]),
        .wb_dest(sign_3[26:22]), 
        .pc_jal(if_jump_fix_addr),
        .blt(sign_1[53]), // 是否为 BLT 指令
        .bge(sign_1[55]), // 是否为 BGE 指令
        .bgeu(sign_1[56]), // 是否为 BGEU 指令
        .bltu(sign_1[54]), // 是否为 BLTU 指令
        .is_b_type(sign_1[32]),
        .auipc(sign_1[43]),
        .is_jal(sign_1[51]), // 是否为 JAL 指令
        .slt_slti(sign_1[45]), // 是否为 SLT 或 SLTI 指令
        .ex_write_enable(sign_1[12]), // EX 阶段写使能信号
        .mem_write_enable(mem_write_enable), // MEM 阶段写使能信号
        .wb_write_enable(sign_3[12]),// WB 阶段写使能信号
        .mem_data(mem_data), // MEM 阶段写入的数据
        .wb_data(wb_write_data),
        .id_rs1(sign_1[6:2]),
        .id_rs2(sign_1[11:7]),
        .branch_control(sign_1[38:37]), // 控制信号
        .is_lui(sign_1[34]), // 是否为 LUI 指令
        .branch_taken(branch_taken), // 分支是否被执行
        .result(ex_alu_result),//output
        .corrected_operand2(corrected_operand2) //修正后的操作数2
    );
reg [60:0]sign_2;
    always @(posedge clk or negedge rst) begin
        if(rst)
            sign_2<=61'b0;
        else
            sign_2<=sign_1;
    end
wire mem_write_enable = (sign_3[52])?1'b0:sign_2[12];
reg [47:0] EX_jicunqi;
always @(posedge clk or negedge rst) begin
    if(rst || branch_taken )
      EX_jicunqi<=64'b0;
    else begin
        EX_jicunqi[15:0]<=ex_alu_result[15:0];
        EX_jicunqi[47:16]<=ex_alu_result;
    end
end
wire [31:0] wb_data;
wire [31:0] alu_operand2; // 修正后的操作数2
reg [31:0] corrected_operand2_sw; // 修正后的操作数2（用于存储指令）
reg [31:0] cor_op2_sw; // 修正后的操作数2（用于存储指令）
always @(posedge clk or negedge rst) begin
    if(rst)
        cor_op2_sw<=32'b0;
    else 
        cor_op2_sw<=alu_operand2;
end
always @(posedge clk or negedge rst) begin
    if(rst)
        corrected_operand2_sw<=32'b0;
    else 
        corrected_operand2_sw<=corrected_operand2;
end
    // MEM 模块实例化
    MEM mem_stage(
        .clk(clk),
        .rst(rst),
        .mem_data(mem_data),
        .cor_op2_sw(cor_op2_sw), // 修正后的操作数2（用于存储指令）
 /* verilator lint_off SELRANGE */.sw(sign_2[57]), // 是否为 SW 指令
        .write_addr(sign_2[26:22]),
        .corrected_operand2_sw(corrected_operand2_sw), // 修正后的操作数2（用于存储指令）
        .mem_read(sign_2[36]),
        .mem_write(sign_2[35]),
        .is_b_type(sign_2[32]),
        .mem_addr(EX_jicunqi[15:0]),
        .write_data(EX_jicunqi[47:16]),
        .is_i_load(sign_2[47]), // 是否为 I 类型加载指令read_data
        .is_i_s_type(sign_2[50:48]), // 是否为 I 类型存储指令
        .read_data(read_data),//output  // 从存储器读取的数据
        .mem_ready(mem_ready),
        .ext_mem_addr(ext_mem_addr),
        .ext_mem_wdata(ext_mem_wdata),
        .ext_mem_write(ext_mem_write),
        .ext_mem_read(ext_mem_read),
        .ext_mem_rdata(ext_mem_rdata),
        .ext_mem_ready(ext_mem_ready)
    );

    always @(posedge clk or negedge rst) begin
        if(rst)
            sign_3<=61'b0;
        else
            sign_3<=sign_2;
    end
        always @(posedge clk or negedge rst) begin
        if(rst)
            sign_4<=61'b0;
        else
            sign_4<=sign_3;
    end
reg branch_taken_jicunqi;
always @(posedge clk or negedge rst) begin
    if (rst) 
        branch_taken_jicunqi <= 1'b0; // 复位时将分支信号清零
    else 
        branch_taken_jicunqi <= branch_taken; // 保持分支信号不变
end
//第四级流水线
always @(posedge clk or negedge rst) begin
    if(rst||branch_taken_jicunqi||sign_3[52]) // 如果复位或分支跳转或是 JALR 指令
     MEM_jicunqi<=32'b0;
    else 
     MEM_jicunqi<=read_data;
end
    // WB 模块实例化
    WB wb_stage(
        .clk(clk),
        .rst(rst),
        .wb_enable(sign_3[12]),
        .wb_data(MEM_jicunqi),
        .wb_dest(sign_3[26:22]), 
        .is_b_type(sign_3[32]),
        .is_jalr(sign_3[52]),
        .reg_write_enable(wb_reg_write_enable),//output
        .write_data(wb_write_data),
        .write_addr(wb_write_addr)
    );

assign wb_data=wb_write_data;
assign wb_enable=sign_3[17];

endmodule
