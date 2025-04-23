module exception_unit(
     input wire invalid_0, 
     input wire inexact_0, 
     input wire overflow_0,
     input wire underflow_0, 
     input wire div_by_zero_0,
     input wire invalid_1, 
     input wire inexact_1, 
     input wire overflow_1,
     input wire underflow_1, 
     input wire div_by_zero_1,
     input wire invalid_2, 
     input wire inexact_2, 
     input wire overflow_2,
     input wire underflow_2, 
     input wire div_by_zero_2,
     input wire invalid_3, 
     input wire inexact_3, 
     input wire overflow_3,
     input wire underflow_3, 
     input wire div_by_zero_3,
     output reg [3:0] invalid,
     output reg [3:0] inexact,
     output reg [3:0] overflow,
     output reg [3:0] underflow,
     output reg [3:0] div_by_zero
    );
    
    always@(*) begin
        invalid = {invalid_3,invalid_2,invalid_1,invalid_0};
        inexact = {inexact_3,inexact_2,inexact_1,inexact_0};
        overflow = {overflow_3,overflow_2,overflow_1,overflow_0};
        underflow = {underflow_3,underflow_2,underflow_1,underflow_0};
        div_by_zero = {div_by_zero_3,div_by_zero_2,div_by_zero_1,div_by_zero_0};
    end
    
endmodule
