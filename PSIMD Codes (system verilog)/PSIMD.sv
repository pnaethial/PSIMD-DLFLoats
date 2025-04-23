module PSIMD #(
    parameter REG_WIDTH =64)(
    input logic clk,
    input logic rst_n,
    input logic [31:0] instr,
    output logic [3:0] invalid ,inexact ,overflow ,underflow ,div_by_zero,
    output logic [63:0] data_out_reg
    //output logic [63:0] data_out_1
   
    
    );
    

    
     logic[4:0] rs1_address,rs2_address,rs3_address,rd_address;
     logic [15:0] data_0, data_1, data_2, data_3;
     logic [15:0] data1_0, data1_1, data1_2, data1_3;
     logic [15:0] data2_0, data2_1, data2_2, data2_3;
     logic [15:0] data3_0, data3_1, data3_2, data3_3;
     logic [2:0] rm,sel2;
     logic [3:0] ena;
     logic [1:0] sel1;
     logic sp;
     logic [REG_WIDTH-1:0] data1,data2,data3,dataout_1;
     logic [REG_WIDTH-1:0] dataout_2;
     logic [31:0] in_int_0,in_int_1,in_int_2,in_int_3,outi_0,outi_1,outi_2,outi_3;
     logic [63:0] data_in_1;
     logic [REG_WIDTH-1:0] datain_2;
     logic [63:0] dataouti_0;
     logic [63:0] data_out_1;
     logic [63:0] datai_0,datain_0,dataout_mux,dataouti_1,datai_1,datain_1;
//    logic [31:0] instr;
//    logic [3:0] invalid,inexact,overflow,underflow,div_by_zero;
//     logic [63:0] data_out_reg;
//    logic [63:0] data_out_1;

    
    
//    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)instr_buffer instr_buffer(
//    .clk(clk),
//    .instr(instr)
//    );
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) psimd_reg_file register_file (
    .clk(clk),
    .rst_n(rst_n),
    .rs1_address(rs1_address),
    .rs2_address(rs2_address),
    .rs3_address(rs3_address),
    .rd_address(rd_address),
    .wr_enable(wr_enable),
    .logic_fti_ctrl(logic_fti_ctrl),
    .dataout_1(data_out_1),
    .dataout_2(dataouti_1),
    .data1(data1),
    .data2(data2),
    .data3(data3)
    );
    
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)  mux mux_sp(
    .a(dataouti_0),
    .b(dataout_1),
    .s(sp),
    .c(data_out_1)
    );


    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) decoder decoder(
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
    .logic_fti_ctrl(logic_fti_ctrl),
    .sp(sp)
    );
    
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) Execution_unit EU (
    .ena(ena),
    .rm(rm),
    .sel2(sel2),
    .op(op),
    .sel1(sel1),
    .data1(data1),
    .data2(data2),
    .data3(data3),
    .datai_0(data1),
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
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) output_logic output_logicister(
    .a(data_out_1),
    .clk(clk),
    .b(data_out_reg)
    );
    
endmodule
