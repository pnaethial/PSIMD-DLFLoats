module output_reg(
    input wire [63:0]a,
    input wire clk,
    output reg [63:0] b
    );
    
    always @(posedge clk) begin
        b <= a;
    end 
endmodule
