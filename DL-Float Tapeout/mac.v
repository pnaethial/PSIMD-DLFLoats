module dlfloat_mac (
    input wire clk,
    input wire rst_n,
    input wire [15:0] a,
    input wire [15:0] b,
    output reg [15:0] c_out
);

    wire [15:0] fprod;
    wire [15:0] c_add_1;
    wire [15:0] c_wire;
    reg [15:0] c_wire_1;

    assign c_wire = c_out;
    

    always @(posedge clk ) begin
        if (!rst_n) begin
            c_out <= 16'b0;
        end else begin
            c_out <= c_add_1;
        end
    end
    
    dlfloat_mult mul (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .c_mul(fprod)
    );

    dlfloat_adder add (
        .a1(fprod),
        .b1(c_wire_1),
        .c_add_1(c_add_1)
    );

endmodule
