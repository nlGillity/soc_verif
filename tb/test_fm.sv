module testbench #(
    parameter DATA_WIDTH = 8,
    parameter BUFFER_DEPTH = 2,
    parameter LOG_BUFFER_DEPTH = $clog2(BUFFER_DEPTH)
)(
    input  logic                      clk_i,
    input  logic                      rstn_i,

    input  logic                      clr_i,
    input  logic                      ready_i,
    input  logic                      valid_i,
    input  logic [DATA_WIDTH-1 : 0]   data_i,

    output logic [LOG_BUFFER_DEPTH:0] elements_o,
    output logic [DATA_WIDTH-1 : 0]   data_o,
    output logic                      valid_o,
    output logic                      ready_o

);

    io_generic_fifo DUT (
        .clk_i      ( clk_i      ),
        .rstn_i     ( rstn_i     ),
        .clr_i      ( clr_i      ),
        .elements_o ( elements_o ),
        .data_o     ( data_o     ),
        .valid_o    ( valid_o    ),
        .ready_i    ( ready_i    ),
        .valid_i    ( valid_i    ),
        .data_i     ( data_i     ),
        .ready_o    ( ready_o    )
    );

    `include "uart_fifo_sva.sv"

endmodule