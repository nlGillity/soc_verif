interface apb_uart_if #(
    parameter APB_ADDR_WIDTH = 12
)(
    input logic clk,
    input logic rstn
);
    //====================================================================
    // Signals
    //====================================================================

    /* verilator lint_off UNUSED */
    logic [APB_ADDR_WIDTH-1:0] paddr,
    /* lint_on */
    logic               [31:0] pwdata,
    logic                      pwrite,
    logic                      pselx,
    logic                      penable,
    logic               [31:0] prdata,
    logic                      pready,
    logic                      pslverr,

    logic                      rx_i,
    logic                      tx_o,
    logic                      event_o

    //====================================================================
    // Modports
    //====================================================================

    modport inner (
        output paddr,
        output pwdata,
        output psel,
        output penable,
        input  prdata,
        input  pready,
        input  pslverr
    );

    modport outer (
        output rx_i,
        input  tx_o,
        input  event_o
    );

    //====================================================================
    // SVA
    //====================================================================

    
    
endinterface