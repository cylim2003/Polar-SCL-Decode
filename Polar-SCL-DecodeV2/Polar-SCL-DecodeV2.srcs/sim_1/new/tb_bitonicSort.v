`timescale 1ns / 1ps


module tb_bitonicSort(    );

reg sysclk;
reg sysres;
reg BS_en;
wire [1:0] index0;
wire [1:0] index1;
wire BS_Updating;
reg [31:0] path_matrix0;
reg [31:0] path_matrix1;
reg [31:0] path_matrix2;
reg [31:0] path_matrix3;
reg DELAY1;
integer i;

initial begin
    sysclk <= 1'b0;
    sysres <= 1'b0;
    #20
    sysres <= 1'b1;
end

always #20 sysclk <= ~sysclk;

always @(posedge sysclk or negedge sysres) begin
    if(sysres == 1'b0) begin
        path_matrix0 <= 31'd0;
        path_matrix1 <= 31'd0;
        path_matrix2 <= 31'd0;
        path_matrix3 <= 31'd0;
        BS_en <= 1'b0;
        DELAY1 <= 1'b0;
    end
    else if(DELAY1 == 1'b0 && BS_Updating == 1'b0) begin
        // path_matrix0 <= 31'd104;
        // path_matrix1 <= 31'd104;
        // path_matrix2 <= 31'd108;
        // path_matrix3 <= 31'd107;
        path_matrix0 <= $random;
        path_matrix1 <= $random;
        path_matrix2 <= $random;
        path_matrix3 <= $random;
        BS_en <= 1'b1; 
        DELAY1 <= 1'b1;
    end
    else if (DELAY1 == 1'b1 && BS_Updating == 1'b0) begin
        BS_en <= 1'b0;
        DELAY1 <= 1'b0;
    end
    else begin
        BS_en <= 1'b0;
    end
end

BitonicSort BitonicSort_inst(
    .sysclk(sysclk),
    .sysres(sysres),
    .BS_en(BS_en),
    .path_matrix0(path_matrix0),
    .path_matrix1(path_matrix1),
    .path_matrix2(path_matrix2),
    .path_matrix3(path_matrix3),
    .index0(index0),
    .index1(index1),
    .BS_Updating(BS_Updating)
    );

endmodule
