
module miniRV_SoC (
    input  logic         fpga_rst,   // High active
    input  logic         fpga_clk,

    output logic         debug_wb_have_inst, // 当前时钟周期是否有指令写回 (对单周期CPU，可在复位后恒置1)
    output logic [15:0]  debug_wb_pc,        // 当前写回的指令的PC (若wb_have_inst=0，此项可为任意值)
    output               debug_wb_ena,       // 指令写回时，寄存器堆的写使能 (若wb_have_inst=0，此项可为任意值)
    output logic [ 4:0]  debug_wb_reg,       // 指令写回时，写入的寄存器号 (若wb_ena或wb_have_inst=0，此项可为任意值)
    output logic [31:0]  debug_wb_value      // 指令写回时，写入寄存器的值 (若wb_ena或wb_have_inst=0，此项可为任意值)
);
    logic        cpu_clk = fpga_clk;
    wire [15:0] if_pc_addr; // 指令存储器地址
    wire [31:0] instruction_spo; // 指令存储器输出
    wire [15:0] ext_mem_addr; // 外部存储器地址
    wire [31:0] ext_mem_wdata; // 外部存储器写数据
    wire        ext_mem_write; // 外部存储器写使能
    wire        ext_mem_read; // 外部存储器读使能
    wire [31:0] ext_mem_rdata; // 外部存储器读数据
    wire        ext_mem_ready; // 外部存储器准备好信号
    wire [4:0]  rd; //寄存器地址
    wire        rd_enable; // 寄存器堆写使能信号
    wire [15:0] wb_addr; // 写回寄存器地址+
    wire [31:0] wb_data; // 写回数据
    wire        wb_enable; // 写回使能信号
    wire [15:0] addr; // 地址

wire [15:0] addr_debug_wb_pc; // 地址
// 假设 addr_debug_wb_pc 是 16 位宽的信号
reg [15:0] addr_debug_wb_pc_d1, addr_debug_wb_pc_d2, addr_debug_wb_pc_d3, addr_debug_wb_pc_d4;

// 时钟过程
always @(posedge fpga_clk or negedge fpga_rst) begin
    if (fpga_rst) begin
        addr_debug_wb_pc_d1 <= 16'b0;
        addr_debug_wb_pc_d2 <= 16'b0;
        addr_debug_wb_pc_d3 <= 16'b0;
        addr_debug_wb_pc_d4 <= 16'b0;
    end else begin
        addr_debug_wb_pc_d1 <= addr;       // 第 1 拍
        addr_debug_wb_pc_d2 <= addr_debug_wb_pc_d1;   // 第 2 拍
        addr_debug_wb_pc_d3 <= addr_debug_wb_pc_d2;   // 第 3 拍
        addr_debug_wb_pc_d4 <= addr_debug_wb_pc_d3;   // 第 4 拍
    end
end


// 假设 rd_debug_wb_reg 是 6 位宽的信号
wire [5:0] rd_debug_wb_reg; //寄存器地址
reg [5:0] rd_debug_wb_reg_d1, rd_debug_wb_reg_d2, rd_debug_wb_reg_d3;

// 时钟过程
always @(posedge fpga_clk or negedge fpga_rst) begin
    if (fpga_rst) begin
        rd_debug_wb_reg_d1 <= 6'b0;
        rd_debug_wb_reg_d2 <= 6'b0;
        rd_debug_wb_reg_d3 <= 6'b0;
    end else begin
        rd_debug_wb_reg_d1 <= rd;       // 第 1 拍
        rd_debug_wb_reg_d2 <= rd_debug_wb_reg_d1;   // 第 2 拍
        rd_debug_wb_reg_d3 <= rd_debug_wb_reg_d2;   // 第 3 拍
    end
end
reg if_jump_error; // 分支跳转错误信号
reg if_jump_error_d1; // 分支跳转错误信号       
reg if_jump_error_d2; // 分支跳转错误信号
reg if_jump_error_d3; // 分支跳转错误信号
// 添加一个寄存器用于存储提前一个周期的 wb_data
  always @(posedge fpga_clk ) begin
    if (fpga_rst) begin
        if_jump_error_d1 <= 1'b0;
        if_jump_error_d2 <= 1'b0;
        if_jump_error_d3 <= 1'b0;
    end else begin
        if_jump_error_d1 <= if_jump_error;       // 第 1 拍
        if_jump_error_d2 <= if_jump_error_d1;   // 第 2 拍
        if_jump_error_d3 <= if_jump_error_d2;   // 第 3 拍
    end
end
reg is_jalr_d1; // 是否为jalr指令
reg is_jalr_d2; // 是否为jalr指令
reg is_jalr_d3; // 是否为jalr指令
always @(posedge fpga_clk ) begin
    if (fpga_rst) begin
        is_jalr_d1 <= 1'b0;
        is_jalr_d2 <= 1'b0;
        is_jalr_d3 <= 1'b0;
    end else begin
        is_jalr_d1 <= is_jalr;       // 第 1 拍
        is_jalr_d2 <= is_jalr_d1;   // 第 2 拍
        is_jalr_d3 <= is_jalr_d2;   // 第 3 拍
    end
end


// rd_debug_wb_reg_d3 即为打了三个拍子的信号


assign debug_wb_have_inst =(branch_taken_debug_d1||is_jalr_d3)?0:wb_enable; //写使能信号 
assign debug_wb_pc        = addr_debug_wb_pc_d2; //
assign debug_wb_ena       = rd_enable; //+
assign debug_wb_reg       = rd_debug_wb_reg_d1; //register地址五位
assign debug_wb_value     = wb_data; //写入寄存器的值

    myCPU Core_cpu (
        .rst            (fpga_rst),
        .clk            (cpu_clk),
        .if_pc_addr     (if_pc_addr),
        .is_jalr        (is_jalr), // 是否为jalr指令
        .rd             (rd), //寄存器地址
        .rd_enable      (rd_enable), // 寄存器堆写使能信号
        .instruction_spo(instruction_spo),
        .wb_addr        (wb_addr), // 写回寄存器地址
        .read_data      (wb_data), // 写回数据
        .if_jump_error (if_jump_error), // 分支跳转错误信号
        .addr           (addr), // 地址
        .wb_enable      (wb_enable), // 写回使能信号
        .branch_taken   (branch_taken), // 分支跳转信号
        .ext_mem_addr   (ext_mem_addr),//外部存储器接口
        .ext_mem_wdata  (ext_mem_wdata),
        .ext_mem_write  (ext_mem_write),
        .ext_mem_read   (ext_mem_read),
        .ext_mem_rdata  (ext_mem_rdata),
        .ext_mem_ready  (ext_mem_ready)
    );
    reg branch_taken_debug; // 分支跳转信号
    reg branch_taken_debug_d1; // 分支跳转信号
    always@(posedge fpga_clk or negedge fpga_rst) begin
        if(fpga_rst) begin
            branch_taken_debug <= 1'b0; // 分支跳转信号
            branch_taken_debug_d1 <= 1'b0; // 分支跳转信号
        end else begin
            branch_taken_debug <= branch_taken; // 分支跳转信号
            branch_taken_debug_d1 <= branch_taken_debug; // 分支跳转信号
        end
    end

    IROM Mem_IROM (
        .a          ({2'b00,addr[13:2]}), // 地址线cd
        .spo        (instruction_spo)
    );

    DRAM Mem_DRAM (
        .clk        (fpga_clk),
        .a          (ext_mem_addr),
        .spo        (ext_mem_rdata),
        .we         (ext_mem_write),
        .d          (ext_mem_wdata)
    );

endmodule