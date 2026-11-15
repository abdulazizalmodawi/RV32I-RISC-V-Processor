
`timescale 1ns / 1ps

module trap_controller_tb;

  reg clk;
  reg rst;
  reg exception_valid;
  reg [31:0] exception_cause;
  reg [31:0] exception_pc;
  reg [31:0] exception_tval;
  reg trap_return;
  reg [31:0] return_address;

  wire [31:0] mepc;
  wire [31:0] mcause;
  wire [31:0] mtval;
  wire trap_active;
  wire trap_redirect;
  wire [31:0] trap_target;
  wire trap_flush;

  integer passed;
  integer failed;

  localparam [31:0] VECTOR = 32'h00000100;

  trap_controller #(
    .TRAP_VECTOR(VECTOR)
  ) dut (
    .clk(clk),
    .rst(rst),
    .exception_valid(exception_valid),
    .exception_cause(exception_cause),
    .exception_pc(exception_pc),
    .exception_tval(exception_tval),
    .trap_return(trap_return),
    .return_address(return_address),
    .mepc(mepc),
    .mcause(mcause),
    .mtval(mtval),
    .trap_active(trap_active),
    .trap_redirect(trap_redirect),
    .trap_target(trap_target),
    .trap_flush(trap_flush)
  );

  task tick;
    begin
      #5 clk = 1'b1;
      #1;
      clk = 1'b0;
      #4;
    end
  endtask

  task check_state;
    input [31:0] exp_mepc;
    input [31:0] exp_mcause;
    input [31:0] exp_mtval;
    input exp_active;
    input [255:0] name;
    begin
      if ({mepc, mcause, mtval, trap_active} ===
          {exp_mepc, exp_mcause, exp_mtval, exp_active}) begin
        passed = passed + 1;
        $display("PASS: %0s", name);
      end else begin
        failed = failed + 1;
        $display("FAIL: %0s", name);
        $display("  mepc=%h mcause=%h mtval=%h active=%b",
                 mepc, mcause, mtval, trap_active);
      end
    end
  endtask

  task check_control;
    input exp_redirect;
    input [31:0] exp_target;
    input exp_flush;
    input [255:0] name;
    begin
      #1;
      if ({trap_redirect, trap_target, trap_flush} ===
          {exp_redirect, exp_target, exp_flush}) begin
        passed = passed + 1;
        $display("PASS: %0s", name);
      end else begin
        failed = failed + 1;
        $display("FAIL: %0s", name);
        $display("  redirect=%b target=%h flush=%b",
                 trap_redirect, trap_target, trap_flush);
      end
    end
  endtask

  initial begin
    clk = 0;
    rst = 0;
    exception_valid = 0;
    exception_cause = 0;
    exception_pc = 0;
    exception_tval = 0;
    trap_return = 0;
    return_address = 0;
    passed = 0;
    failed = 0;

    // Reset
    rst = 1;
    tick();
    check_state(0, 0, 0, 0, "Reset clears trap state");

    rst = 0;
    check_control(0, 0, 0, "Idle control outputs");

    // Illegal instruction exception
    exception_valid = 1;
    exception_cause = 2;
    exception_pc = 32'h00000020;
    exception_tval = 32'hFFFFFFFF;

    check_control(1, VECTOR, 1,
                  "Exception redirects to trap vector");

    tick();
    check_state(32'h20, 2, 32'hFFFFFFFF, 1,
                "Illegal instruction context saved");

    // No request: retain trap context
    exception_valid = 0;
    tick();
    check_state(32'h20, 2, 32'hFFFFFFFF, 1,
                "Trap context retained");

    // Load address misaligned
    exception_valid = 1;
    exception_cause = 4;
    exception_pc = 32'h00000040;
    exception_tval = 32'h00000003;
    tick();
    check_state(32'h40, 4, 3, 1,
                "Load misalignment context saved");

    // Store address misaligned
    exception_cause = 6;
    exception_pc = 32'h00000060;
    exception_tval = 32'h00000005;
    tick();
    check_state(32'h60, 6, 5, 1,
                "Store misalignment context saved");

    // Trap return
    exception_valid = 0;
    trap_return = 1;
    return_address = 32'h00000060;

    check_control(1, 32'h60, 1,
                  "Trap return redirect");

    tick();
    check_state(32'h60, 6, 5, 0,
                "Trap return clears active flag");

    // Return does not erase saved context
    trap_return = 0;
    tick();
    check_state(32'h60, 6, 5, 0,
                "Saved context retained after return");

    // Simultaneous exception and return:
    // exception has priority
    exception_valid = 1;
    exception_cause = 0;
    exception_pc = 32'h00000080;
    exception_tval = 32'h00000082;
    trap_return = 1;
    return_address = 32'h00000060;

    check_control(1, VECTOR, 1,
                  "Exception priority in redirect");

    tick();
    check_state(32'h80, 0, 32'h82, 1,
                "Exception priority in state update");

    // Clear both requests
    exception_valid = 0;
    trap_return = 0;
    check_control(0, 0, 0, "Control returns to idle");

    // Retain state with no active request
    tick();
    check_state(32'h80, 0, 32'h82, 1,
                "State retained without new request");

    // Second return
    trap_return = 1;
    return_address = 32'h00000084;
    check_control(1, 32'h84, 1,
                  "Second trap return redirect");

    tick();
    check_state(32'h80, 0, 32'h82, 0,
                "Second return clears active flag");

    // Reset after trap activity
    trap_return = 0;
    rst = 1;
    tick();
    check_state(0, 0, 0, 0,
                "Reset clears previous trap context");

    // Reset is synchronous: held until clock edge
    rst = 0;
    exception_valid = 1;
    exception_cause = 2;
    exception_pc = 32'h000000A0;
    exception_tval = 32'h00000013;
    tick();
    check_state(32'hA0, 2, 32'h13, 1,
                "New exception after reset");

    // Active trap remains active without return
    exception_valid = 0;
    tick();
    check_state(32'hA0, 2, 32'h13, 1,
                "Active trap persists");

    // Final reset
    rst = 1;
    tick();
    check_state(0, 0, 0, 0, "Final reset");

    $display("----------------------------------");
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);

    if (passed == 20 && failed == 0)
      $display("TRAP CONTROLLER TEST PASSED");
    else
      $fatal(1, "TRAP CONTROLLER TEST FAILED");

    $finish;
  end

endmodule
