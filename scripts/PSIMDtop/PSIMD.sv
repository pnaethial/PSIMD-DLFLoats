module PSIMD #(
    parameter REG_WIDTH =64)(
    input logic clk,
    input logic rst_n,
    input logic [31:0] instr,
    input logic [31:0] rs1_core,
    output logic [REG_WIDTH-1:0] data_in_from_mem,    
    output [3:0] invalid ,inexact ,overflow ,underflow ,div_by_zero,
    output logic [REG_WIDTH-1:0] data_out_to_mem,data1,data2,data3,
    output logic [31:0] address,
    output logic mem_read,mem_write,
    output logic [REG_WIDTH-1:0] data_out_1,dataouti_0,dataouti_1,data_out_to_reg
//    output logic [15:0] data1_0,
//    output logic [15:0] data1_1,
//    output logic [15:0] data1_2,
//    output logic [15:0] data1_3,
//    output logic [15:0] data2_0,
//    output logic [15:0] data2_1,
//    output logic [15:0] data2_2,
//    output logic [15:0] data2_3,
//    output logic [15:0] data3_0,
//    output logic [15:0] data3_1,
//    output logic [15:0] data3_2,
//    output logic [15:0] data3_3,
//    output logic [31:0] in_int_0,
//    output logic [31:0] in_int_1,
//    output logic [31:0] in_int_2,
//    output logic [31:0] in_int_3
    );
    
    logic [4:0] rs1_address,rs2_address,rs3_address,rd_address;
    logic [15:0] data_0, data_1, data_2, data_3;
    logic [15:0] data1_0, data1_1, data1_2, data1_3;
    logic [15:0] data2_0, data2_1, data2_2, data2_3;
    logic [15:0] data3_0, data3_1, data3_2, data3_3;
    logic [2:0] rm,sel2;
    logic [3:0] ena;
    logic [1:0] sel1;
    logic sp;
    logic [REG_WIDTH-1:0] data1,data2,data3,dataout_1,dataout_2;
    logic [31:0] in_int_0,in_int_1,in_int_2,in_int_3,outi_0,outi_1,outi_2,outi_3;
    logic [63:0] data_in_from_reg,data_out_to_reg,data_out_1,data_in_1,dataout_1;
    logic [11:0] imm;
    logic [63:0] datai_0,datain_0,dataout_2,dataout_mux,datain_2,data2,dataouti_0,datai_1,datain_1;
    
    p_reg_file register_file (
    .clk(clk),
    .rst_n(rst_n),
    .rs1_address(rs1_address),
    .rs2_address(rs2_address),
    .rs3_address(rs3_address),
    .rd_address(rd_address),
    .wr_enable(wr_enable),
    .dataout_1(data_out_1),
    .dataout_2(dataouti_1),
    .data1(data1),
    .data2(data2),
    .data3(data3)
    );
    
    LSU load_store_unit (
    .data_in_from_mem(data_in_from_mem),
    .data_in_from_reg(data_in_from_reg),
    .imm(imm),
    .rs1_core(rs1_core),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .address(address),
    .data_out_to_reg(data_out_to_reg),
    .data_out_to_mem(data_out_to_mem)
    );
    
    mux_reg mux1(
    .a(data_out_to_reg),
    .b(dataout_mux),
    .s(s_1),
    .c(data_out_1)
    );
    
    mux_reg mux_sp(
    .a(dataouti_0),
    .b(dataout_1),
    .s(sp),
    .c(dataout_mux)
    );
    
   
    demux_reg demux1 (
    .a(data1),
    .s(s_2),
    .b(data_in_from_reg),
    .c(data_in_1)
    );
    
    
    dlfloat16_decoder decoder(
    .instr(instr),
    .ena(ena),
    .rm(rm),
    .sel2(sel2),
    .op(op),
    .sel1(sel1),
    .rs1(rs1_address),
    .rs2(rs2_address),
    .rs3(rs3_address),
    .rd(rd_address),
    .imm(imm),
    .wr_enable(wr_enable),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .s_1(s_1),
    .s_2(s_2),
    .sp(sp)
    );
    
    
    Execution_unit EU (
    .ena(ena),
    .rm(rm),
    .sel2(sel2),
    .op(op),
    .sel1(sel1),
    .data1(data_in_1),
    .data2(data2),
    .data3(data3),
    .datai_0(data_in_1),
    .datai_1(data2),
    .dataout_1(dataout_1),
    .dataouti_0(dataouti_0),
    .dataouti_1(dataouti_1),
    .invalid(invalid), 
    .inexact(inexact), 
    .overflow(overflow),
    .underflow(underflow) ,
    .div_by_zero(div_by_zero),
    .data1_0(data1_0),
    .data1_1(data1_1),
    .data1_2(data1_2),
    .data1_3(data1_3),
    .data2_0(data2_0),
    .data2_1(data2_1),
    .data2_2(data2_2),
    .data2_3(data2_3),
    .data3_0(data3_0),
    .data3_1(data3_1),
    .data3_2(data3_2),
    .data3_3(data3_3),
    .in_int_0(in_int_0),
    .in_int_1(in_int_1),
    .in_int_2(in_int_2),
    .in_int_3(in_int_3)
    );
    
    memory memory (
    .address(address),
    .data_out_to_mem(data_out_to_mem),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .data_in_from_mem(data_in_from_mem)
    );
    
endmodule
