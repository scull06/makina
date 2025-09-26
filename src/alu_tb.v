module tb;

	// 1. Declare input/output variables to drive to the design
	reg [15:0]	tb_A;
	reg [15:0]	tb_B;
	reg [4:0]	tb_ALUCtrl;
	wire [15:0]	tb_Result;

	// 2. Create an instance of the design
	// This is called design instantiation
	alu16 	alu ( 		
					.A(tb_A), 		// Connect data input with TB signal
					.B (tb_B), 		// Connect reset input with TB signal
					.ALUCtrl (tb_ALUCtrl),
					.Result(tb_Result)); 		// Connect output q with TB signal

	// 3. add values to signals
	initial begin
		    // ADD
        tb_A = 16'h0003; tb_B = 16'h0002; tb_ALUCtrl = 5'b00000;
        #10 $display("ADD: %d + %d = %d", tb_A, tb_B, tb_Result);

        // SUB
        tb_A = 16'h0005; tb_B = 16'h0003; tb_ALUCtrl = 5'b00001;
        #10 $display("SUB: %d - %d = %d", tb_A, tb_B, tb_Result);

        // AND
        tb_A = 16'h00FF; tb_B = 16'h0F0F; tb_ALUCtrl = 5'b00010;
        #10 $display("AND: %h & %h = %h", tb_A, tb_B, tb_Result);

        // OR
        tb_A = 16'h00F0; tb_B = 16'h0F0F; tb_ALUCtrl = 5'b00011;
        #10 $display("OR: %h | %h = %h", tb_A, tb_B, tb_Result);

        // XOR
        tb_A = 16'hAAAA; tb_B = 16'h5555; tb_ALUCtrl = 5'b00100;
        #10 $display("XOR: %h ^ %h = %h", tb_A, tb_B, tb_Result);

        // MUL
        tb_A = 16'h0003; tb_B = 16'h0004; tb_ALUCtrl = 5'b00101;
        #10 $display("MUL: %d * %d = %d", tb_A, tb_B, tb_Result);

        // DIV
        tb_A = 16'h0008; tb_B = 16'h0002; tb_ALUCtrl = 5'b00111;
        #10 $display("DIV: %d / %d = %d", tb_A, tb_B, tb_Result);

        // NOT
        tb_A = 16'hFFFF; tb_B = 16'h0000; tb_ALUCtrl = 5'b01000;
        #10 $display("NOT: ~%h = %h", tb_A, tb_Result);

        // MOD
        tb_A = 16'h0009; tb_B = 16'h0004; tb_ALUCtrl = 5'b01001;
        #10 $display("MOD: %d %% %d = %d", tb_A, tb_B, tb_Result);

        // Default
        tb_A = 16'h0001; tb_B = 16'h0001; tb_ALUCtrl = 5'b11111;
        #10 $display("DEFAULT: Result = %d", tb_Result);

        $finish;
	end
endmodule