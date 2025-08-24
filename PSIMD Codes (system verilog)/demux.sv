module demux_reg #(
    parameter REG_WIDTH =64)(
    input logic [REG_WIDTH-1:0] a,
    input logic s,
    output logic [REG_WIDTH-1:0] b,
    output logic [REG_WIDTH-1:0] c
    );
    
    always@(*) begin
        if(s ==  1'b0) begin
            b = a;
        end else begin
            c = a;
        end
    end
endmodule
