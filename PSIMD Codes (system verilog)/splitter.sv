module splitter #(
    parameter REG_WIDTH = 64)(
     input logic [REG_WIDTH-1:0] data1,
     input logic [REG_WIDTH-1:0] data2,
     input logic [REG_WIDTH-1:0] data3,
     input logic [REG_WIDTH-1:0] datai_0,
     input logic [REG_WIDTH-1:0] datai_1,
     input logic [15:0] data_0,
     input logic [15:0] data_1,
     input logic [15:0] data_2,
     input logic [15:0] data_3,
     input logic [31:0] outi_0,
     input logic [31:0] outi_1,
     input logic [31:0] outi_2,
     input logic [31:0] outi_3,
     output logic [REG_WIDTH-1:0] dataout_1,
     output logic [REG_WIDTH-1:0] dataouti_0,
     output logic [REG_WIDTH-1:0] dataouti_1,
     output logic [15:0] data1_0,
     output logic [15:0] data1_1,
     output logic [15:0] data1_2,
     output logic [15:0] data1_3,
     output logic [15:0] data2_0,
     output logic [15:0] data2_1,
     output logic [15:0] data2_2,
     output logic [15:0] data2_3,
     output logic [15:0] data3_0,
     output logic [15:0] data3_1,
     output logic [15:0] data3_2,
     output logic [15:0] data3_3,
     output logic [31:0] in_int_0,
     output logic [31:0] in_int_1,
     output logic [31:0] in_int_2,
     output logic [31:0] in_int_3
    );
    
    always@(*) begin
            data1_0 = data1[15:0];
            data1_1 = data1[31:16];
            data1_2 = data1[47:32];
            data1_3 = data1[63:48];
            
            data2_0 = data2[15:0];
            data2_1 = data2[31:16];
            data2_2 = data2[47:32];
            data2_3 = data2[63:48];
            
            data3_0 = data3[15:0];
            data3_1 = data3[31:16];
            data3_2 = data3[47:32];
            data3_3 = data3[63:48];
            
            dataout_1[15:0] = data_0;
            dataout_1[31:16] = data_1;
            dataout_1[47:32] = data_2;
            dataout_1[63:48] = data_3;
            
            dataouti_0 [31:0] = outi_0;
            dataouti_0 [63:32] = outi_1;
            dataouti_1 [31:0] = outi_2;
            dataouti_1 [63:32] = outi_3;
            
            in_int_0 = datai_0[31:0];
            in_int_1 = datai_0[63:32];
            in_int_2 = datai_1[31:0];
            in_int_3 = datai_1[63:32];

    end
endmodule
