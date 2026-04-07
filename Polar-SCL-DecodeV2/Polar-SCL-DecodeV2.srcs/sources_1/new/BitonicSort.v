`timescale 1ns / 1ps

module BitonicSort(
    input wire sysclk,
    input wire sysres,
    input wire BS_en,
    input wire [31:0] path_matrix0,
    input wire [31:0] path_matrix1,
    input wire [31:0] path_matrix2,
    input wire [31:0] path_matrix3,
    output wire [1:0] index0,
    output wire [1:0] index1,
    output reg BS_Updating
    );


wire [31:0] path_matrix [3:0];
reg [1:0]index[3:0];
assign path_matrix[0] = path_matrix0;
assign path_matrix[1] = path_matrix1;
assign path_matrix[2] = path_matrix2;
assign path_matrix[3] = path_matrix3;
assign index0 = index[0];
assign index1 = index[1];
reg [2:0] count;
integer i;

always @(posedge sysclk or negedge sysres) begin
    if (sysres == 1'b0) begin
        for (i = 0; i <= 3; i =i +1) begin
            index[i] <= 1'b0;
        end
        count <= 1'b0;
        BS_Updating <= 1'b0;
    end
    else if(BS_en == 1'b1) begin
        BS_Updating <=1'b1;
        if (count == 2'd0) begin
            // for (i =0; i < 3; i = i+2) begin
            //     if (path_matrix[i] > path_matrix[i+1]) begin
            //             index[i] <= i+1;
            //             index[i+1] <= i;
            //     end
            //     else begin
            //         index[i] <= i;
            //         index[i+1] <= i+1;
            //     end
            //     // index[i] <= (path_matrix[i]>path_matrix[i+1])? i+1: i;
            //     // index[i+1] <= (path_matrix[i]>path_matrix[i+1])? i: i+1;
            // end
            if(path_matrix[0]>path_matrix[1]) begin
                index[0] <= 1'b1;
                index[1] <= 1'b0;
            end
            else begin
                index[0] <= 1'b0;
                index[1] <= 1'b1;
            end
            if(path_matrix[2]>path_matrix[3]) begin
                index[2] <= 2'd2;
                index[3] <= 2'd3;
            end
            else begin
                index[2] <= 2'd3;
                index[3] <= 2'd2;
            end
            count <= count+ 1'b1;
        end
    end
    else if(BS_Updating == 1'b1 && count == 2'd1) begin
            for(i = 0; i < 2; i = i+1) begin
                index[i] <= (path_matrix[index[i]]>path_matrix[index[i+2]])? index[i+2]: index[i];
                index[i+2] <= (path_matrix[index[i]]>path_matrix[index[i+2]])? index[i]: index[i+2];
            end
            // if(path_matrix[index[1]]>path_matrix[index[2]]) begin
            //     index[1] <= index[2];
            //     index[2] <= index[1];
            // end

        count <= count +1'b1;
    end
    else if(BS_Updating == 1'b1 && count == 2'd2) begin
            for (i =0; i < 3; i = i+2) begin
                if (path_matrix[index[i]] > path_matrix[index[i+1]]) begin
                    index[i] <= index[i+1];
                    index[i+1] <= index[i];
                end
                // index[i] <= (path_matrix[index[i]]>path_matrix[index[i+1]])? index[i+1]: index[i];
                // index[i+1] <= (path_matrix[index[i]]>path_matrix[index[i+1]])? index[i]: index[i+1];
            end
        BS_Updating <= 1'b0;
    end
    // else if(count == 2'd2) begin
    //     if(path_matrix[index[1]] < path_matrix[index[0]]) begin
    //         index[0] <= index[1];
    //         index[1] <= index[0];
    //     end
    // end
    else begin
        count <= 1'b0;
        BS_Updating <= 1'b0;
    end
end

endmodule