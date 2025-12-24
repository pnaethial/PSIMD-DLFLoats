module out_mux(
     input wire clk,reset,
     input wire [2:0] sel, 
     input wire [15:0] out_mul,out_add,out_sub,out_sqrt,out_div, out_mac,out_norm,out_dp,
     output reg [15:0] out_muxed_1);

    reg [15:0] out_muxed;    
    
  always @(*) begin
    out_muxed = 16'b0;
      case(sel)
        3'b000: out_muxed = out_add;
        3'b001: out_muxed = out_sub;
        3'b010: out_muxed = out_mul;
        3'b011: out_muxed = out_div;
        3'b100: out_muxed = out_mac;
        3'b101: out_muxed = out_sqrt;
        3'b110: out_muxed = out_norm;
        3'b111: out_muxed = out_dp; 
      endcase
      end
      
    always@(posedge clk) begin
        if(!reset)begin
            out_muxed_1 <= 16'b0;
        end else begin
            out_muxed_1 <= out_muxed;
        end
    end
    
    
endmodule
