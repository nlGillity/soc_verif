module miter #(
    parameter DATA_WIDTH = 8,
    parameter BUFFER_DEPTH = 2,
    parameter LOG_BUFFER_DEPTH = $clog2(BUFFER_DEPTH)
)(
    input  logic                    clk,
    input  logic                    rstn,

    input  logic                    ref_clr_i,
    input  logic                    ref_ready_i,
    input  logic                    ref_valid_i,
    input  logic [DATA_WIDTH-1 : 0] ref_data_i,

    input  logic                    uut_clr_i,
    input  logic                    uut_ready_i,
    input  logic                    uut_valid_i,
    input  logic [DATA_WIDTH-1 : 0] uut_data_i
);

    wire [LOG_BUFFER_DEPTH:0] ref_elements_o;
    wire [DATA_WIDTH-1 : 0]   ref_data_o;
    wire                      ref_valid_o;
    wire                      ref_ready_o;

    io_generic_fifo ref (
        .clk_i            ( clk              ),
        .rstn_i           ( rstn             ),
        .clr_i            ( ref_clr_i        ),
        .elements_o       ( ref_elements_o   ),
        .data_o           ( ref_data_o       ),
        .valid_o          ( ref_valid_o      ),
        .ready_i          ( ref_ready_i      ),
        .valid_i          ( ref_valid_i      ),
        .data_i           ( ref_data_i       ),
        .ready_o          ( ref_ready_o      ),
        .mutsel           ( 1'b0             )
    );

    wire [LOG_BUFFER_DEPTH:0] uut_elements_o;
    wire [DATA_WIDTH-1 : 0]   uut_data_o;
    wire                      uut_valid_o;
    wire                      uut_ready_o;

    io_generic_fifo uut (
        .clk_i            ( clk              ),
        .rstn_i           ( rstn             ),
        .clr_i            ( uut_clr_i        ),
        .elements_o       ( uut_elements_o   ),
        .data_o           ( uut_data_o       ),
        .valid_o          ( uut_valid_o      ),
        .ready_i          ( uut_ready_i      ),
        .valid_i          ( uut_valid_i      ),
        .data_i           ( uut_data_i       ),
        .ready_o          ( uut_ready_o      ),
        .mutsel           ( 1'b1             )
    );

    initial assume(!rstn && !ref_clr_i);

    always_ff @(posedge clk)
        if (rstn) begin
            assume(ref_clr_i   == uut_clr_i);
            assume(ref_ready_i == uut_ready_i);
            assume(ref_valid_i == uut_valid_i);
            assume(ref_data_i  == uut_data_i);
            assume(ref_data_o  == uut_data_o);
        end

    always_ff @(posedge clk)
        if (rstn) begin
            assert(ref_elements_o == uut_elements_o);
            assert(ref_ready_o    == uut_ready_o);
            assert(ref_valid_o    == uut_valid_o);
        end

endmodule