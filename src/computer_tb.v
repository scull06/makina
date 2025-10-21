module computer_tb;
    reg clk = 1'b0;
    reg rst;

    Computer u_Computer(
        .clk 	(clk  ),
        .rst 	(rst  )
    );
    
    program_tracer tracer(
        .clk(clk),
        .PC(u_Computer.pc_addr),
        .instr(u_Computer.instruction),
        .cpu_registers(u_Computer.u_MCPU.u_RegisterFile.cpu_registers),
        .mem_addr(u_Computer.mem_addr),
        .mem_data_in(u_Computer.cur_memory_data),
        .mem_data_out(u_Computer.mem_data_write),
        .mem_write(u_Computer.mem_write_enabled),
        .stage(u_Computer.u_MCPU.stage)
    );

    integer cycle = 0; //Parameter for the number of instructions to be executed ....

    initial begin
        $display("Starting Computer simulation");

        // u_Computer.u_RAM.memory[0]= 16'd1125;
        // u_Computer.u_RAM.memory[1]= 16'd115;
        //initialization of program and memory
        $readmemb("tests/p1", u_Computer.u_ROM.memory);

        #100
        clk = 1'b0;
        #10
        rst = 1'b1;
        #50
        rst = 1'b0;
        forever #20 clk = ~clk;
    end

    always @(posedge clk) begin
        cycle = cycle + 1;
        if (cycle == 40) begin
            $display("Memory Dump \n_________");
            for (cycle = 0; cycle < 10; cycle=cycle+1) begin
                $display("%d %0d", cycle, u_Computer.u_RAM.memory[cycle]);
            end
            $display("_________\nEnd to Computer test simulation...");
            $finish;
         end
    end
endmodule