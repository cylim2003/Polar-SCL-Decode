`timescale 1ns / 1ps
module tb_PartialSumV3();

reg sysclk;
reg sysres;
reg [10:0] i;
reg [4:0] s;
reg U_0;
reg readEn;
reg writeEn;
reg COMPLETED;

reg DELAY1;
reg DELAY2;

wire isUpdating;
wire readComplete;
wire U;

initial begin
    sysclk <= 1'b0;
    sysres <= 1'b0;
    #20
    sysres <= 1'b1;
end

always #20 sysclk <= ~sysclk;

always @(posedge sysclk or negedge sysres) begin
    if (sysres == 1'b0) begin
        U_0 <= 1'b1;
        i <= 1'b0;
        s <= 1'b0;
        readEn <= 1'b0;
        writeEn <= 1'b0;
        COMPLETED <= 1'b0;
        DELAY1 <= 1'b0;
        DELAY2 <= 1'b0;
    end
    else begin
        if (COMPLETED == 1'b0 &&DELAY1 == 1'b0) begin
            if (i == 1024) begin
                COMPLETED <= 1'b1;
            end
            else begin
                DELAY1 <= 1'b1;
                writeEn <= 1'b1;
            end
        end
        else if (COMPLETED == 1'b0 && DELAY1 == 1'b1) begin
            writeEn <= 1'b0;
            DELAY2 <= 1'b1;
            if (DELAY2 == 1'b1 && writeEn == 1'b0 && isUpdating == 1'b0)begin
                DELAY1 <= 1'b0;
                DELAY2 <= 1'b0;
                if(i < 1024) begin
                    i <= i + 1'b1;
                    U_0 <= $random%2;
                end
                else begin
                    COMPLETED <= 1'b1;
                    i <= i;
                    U_0 <= U_0;
                end
            end
        end
        else begin
            i <= i;
            s <= s;
            writeEn <= 1'b0;
            readEn <= 1'b0;
        end
    end
end





Partial_SumV3 Partial_Sum_inst
(
    .sysclk(sysclk),
    .sysres(sysres),
    .i(i),
    .s(s),
    .U_0        (U_0), //input U for writing
    .readEn     (readEn),
    .writeEn    (writeEn),
    .COMPLETED  (COMPLETED),
    .isUpdating (isUpdating),
    .readComplete(readComplete),
    .U(U)
    );

endmodule
