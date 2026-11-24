`timescale 1ns / 1ps

// Directed, experimental precise-exception side-effect checks.
// This is NOT a proof of full architectural precise-exception compliance.
module processor_pipeline_trap_precise_tb;
  reg clk;
  reg rst;
  integer passed;
  integer failed;
  integer older_store_count;
  integer younger_store_count;
  integer total_store_count;

  processor_pipeline_trap_top dut (
    .clk(clk),
    .rst(rst)
  );

  task tick;
    begin
      #5 clk = 1'b1;
      #5 clk = 1'b0;
      #1;
    end
  endtask

  task check;
    input condition;
    input [255:0] description;
    begin
      if (condition === 1'b1) begin
        passed = passed + 1;
        $display("PASS: %0s", description);
      end else begin
        failed = failed + 1;
        $display("FAIL: %0s", description);
      end
    end
  endtask

  // Observe actual writes to data memory, rather than relying solely on
  // the eventual register contents of squashed instructions.
  always @(posedge clk) begin
    if (!rst && dut.active_mem_write === 1'b1) begin
      total_store_count = total_store_count + 1;
      if (dut.mem_alu_result == 32'd0 &&
          dut.mem_store_data == 32'd17)
        older_store_count = older_store_count + 1;
      if (dut.mem_alu_result == 32'd4 ||
          dut.mem_alu_result == 32'd8)
        younger_store_count = younger_store_count + 1;
    end
  end

  task fill_handler;
    integer i;
    begin
      // Keep execution in the handler without generating unrelated traps.
      for (i = 64; i < 96; i = i + 1)
        dut.imem.memory[i] = 32'h00000013; // addi x0,x0,0
    end
  endtask

  initial begin
    clk = 0;
    rst = 1;
    passed = 0;
    failed = 0;
    older_store_count = 0;
    younger_store_count = 0;
    total_store_count = 0;

    #2;
    fill_handler();

    // TEST 1: ID-stage illegal instruction. Older ADDI and SW must commit;
    // younger ADDI and SW must not have any architectural side effect.
    dut.imem.memory[0] = 32'h01100293; // addi x5,x0,17
    dut.imem.memory[1] = 32'h00502023; // sw x5,0(x0)
    dut.imem.memory[2] = 32'hFFFFFFFF; // illegal instruction
    dut.imem.memory[3] = 32'h06300393; // addi x7,x0,99 (younger)
    dut.imem.memory[4] = 32'h00702223; // sw x7,4(x0) (younger)

    repeat (2) tick();
    rst = 0;
    repeat (13) tick();

    $display("\nTEST 1: Older and younger side effects at ID exception");
    check(dut.trap_active === 1'b1, "ID trap active");
    check(dut.trap_mcause === 32'd2, "ID illegal instruction cause");
    check(dut.trap_mepc === 32'd8, "ID faulting instruction PC");
    check(dut.trap_mtval === 32'hFFFFFFFF, "ID illegal instruction tval");
    check(dut.rf.registers[5] === 32'd17, "Older ADDI committed");
    check(older_store_count == 1, "Older SW committed exactly once");
    check(dut.rf.registers[7] === 32'd0, "Younger ADDI was squashed");
    check(younger_store_count == 0, "Younger SW did not write memory");
    check(total_store_count == 1, "No unexpected memory stores");

    // TEST 2: MEM-stage misaligned LW. An older ADDI in WB must commit,
    // and younger instructions must not write registers or memory.
    rst = 1;
    older_store_count = 0;
    younger_store_count = 0;
    total_store_count = 0;
    fill_handler();

    dut.imem.memory[0] = 32'h01F00413; // addi x8,x0,31
    dut.imem.memory[1] = 32'h00102483; // lw x9,1(x0) (misaligned)
    dut.imem.memory[2] = 32'h00002423; // sw x0,8(x0) (younger)
    dut.imem.memory[3] = 32'h02C00513; // addi x10,x0,44 (younger)

    repeat (2) tick();
    rst = 0;
    repeat (13) tick();

    $display("\nTEST 2: Older and younger side effects at MEM exception");
    check(dut.trap_active === 1'b1, "MEM trap active");
    check(dut.trap_mcause === 32'd4, "MEM misaligned load cause");
    check(dut.trap_mepc === 32'd4, "MEM faulting load PC");
    check(dut.trap_mtval === 32'd1, "MEM faulting memory address");
    check(dut.rf.registers[8] === 32'd31, "Older WB instruction committed");
    check(dut.rf.registers[9] === 32'd0, "Faulting LW did not write back");
    check(dut.rf.registers[10] === 32'd0, "Younger ADDI was squashed");
    check(total_store_count == 0, "Younger SW did not write memory");

    $display("\n==============================================");
    $display(" PRECISE-EXCEPTION SIDE-EFFECT REGRESSION");
    $display("==============================================");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);
    if (passed == 17 && failed == 0)
      $display("ALL 17 PRECISE-EXCEPTION CHECKS PASSED");
    else
      $fatal(1, "PRECISE-EXCEPTION SIDE-EFFECT TEST FAILED");
    $finish;
  end
endmodule
