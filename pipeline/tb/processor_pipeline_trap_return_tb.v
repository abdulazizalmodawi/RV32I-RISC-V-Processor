`timescale 1ns / 1ps

module processor_pipeline_trap_return_tb;
  reg clk;
  reg rst;
  integer passed;
  integer failed;
  integer cycle;
  reg saw_entry;
  reg saw_return;
  reg saw_mepc_write;
  reg saw_resume_pc;

  processor_pipeline_trap_top dut (.clk(clk), .rst(rst));

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

  initial begin
    clk = 0;
    rst = 1;
    passed = 0;
    failed = 0;
    saw_entry = 0;
    saw_return = 0;
    saw_mepc_write = 0;
    saw_resume_pc = 0;

    #2;
    // PC=0: an illegal instruction causes an exception.
    dut.imem.memory[0] = 32'hFFFFFFFF;
    // PC=4: resume with addi x5,x0,42.
    dut.imem.memory[1] = 32'h02A00293;
    // PC=8: loop here, preventing fall-through.
    dut.imem.memory[2] = 32'h0000006F;
    // Trap handler: CSRRWI x0,mepc,4 followed by MRET.
    // MRET itself returns to the MEPC written by the handler.
    dut.imem.memory[64] = 32'h34125073;
    dut.imem.memory[65] = 32'h30200073;

    repeat (2) tick();
    rst = 0;

    for (cycle = 0; cycle < 30; cycle = cycle + 1) begin
      // Sample return request before clock edge.
      #1;
      if (dut.trap_active && dut.pc == 32'h00000100)
        saw_entry = 1;
      if (dut.mepc_write_request)
        saw_mepc_write = 1;
      if (dut.trap_return_request)
        saw_return = 1;
      tick();
      if (saw_return && dut.pc == 32'd4)
        saw_resume_pc = 1;
    end

    $display("--- Experimental MRET return verification ---");
    check(saw_entry, "Trap handler entered at 0x100");
    check(saw_mepc_write, "Trap handler writes MEPC");
    check(saw_return, "MRET return request asserted");
    check(saw_resume_pc, "Return redirects to PC 4");
    check(dut.trap_active === 1'b0, "Trap active flag cleared");
    check(dut.trap_mepc === 32'd4, "MEPC updated by handler");
    check(dut.trap_mcause === 32'd2, "Illegal instruction cause retained");
    check(dut.trap_mtval === 32'hFFFFFFFF, "Illegal instruction value retained");
    check(dut.rf.registers[5] === 32'd42, "Execution resumes after faulting instruction");

    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);
    if (passed == 9 && failed == 0)
      $display("ALL 9 EXPERIMENTAL TRAP RETURN CHECKS PASSED");
    else
      $fatal(1, "EXPERIMENTAL TRAP RETURN VERIFICATION FAILED");
    $finish;
  end
endmodule
