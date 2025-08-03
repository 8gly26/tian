module WB(
    input wire clk,
    input wire rst,
    input wire wb_enable,             // 写回使能信号
    input wire [31:0] wb_data,        // 写回的数据
    input wire [4:0] wb_dest,         // 写回的目标寄存器地址
    input wire is_b_type,           // 是否为分支指令
    input wire is_jalr,       
    output wire reg_write_enable,     // 寄存器写使能信号
    output wire [31:0] write_data,    // 写入寄存器的数据
    output wire [4:0] write_addr      // 写入寄存器的地址
);


    assign reg_write_enable = wb_enable;
    // 写入寄存器的数据和地址
    assign write_data = (wb_dest==0||is_b_type)?0:wb_data;
    assign write_addr = (is_b_type)?0:wb_dest;

endmodule