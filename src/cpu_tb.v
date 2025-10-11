module cpu_tb;

    reg clk;
    reg rst;
    reg [15:0] Instruction;
    reg [15:0] mem_data_in;

    wire [15:0] pc_addr_out;
    wire [15:0] mem_addr;
    wire [15:0] mem_data_write;
    wire        mem_write_enabled;

    // Instantiate CPU
    CPU uut (
        .clk(clk),
        .rst(rst),
        .Instruction(Instruction),
        .mem_data_in(mem_data_in),
        .pc_addr_out(pc_addr_out),
        .mem_addr(mem_addr),
        .mem_data_write(mem_data_write),
        .mem_write_enabled(mem_write_enabled)
    );

    // small instr + data memory
    reg [15:0] instr_mem [0:31];
    reg [15:0] data_mem  [0:63];

    // simple clock generator
    initial clk = 0;
    always #20 clk = ~clk;

    // fetch instruction combinationally from instr_mem using pc
    always @(*) begin
        Instruction = instr_mem[pc_addr_out];
    end

    // always present data bus: drive mem_data_in from data_mem at mem_addr
    always @(*) begin
        mem_data_in = data_mem[mem_addr];
    end

    // perform memory writes from CPU when mem_write_enabled asserted
    always @(posedge clk) begin
        if (mem_write_enabled) begin
            data_mem[mem_addr] <= mem_data_write;
        end
    end

    integer i;
	integer cycle = 0;

    initial begin
        // clear memories
        for (i=0; i<32; i = i+1) instr_mem[i] = 16'h0000;
        for (i=0; i<64; i = i+1) data_mem[i]  = 16'h0000;

        // preload data memory constants:
        // data_mem[0] = 5, data_mem[1] = 3
        data_mem[0] = 16'd5;
        data_mem[1] = 16'd3;

        // Program:
        // 0: LD  r1, 0(r0)    ; r1 <- data_mem[0] = 5
        instr_mem[0] = 16'b0000010000000000; // {2'b00, 1'b0, 3'b001, 3'b000, 7'b0000000};
        // 1: LD  r2, 1(r0)    ; r2 <- data_mem[1] = 3
        instr_mem[1] = 16'b0000100000000001; //{2'b00, 1'b0, 3'b010, 3'b000, 7'b0000001};
        // 2: ADD r3, r1, r2   ; r3 = r1 + r2 = 8
        instr_mem[2] = 16'b0100000011001010; //{2'b01, 4'b0000, 3'b011, 3'b001, 3'b010};
        // 3: ST  r3, 2(r0)    ; data_mem[2] <- r3
        instr_mem[3] = {2'b00, 1'b1, 3'b011, 3'b000, 7'b0000010};
        // 4: LD  r4, 2(r0)    ; r4 <- data_mem[2] (should be 8)
        instr_mem[4] = {2'b00, 1'b0, 3'b100, 3'b000, 7'b0000010};
        // 5: NOP (or stop reading useful work)
        instr_mem[5] = 16'h0000;

        // reset + run
        rst = 1'b1;
        #30;
        rst = 1'b0;



		#600

        // show results
        $display("DATA MEM[0]=%0d", data_mem[0]);
        $display("DATA MEM[1]=%0d", data_mem[1]);
        $display("DATA MEM[2]=%0d (expected 8)", data_mem[2]);
        $display("SIM COMPLETE");
        $finish;
    end

	always @(posedge clk) begin
				cycle = cycle + 1;
				#20; // allow combinational outputs to settle after posedge
				$display("CYCLE %0d | PC=%0d | INSTR=%b | MEM_ADDR=%0d | MEM_WR=%b | MEM_DATA_WRITE=%0d | MEM_DATA_IN=%0d",
						cycle, uut.u_PC.pc_out, Instruction, mem_addr, mem_write_enabled, mem_data_write, mem_data_in);
				$display("R1=%b | R2=%b | R3=%b", uut.u_RegisterFile.cpu_registers[0], uut.u_RegisterFile.cpu_registers[1], uut.u_RegisterFile.cpu_registers[2]);
	end
endmodule