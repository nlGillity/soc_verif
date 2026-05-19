`timescale 1ns / 1ps

module testbench;

    parameter int unsigned ApbDataWidth    = 32;
    parameter int unsigned ApbAddrWidth    = 32;
    parameter int unsigned InterruptsCount = 2;   // zero irq is ignored
    parameter int unsigned ClockPeriod     = 100;
    parameter int unsigned ReceiverPort    = 0;
    parameter int unsigned SenderPort      = 0;
    parameter string       Address         = "";

    //==============================================================================

    logic                         clk = 1;
    logic [InterruptsCount - 1:0] interrupts;

    initial begin
        clk = '0;
        forever #(ClockPeriod / 2) clk = ~clk;
    end

    //==============================================================================

    renode #(
        .BusControllersCount ( 1               ),
        .InterruptsCount     ( InterruptsCount )
    ) renode (
        .clk                 ( clk             ),
        .interrupts          ( interrupts      )
    );

    renode_apb3_if #(
        .AddressWidth ( ApbAddrWidth ), 
        .DataWidth    ( ApbDataWidth )
    ) apb (clk);

    renode_apb3_requester renode_apb3_requester (
        .bus        ( apb                   ),
        .connection ( renode.bus_controller )
    );

    logic loopback;
    uart_requester uart_requester (
        .clk                          ( clk      ),
        .cfg_bus_connection           ( apb      ),
        .communication_bus_connection (          ),
        .tx_o                         ( loopback ),
        .rx_i                         ( loopback )
    );

    initial begin
        if (Address != "") 
            renode.connection.connect(ReceiverPort, SenderPort, Address);
        renode.reset();
    end

    //==============================================================================

    parameter int unsigned DataWidth      = 8;
    parameter int unsigned BufferDepth    = 2;
    parameter int unsigned LogBufferDepth = $clog2(BufferDepth);

    apb_uart #(
        .DATA_WIDTH   ( DataWidth   ),
        .BUFFER_DEPTH ( BufferDepth )
    ) DUT (
        .CLK     ( clk           ),
        .RSTN    ( apb.presetn   ),
        .PADDR   ( apb.paddr     ),
        .PWDATA  ( apb.pwdata    ),
        .PWRITE  ( apb.pwrite    ),
        .PSEL    ( apb.pselx     ),
        .PENABLE ( apb.penable   ),
        .PRDATA  ( apb.prdata    ),
        .PREADY  ( apb.pready    ),
        .PSLVERR ( apb.pslverr   ),
        .rx_i    ( loopback      ),
        .tx_o    ( loopback      ),
        .event_o ( interrupts[1] )
    );

    //==============================================================================

    always @(posedge clk) begin
        // The receive method blocks execution of the simulation.
        // It waits until receive a message from Renode.
        renode.receive_and_handle_message();
        if (!renode.connection.is_connected()) $finish;
    end

    //==============================================================================

endmodule
