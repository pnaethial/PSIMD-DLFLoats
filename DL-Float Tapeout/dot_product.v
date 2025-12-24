`timescale 1ns / 1ps
module dot_product(
    input wire [15:0] a, b,
    output wire [15:0] c
    );
    
    wire [15:0] ab, eu_out,c1;
    assign c=c1;
    
    dlfloat16_mul dp_mul(.a(a),.b(b),.c_mul(ab));
    Eucli_norm euclidean_norm(.a(a),.b(b),.c(eu_out));
    dlfloat16_div div(.a(ab), .b(eu_out), .c_div_1(c1));
    
    
endmodule
