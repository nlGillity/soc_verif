`timescale 1ns / 1ps

module sim;
  parameter int unsigned ApbDataWidth = 32;
  parameter int unsigned ApbAddrWidth = 20;
  parameter int unsigned TimersCnt = 2;
  parameter int unsigned InterruptsCount = TimersCnt;
  parameter int ClockPeriod = 100;
  parameter int ReceiverPort = 0;
  parameter int SenderPort = 0;
  parameter string Address = "";

  logic clk = 1;
  logic[InterruptsCount - 1:0] interrupts;

  renode # (
      .BusControllersCount(1),
      .InterruptsCount(InterruptsCount)
  ) renode (
      .clk(clk),
      .interrupts(interrupts)
  );

  renode_apb3_if #(
    .AddressWidth(ApbAddrWidth), 
    .DataWidth(ApbDataWidth)
  ) apb (clk);

  renode_apb3_requester renode_apb3_requester (
      .bus(apb),
      .connection(renode.bus_controller)
  );

  initial begin
    if (Address != "") renode.connection.connect(ReceiverPort, SenderPort, Address);
    renode.reset();
  end

  always @(posedge clk) begin
    // The receive method blocks execution of the simulation.
    // It waits until receive a message from Renode.
    renode.receive_and_handle_message();
    if (!renode.connection.is_connected()) $finish;
  end

  always #(ClockPeriod / 2) clk = ~clk;

  apb_timer #(
    .APB_ADDR_WIDTH(ApbAddrWidth),
    .TIMER_CNT(TimersCnt)
  ) dut (
    .HCLK(clk),
    .HRESETn(apb.presetn),
    .PADDR(apb.paddr),
    .PWDATA(apb.pwdata),
    .PWRITE(apb.pwrite),
    .PSEL(apb.pselx),
    .PENABLE(apb.penable),
    .PRDATA(apb.prdata),
    .PREADY(apb.pready),
    .PSLVERR(apb.pslverr),
    .irq_o(interrupts)

);

endmodule
