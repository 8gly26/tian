module MEM(
    input wire clk,
    input wire rst,
    input wire mem_read,              // 读存储器信号
    input wire sw,                  // 是否为 SW 指令
    input wire mem_write,             // 写存储器信号  
    input wire is_b_type,             // 是否为分支指令
    input wire [17:0] mem_addr,       // 存储器地址
    input wire [31:0] cor_op2_sw,     // 修正后的操作数2（用于存储指令）
    input wire [31:0] corrected_operand2_sw, // 修正后的操作数2（用于存储指令）
    input wire [31:0] write_data,     // 写入存储器的数据   load读寄存器地址memory
    input wire [4:0]  write_addr,      // 写入存储器的地址
    input wire is_i_load,            // 是否为 I 型加载指令
    input wire [2:0]is_i_s_type,     // 是否为 I 型存储指令S
    output wire [31:0] mem_data,       // 存储器数据
    output wire mem_ready,            // 存储器操作完成信号
    output wire [31:0] read_data,     // 从存储器读取的数据
    // 与外部存储器交互的接口
    output wire [15:0] ext_mem_addr,  // 外部存储器地址
    output wire [31:0] ext_mem_wdata, // 外部存储器写入数据
    output wire ext_mem_write,        // 外部存储器写使能
    output wire ext_mem_read,         // 外部存储器读使能
    input wire [31:0] ext_mem_rdata,  // 外部存储器读取数据
    input wire ext_mem_ready         // 外部存储器操作完成信号
);


    // 将输入信号直接传递给外部存储器
    assign ext_mem_addr  =  mem_addr>>2; // 只取低16位作为地址
    assign ext_mem_wdata = (sw)?corrected_operand2_sw:
                           (is_i_s_type == 3'b110)? mem_wdata:
                           (is_i_s_type == 3'b111)? mem_wdata1:
                           32'b0;   
    assign ext_mem_write = (sw||is_i_s_type == 3'b110||is_i_s_type == 3'b111)? 1'b1 : 1'b0 ;  // 如果是存储指令，则写入修正后的操作数2，否则为0
    assign ext_mem_read = mem_read;
  // 根据sb前面的偏移量判断写入那个地址其余保持不变
    wire [31:0] mem_wdata;
    assign mem_wdata = (il) ? ((cor_op2_sw_yima[1:0] == 2'b00) ? corrected_operand2_sw[31:0] :
                              (cor_op2_sw_yima[1:0] == 2'b01) ? {corrected_operand2_sw[31:23],corrected_operand2_sw[7:0],corrected_operand2_sw[15:0]} :
                              (cor_op2_sw_yima[1:0] == 2'b10) ? {16'b0, corrected_operand2_sw[15:0]} :
                              {24'b0, corrected_operand2_sw[7:0]}):
                              //il==0
                              ((write_data[1:0] == 2'b00) ? {corrected_operand2_sw[31:0]} :
                              (write_data[1:0] == 2'b01) ? {corrected_operand2_sw[23:0], 8'b0} :
                              (write_data[1:0] == 2'b10) ? {corrected_operand2_sw[15:0], 16'b0} :
                              {corrected_operand2_sw[7:0], 24'b0});
wire [31:0] mem_wdata1;
assign mem_wdata1 = (il) ?((cor_op2_sw_yima[1:0] == 2'b00) ? {corrected_operand2_sw[15:0],corrected_operand2_sw[31:16]} :{16'b0, corrected_operand2_sw[15:0]} ): 
                          // il=0 
                          ((write_data[1:0] == 2'b00) ? {corrected_operand2_sw[31:0]} : {corrected_operand2_sw[15:0], 16'b0});
    // 从外部存储器读取数据
    wire il;
    assign il = cor_op2_sw[31] == 1'b1;
    wire [1:0]cor_op2_sw_yima;
    assign cor_op2_sw_yima = (cor_op2_sw[1:0] == 2'b00) ? 2'b00 : // 
                             (cor_op2_sw[1:0] == 2'b01) ? 2'b11 : // -3==1
                             (cor_op2_sw[1:0] == 2'b10) ? 2'b10 : // -2==2
                             (cor_op2_sw[1:0] == 2'b11) ? 2'b01 : // -1==1
                             2'b00; // 默认值

    wire [31:0]ext_mem_rdata_lb;
    assign ext_mem_rdata_lb = (il) ? ext_mem_rdata << (cor_op2_sw_yima[1:0]*8) : ext_mem_rdata >> (write_data[1:0]*8); // 读取指定字节的数据
    wire [31:0]ext_mem_rdata_lb1;
    assign ext_mem_rdata_lb1 = (il) ? {{24{ext_mem_rdata_lb[31]}}, ext_mem_rdata_lb[31:24]} :{{24{ext_mem_rdata_lb[7]}}, ext_mem_rdata_lb[7:0]} ;
    wire [31:0]ext_mem_rdata_lh;
    assign ext_mem_rdata_lh =  (il) ? {{16{ext_mem_rdata_lb[31]}}, ext_mem_rdata_lb[31:16]} :{{16{ext_mem_rdata_lb[15]}}, ext_mem_rdata_lb[15:0]} ;
  // debug数据
    assign read_data =(sw)? corrected_operand2_sw :
                      (is_i_s_type == 3'b011)?ext_mem_rdata                                    ://lw
                      (is_i_s_type == 3'b010) ? ext_mem_rdata_lh                               : // lh
                      (is_i_s_type == 3'b001) ? ext_mem_rdata_lb1                              : // lb
                      (is_i_s_type == 3'b101) ? {16'b0, ext_mem_rdata_lh[15:0]}                : // lhu无符号扩展
                      (is_i_s_type == 3'b100) ? {24'b0, ext_mem_rdata_lb1[7:0]}                : // lbu无符号扩展
                      write_data;
  //写入寄存器数据
    assign mem_data  =(write_addr==0)?0:
                      (is_i_s_type == 3'b011)?ext_mem_rdata                                    ://lw
                      (is_i_s_type == 3'b010) ? ext_mem_rdata_lh                               : // lh
                      (is_i_s_type == 3'b001) ? ext_mem_rdata_lb1                              : // lb
                      (is_i_s_type == 3'b101) ? {16'b0, ext_mem_rdata_lh[15:0]}                : // lhu无符号扩展
                      (is_i_s_type == 3'b100) ? {24'b0, ext_mem_rdata_lb1[7:0]}                : // lbu无符号扩展
                      write_data;

    // 操作完成信号
    assign mem_ready = ext_mem_ready;

endmodule