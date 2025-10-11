module PC (
    input clk,
    input reset,
    input branch_taken,
    input [15:0] w_instruction_address,
    output reg [15:0] pc_out
);

always @(posedge clk) begin
    if (reset == 1'b1) begin
        pc_out <= 16'b0;
    end
     else if (branch_taken) 
        pc_out <= w_instruction_address;
    else begin
        pc_out <= pc_out + 16'd1; 
    end
end
endmodule