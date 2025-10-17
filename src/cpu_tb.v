module cpu_tb;

    reg clk;
    reg rst;
    reg [15:0] Instruction;
    reg [15:0] mem_data_in;

    wire [15:0] pc_addr_out;
    wire [15:0] mem_addr;
    wire [15:0] mem_data_write;
    wire        mem_write_enabled;

    // small instr + data memory
    reg [15:0] data_mem  [0:63];

    // simple clock generator
    initial clk = 1'b0;
    always #20 clk = ~clk;

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

    ProgramMemory #(
        .MEM_SIZE  	(5),
        .FILE_PATH 	("tests/p0"))
    u_ProgramMemory(
        .address     	(pc_addr_out  ),
        .instruction 	(Instruction  )
    );
    

    program_tracer tracer(
        .clk(clk),
        .PC(pc_addr_out),
        .instr(Instruction),
        .cpu_registers(uut.u_RegisterFile.cpu_registers),
        .mem_addr(mem_addr),
        .mem_data_in(mem_data_in),
        .mem_data_out(mem_data_write),
        .mem_write(mem_write_enabled),
        .mem_read(uut.u_decoder.mem_read)
    );



    // // always present data bus: drive mem_data_in from data_mem at mem_addr
    always @(*) begin
        mem_data_in = data_mem[mem_addr];
    end

    // perform memory writes from CPU when mem_write_enabled asserted
    integer cycle = 0;
    always @(posedge clk) begin
        if (mem_write_enabled) begin
            data_mem[mem_addr] <= mem_data_write;
        end

        cycle = cycle + 1;
        
        if (cycle == 10) begin
            for (cycle = 0; cycle < 10; cycle=cycle+1) begin
                $display("%d %b", cycle, data_mem[cycle]);
            end
            $finish;
        end
    end

    
    integer i;
    initial begin
        for (i=0; i<64; i = i+1) data_mem[i]  = 16'h0000;

        data_mem[0]= 16'd5;
        data_mem[1]= 16'd3;

        // reset + run
        #10
        rst = 1'b1;
        #20;
        rst = 1'b0;
    end


endmodule



