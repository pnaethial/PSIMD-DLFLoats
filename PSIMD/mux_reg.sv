module mux_reg #(
    parameter REG_WIDTH = 64)(
    input logic [REG_WIDTH-1:0] a,
    input logic [REG_WIDTH-1:0] b,
    input logic s,
    output logic [REG_WIDTH-1:0] c
    );
     
    always@(*) begin
        if(s ==1'b0) begin
            c = a;
        end if(s == 1'b1) begin
            c = b;
        end
    end
endmodule
