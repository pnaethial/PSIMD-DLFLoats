module exception_unit(
     input logic invalid_0, 
     input logic inexact_0, 
     input logic overflow_0,
     input logic underflow_0, 
     input logic div_by_zero_0,
     input logic invalid_1, 
     input logic inexact_1, 
     input logic overflow_1,
     input logic underflow_1, 
     input logic div_by_zero_1,
     input logic invalid_2, 
     input logic inexact_2, 
     input logic overflow_2,
     input logic underflow_2, 
     input logic div_by_zero_2,
     input logic invalid_3, 
     input logic inexact_3, 
     input logic overflow_3,
     input logic underflow_3, 
     input logic div_by_zero_3,
     output logic [3:0] invalid,
     output logic [3:0] inexact,
     output logic [3:0] overflow,
     output logic [3:0] underflow,
     output logic [3:0] div_by_zero
    );
    
    always@(*) begin
        invalid = {invalid_3,invalid_2,invalid_1,invalid_0};
        inexact = {inexact_3,inexact_2,inexact_1,inexact_0};
        overflow = {overflow_3,overflow_2,overflow_1,overflow_0};
        underflow = {underflow_3,underflow_2,underflow_1,underflow_0};
        div_by_zero = {div_by_zero_3,div_by_zero_2,div_by_zero_1,div_by_zero_0};
    end
    
endmodule
