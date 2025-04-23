module mux #(
    parameter REG_WIDTH = 64)(
    input wire [REG_WIDTH-1:0] a,
    input wire [REG_WIDTH-1:0] b,
    input wire s,
    output reg [REG_WIDTH-1:0] c
    );
     
    always@(*) begin
        if(s)
            c = b;
        else
            c = a;
    end
endmodule
