module dl_float(
   input wire clk, rst_n,
   input wire [2:0] sel,
   input wire [15:0] a,b,
   output reg [15:0] result
);

   wire [15:0] out_add, out_mul, out_div, out_mac,out_sub,out_sqrt,out_norm,out_dp;
   wire [15:0] out_muxed_wire;
   dlfloat16_div div(.a(a), .b(b), .c_div_1(out_div));
   dlfloat_mac mac(.clk(clk),.rst_n(rst_n),.a(a), .b(b), .c_out(out_mac));
   dlfloat16_add add(.a(a),.b(b),.c_add_1(out_add));
   dlfloat16_sub sub(.a1(a),.b1(b),.c_add_1(out_sub));
   dlfloat16_sqrt sqrt(.dl_in(a),.dl_out_fin(out_sqrt));
   dlfloat16_mul mul(.a(a),.b(b),.c_mul(out_mul));
   Eucli_norm euclidean_norm(.a(a),.b(b),.c(out_norm));
   dot_product dot_product(.a(a),.b(b),.c(out_dp));
   out_mux outmux(.clk(clk),.reset(rst_n),.sel(sel),.out_add(out_add),.out_sub(out_sub),.out_mul(out_mul), .out_div(out_div),.out_mac(out_mac),.out_sqrt(out_sqrt),.out_norm(out_norm),.out_dp(out_dp),.out_muxed_1(out_muxed_wire));

    always@(*) begin
         result = out_muxed_wire;
    end
    
endmodule

    

