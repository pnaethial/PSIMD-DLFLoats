module output_logic(
    input logic [63:0]a,
    input logic clk,
    output logic [63:0] b
    );
    
    always @(posedge clk) begin
        b <= a;
    end 
endmodule
