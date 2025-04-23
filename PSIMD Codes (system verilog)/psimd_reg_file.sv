module psimd_reg_file (
    input logic clk,
    input logic rst_n,
    input logic [4:0] rs1_address,
    input logic [4:0] rs2_address,
    input logic [4:0] rs3_address,
    input logic [4:0] rd_address,
    input logic wr_enable,logic_fti_ctrl,
    input logic [63:0] dataout_1,
    input logic [63:0] dataout_2,
    output logic [63:0] data1,
    output logic [63:0] data2,
    output logic [63:0] data3
    );
    
    
    integer i;
    logic [63:0] REGISTER [31:0];
    
    
    always@(posedge clk) begin
    if(~rst_n) begin
         begin
            for (i = 0; i < 32; i = i + 1) begin
                REGISTER[i] <= 64'b0;
            end
        end
    end
    else begin
        if (wr_enable) begin
        if (logic_fti_ctrl) begin
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
