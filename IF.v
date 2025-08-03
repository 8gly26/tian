module IF(
    input wire clk,
    input wire rst,
    input wire[31:0]ex_pc,
    input wire branch_taken, // 分支是否被执行
    output wire is_jalr, // JAL 指令
    input wire [31:0] rs1,
    input wire [31:0] instruction_in,
    output wire jump_error,
    output wire [31:0] pc_next_out   // 输出下一个 PC 地址
);
wire [31:0] imm_jal, imm_b,imm_jalr; // 立即数
wire [4:0] addr_id; // 寄存器地址
assign addr_id=  instruction_in[19:15];
assign is_jal  = (instruction_in[6:0] == 7'b1101111); // JAL 指令
assign is_jalr = (instruction_in[6:0] == 7'b1100111); // JALR 指令
// 提取 JAL 类指令的立即数
assign imm_jal = {{11{instruction_in[31]}}, instruction_in[31], instruction_in[19:12], instruction_in[20], instruction_in[30:21], 1'b0};
// 提取 JALR 类指令的立即数
assign imm_jalr = {{11{instruction_in[31]}}, instruction_in[31], instruction_in[19:12], instruction_in[20], instruction_in[30:21], 1'b0};
// 提取 B 类指令的立即数
assign imm_b = {{19{instruction_in[31]}}, instruction_in[31], instruction_in[7], instruction_in[30:25], instruction_in[11:8], 1'b0};
reg is_jal_d1;
always@(posedge clk)
    if (rst) begin
        is_jal_d1 <= 1'b0; // 复位时将指令清零
    end else begin
        is_jal_d1 <= is_jal; // 保持指令不变
    end
assign jump_error = (imm_jal!=4 && is_jal) ? 1'b1 : 1'b0; // 跳转错误信号
// 定义PC寄存器
reg [31:0] pc_next;

// 输出下一个PC地址
assign pc_next_out = pc_next;
reg [31:0] imm_b_jicunqi;
always @(posedge clk or posedge rst) 
    if (rst) 
        imm_b_jicunqi <= 32'b0; // 复位时将PC清零
    else 
        imm_b_jicunqi <=  imm_b; // 跳转到 B 类指令的目标地址
        reg is_jalr_d1;
always @(posedge clk or posedge rst) 
    if (rst) 
        is_jalr_d1 <= 32'b0; // 复位时将PC清零
    else 
        is_jalr_d1 <=  is_jalr; // 跳转到 B 类指令的目标地址
// PC更新逻辑
always @(posedge clk ) begin
    if (rst) 
        pc_next <= 32'b0;
    else if ( branch_taken) 
        pc_next <= pc_next - 4 + imm_b_jicunqi; // 跳转到 B 类指令的目标地址
    else if (is_jalr_d1) 
        pc_next<=  ex_pc[15:0] ; // 跳转到 JALR 指令的目标地址 
    else if(jump_error) 
        pc_next <= pc_next  + imm_jal; // 跳转到 JAL 指令的目标地址
    else 
        pc_next <= pc_next + 4;
end
endmodule