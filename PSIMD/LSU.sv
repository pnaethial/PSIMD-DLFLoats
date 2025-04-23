module LSU #(
    parameter REG_WIDTH =64)(
    input logic [REG_WIDTH-1:0] data_in_from_mem,
    input logic [REG_WIDTH-1:0] data_in_from_reg,
    input logic [11:0] imm,
    input logic [31:0] rs1_core,
    input logic mem_read,mem_write,
    output logic [31:0] address,
    output logic [REG_WIDTH-1:0] data_out_to_reg,
    output logic [REG_WIDTH-1:0] data_out_to_mem
    );
    
    (*dont_touch = "yes" *)logic [31:0] imm1;  
    
    always@(*) begin
        imm1[11:0] = imm;
        imm1[31:12] = 20'b00000000000000000000;
        address = rs1_core + imm1;
    end

    
    
    
    always @(*) begin
        if(mem_read == 1'b1) begin
            data_out_to_reg = data_in_from_mem;
        end
        if(mem_write == 1'b1) begin
            data_out_to_mem = data_in_from_reg;
        end
        $display("data_out_to_reg=%h",data_out_to_reg);
    end
endmodule