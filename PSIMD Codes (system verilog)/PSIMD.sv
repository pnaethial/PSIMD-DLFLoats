module PSIMD #(
    parameter REG_WIDTH =64)(
    input logic clk,
    input logic rst_n,
    input logic [31:0] instr,rs1_core,
    output logic [3:0] invalid, inexact, overflow, underflow, div_by_zero,
    output [63:0] data_out_1_1
    );
    
     logic[4:0] rs1_address,rs2_address,rs3_address,rd_address;
     logic [15:0] data_0, data_1, data_2, data_3;
     logic [15:0] data1_0, data1_1, data1_2, data1_3;
     logic [15:0] data2_0, data2_1, data2_2, data2_3;
     logic [15:0] data3_0, data3_1, data3_2, data3_3;
     logic [2:0] rm,sel2;
     logic [3:0] ena;
     logic [1:0] sel1;
     logic sp,mi,logic_fti_ctrl;
     logic [REG_WIDTH-1:0] data1,data2,data3;
     logic [REG_WIDTH-1:0] dataout_1;
     logic [REG_WIDTH-1:0] dataout_2;
     logic [31:0] in_int_0,in_int_1,in_int_2,in_int_3,outi_0,outi_1,outi_2,outi_3;
     logic [63:0] data_in_1;
     logic [REG_WIDTH-1:0] datain_2;
     logic [63:0] dataouti_0;
     logic [63:0] data_out_1;
     logic [63:0] datai_0,datain_0,dataout_mux,dataouti_1,datai_1,datain_1;
     logic [31:0] instr,rs1_core;
     logic [31:0] address;
//     logic [3:0] invalid, inexact, underflow, overflow,div_by_zero;
     logic mem_read,mem_write, sp1;
     logic [11:0] imm;
     logic [63:0] data_in_from_mem,data_in_from_reg, data_out_to_mem, data_out_to_reg,data_1_1;
     logic [63:0] data_out_1_1;
     logic clk;
     
     IBUFDS clk_ibufds_inst (
        .I(clk_p), 
        .IB(clk_n), 
        .O(clk) 
    );
     
     assign data_out_1_2 = data_out_1_1 [15:0];
     assign iv = invalid [0] | invalid [1] | invalid [2] | invalid [3] | inexact [0] | inexact [1] | inexact [2] | inexact [3];
     assign uf = underflow [0] | underflow [1] | underflow [2] | underflow [3] ; 
     assign of = overflow [0] | overflow [1] | overflow [2] | overflow [3] ; 
     assign dbz = div_by_zero [0] | div_by_zero [1] | div_by_zero [2] | div_by_zero [3] ; 

    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) instr_bin instr_bin(
    .clk(clk),
    //.rst_n(rst_n),
    .instr(instr)
    //.rs1_core(rs1_core)
    );
   
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) psimd_reg_file register_file (
    .clk(clk),
    .rst_n(rst_n),
    .rs1_address(rs1_address),
    .rs2_address(rs2_address),
    .rs3_address(rs3_address),
    .rd_address(rd_address),
    .wr_enable(wr_enable),
    .reg_fti_ctrl(reg_fti_ctrl),
    .dataout_1(data_out_1_1),
    .dataout_2(dataouti_1),
    .data1(data1),
    .data2(data2),
    .data3(data3)
    );
    
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)  mux_reg mux_sp(
    .a(dataouti_0),
    .b(dataout_1),
    .s(sp),
    .c(data_out_1)
    );


    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) dlfloat16_decoder decoder(
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
    .wr_enable(wr_enable),
    .reg_fti_ctrl(reg_fti_ctrl),
    .sp(sp)
//    .mi(mi),
//    .sp1(sp1),
//    .sp2(sp2),
//    .mem_read(mem_read),
//    .mem_write(mem_write),
//    .imm(imm),
//    .op_1(op_1)
    );
    
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) Execution_unit EU (
    //.clk(clk),
    //.rst_n(rst_n),
    //.op_1(op_1),
    .ena(ena),
    .rm(rm),
    .sel2(sel2),
    .op(op),
    .sel1(sel1),
    .data1(data_1_1),
    .data2(data2),
    .data3(data3),
    .datai_0(data_1_1),
    .datai_1(data2),
    .dataout_1(dataout_1),
    .dataouti_0(dataouti_0),
    .dataouti_1(dataouti_1),
    .invalid(invalid), 
    .inexact(inexact), 
    .overflow(overflow),
    .underflow(underflow) ,
    .div_by_zero(div_by_zero)
    );
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) memory memory(
    //.clk(clk),
    .address(address),
    .data_out_to_mem(data_out_to_mem),
    //.mi(mi),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .data_in_from_mem(data_in_from_mem)
    );
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) LSU LSU (
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
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) demux_reg demux(
    .a(data1),
    .s(sp2),
    .b(data_in_from_reg),
    .c(data_1_1)
    );
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)  mux_reg mux(
    .a(data_out_to_reg),
    .b(data_out_1),
    .s(sp1),
    .c(data_out_1_1)
    );
    
    
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) out_reg output_reg(
    .a(a),
    .clk(clk),
    //.rst_n(rst_n),
    //.data_in(data_out_1_1)
    .b(b)
    );

endmodule
