module Execution_unit #(
    parameter REG_WIDTH = 64)(
     input wire [3:0] ena,
     input wire [2:0] rm,
     input wire [2:0] sel2,// for cmpr
     input wire op,
     input wire [1:0] sel1,
     input wire [REG_WIDTH-1:0] data1,
     input wire [REG_WIDTH-1:0] data2,
     input wire [REG_WIDTH-1:0] data3,datai_0,datai_1,
     output reg [REG_WIDTH-1:0] dataout_1,
     output reg [REG_WIDTH-1:0] dataouti_0,dataouti_1,
     output reg [3:0] invalid,
     output reg [3:0] inexact,
     output reg [3:0] overflow,
     output reg [3:0] underflow,
     output reg [3:0] div_by_zero
    );
    
    wire [15:0] data_0, data_1, data_2, data_3;
    wire [15:0] data1_0, data1_1, data1_2, data1_3;
    wire [15:0] data2_0, data2_1, data2_2, data2_3;
    wire [15:0] data3_0, data3_1, data3_2, data3_3;
    wire [31:0] in_int_0,in_int_1,in_int_2,in_int_3,outi_0,outi_1,outi_2,outi_3;
    wire [63:0] data_in_from_reg,data_in_from_mem,data_out_to_reg,data_out_1,data_in_1;
    wire invalid_0,inexact_0,overflow_0,underflow_0,div_by_zero_0;
    wire invalid_1,inexact_1,overflow_1,underflow_1,div_by_zero_1;
    wire invalid_2,inexact_2,overflow_2,underflow_2,div_by_zero_2;
    wire invalid_3,inexact_3,overflow_3,underflow_3,div_by_zero_3;
    
    wire [3:0] invalid_wire,inexact_wire,overflow_wire,underflow_wire,div_by_zero_wire;
    wire [63:0] dataout_1_wire,dataouti_0_wire,dataouti_1_wire;
    
    always@(*) begin
        invalid = invalid_wire;
        inexact = inexact_wire;
        overflow = overflow_wire;
        underflow = underflow_wire;
        div_by_zero = div_by_zero_wire;
        dataout_1 = dataout_1_wire;
        dataouti_0 = dataouti_0_wire;
        dataouti_1 = dataouti_1_wire;
    end
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) dl_floats_execution_unit E0 (
    .ena(ena),
    .rm(rm),
    .sel2(sel2),
    .op(op),
    .sel1(sel1),
    .op1(data1_0),
    .op2(data2_0),
    .op3(data3_0),
    .in_int(in_int_0),
    .invalid(invalid_0), 
    .inexact(inexact_0), 
    .overflow(overflow_0),
    .underflow(underflow_0), 
    .div_by_zero(div_by_zero_0),
    .result(data_0),
    .out_1(outi_0)
    );
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) dl_floats_execution_unit E1 (
    .ena(ena),
    .rm(rm),
    .sel2(sel2),
    .op(op),
    .sel1(sel1),
    .op1(data1_1),
    .op2(data2_1),
    .op3(data3_1),
    .in_int(in_int_1),
    .invalid(invalid_1), 
    .inexact(inexact_1), 
    .overflow(overflow_1),
    .underflow(underflow_1), 
    .div_by_zero(div_by_zero_1),
    .result(data_1),
    .out_1(outi_1)
    );
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) dl_floats_execution_unit E2 (
    .ena(ena),
    .rm(rm),
    .sel2(sel2),
    .op(op),
    .sel1(sel1),
    .op1(data1_2),
    .op2(data2_2),
    .op3(data3_2),
    .in_int(in_int_2),
    .invalid(invalid_2), 
    .inexact(inexact_2), 
    .overflow(overflow_2),
    .underflow(underflow_2), 
    .div_by_zero(div_by_zero_2),
    .result(data_2),
    .out_1(outi_2)
    );
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) dl_floats_execution_unit E3 (
    .ena(ena),
    .rm(rm),
    .sel2(sel2),
    .op(op),
    .sel1(sel1),
    .op1(data1_3),
    .op2(data2_3),
    .op3(data3_3),
    .in_int(in_int_3),
    .invalid(invalid_3), 
    .inexact(inexact_3), 
    .overflow(overflow_3),
    .underflow(underflow_3), 
    .div_by_zero(div_by_zero_3),
    .result(data_3),
    .out_1(outi_3)
    );
    
    (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*)  exception_unit EX (
    .invalid_0(invalid_0), 
    .inexact_0(inexact_0), 
    .overflow_0(overflow_0),
    .underflow_0(underflow_0) ,
    .div_by_zero_0(div_by_zero_0),
    .invalid_1(invalid_1), 
    .inexact_1(inexact_1), 
    .overflow_1(overflow_1),
    .underflow_1(underflow_1) ,
    .div_by_zero_1(div_by_zero_1),
    .invalid_2(invalid_2), 
    .inexact_2(inexact_2), 
    .overflow_2(overflow_2),
    .underflow_2(underflow_2) ,
    .div_by_zero_2(div_by_zero_2),
    .invalid_3(invalid_3), 
    .inexact_3(inexact_3), 
    .overflow_3(overflow_3),
    .underflow_3(underflow_3) ,
    .div_by_zero_3(div_by_zero_3),
    .invalid(invalid_wire), 
    .inexact(inexact_wire), 
    .overflow(overflow_wire),
    .underflow(underflow_wire) ,
    .div_by_zero(div_by_zero_wire)
    );
    
     (* keep_hierarchy = "yes" *) (*DO_NOT_REMOVE = "true"*) splitter s1 (
    .data1(data1),
    .data2(data2),
    .data3(data3),
    .datai_0(datai_0),
    .datai_1(datai_1),
    .data_0(data_0),
    .data_1(data_1),
    .data_2(data_2),
    .data_3(data_3),
    .outi_0(outi_0),
    .outi_1(outi_1),
    .outi_2(outi_2),
    .outi_3(outi_3),
    .dataout_1(dataout_1_wire),
    .dataouti_0(dataouti_0_wire),
    .dataouti_1(dataouti_1_wire),
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
    
endmodule
