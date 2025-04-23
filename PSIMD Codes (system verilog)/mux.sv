module mux #(
    parameter REG_WIDTH = 64)(
    input logic [REG_WIDTH-1:0] a,
    input logic [REG_WIDTH-1:0] b,
    input logic s,
    output logic [REG_WIDTH-1:0] c
    );
     
    always@(*) begin
        if(s)
            c = b;
        else
            c = a;
    end
endmodule
