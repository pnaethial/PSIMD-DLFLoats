module p_reg_file #(
    parameter REG_WIDTH = 64)(
    input logic clk,
    input logic rst_n,
    input logic [4:0] rs1_address,
    input logic [4:0] rs2_address,
    input logic [4:0] rs3_address,
    input logic [4:0] rd_address,
    input logic wr_enable,reg_fti_ctrl,
    input logic [REG_WIDTH-1:0] dataout_1,
    input logic [REG_WIDTH-1:0] dataout_2,
    output logic [REG_WIDTH-1:0] data1,
    output logic [REG_WIDTH-1:0] data2,
    output logic [REG_WIDTH-1:0] data3
    );
    
    logic [REG_WIDTH-1:0] REGISTER [31:0];
    
    (*dont_touch = "yes" *)logic [REG_WIDTH-1:0] write_data;
    (*dont_touch = "yes" *)logic [REG_WIDTH-1:0] rs1_data;
    (*dont_touch = "yes" *)logic [REG_WIDTH-1:0] rs2_data;
    (*dont_touch = "yes" *)logic [REG_WIDTH-1:0] rs3_data;
    
    always_ff@(posedge clk) begin
    if(rst_n) begin
        for (int i = 0; i < 32; i++) begin
            REGISTER[i] <= 32'b0;
        end
    end
    else begin
        if (wr_enable) begin
        if (reg_fti_ctrl) begin
            REGISTER [rd_address] <= dataout_1;
        end
        else begin 
            REGISTER [rd_address] <= dataout_1;
            REGISTER [rd_address+1] <= dataout_2;
       end     
    end
    end
    end
    
    always@(*) begin
        data1 = REGISTER [rs1_address];
        data2 = REGISTER [rs2_address];
        data3 = REGISTER [rs3_address];
        end  
endmodule