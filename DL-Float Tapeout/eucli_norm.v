`timescale 1ns / 1ps
module Eucli_norm(
    input wire [15:0] a,b,
    output wire [15:0] c
    );
    
    wire [15:0] a2,b2,c2,c1;
    assign c=c1;
    
    
    dlfloat16_mul norm_mula(.a(a),.b(a),.c_mul(a2));
    dlfloat16_mul norm_mulb(.a(b),.b(b),.c_mul(b2));
    dlfloat16_add norm_add(.a(a2),.b(b2),.c_add_1(c2));
    dlfloat16_sqrt sqrt(.dl_in(c2),.dl_out_fin(c1));
    
    
    
    
endmodule
