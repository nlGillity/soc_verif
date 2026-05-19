
`include "scr1_arch_description.svh"
`include "scr1_ipic.svh"


module soc_top_tb_axi (
    input logic clk
);

//------------------------------------------------------------------------------
// Local parameters
//------------------------------------------------------------------------------
localparam                          SCR1_MEM_SIZE       = 64*1024*1024;
localparam                          TIMEOUT             = 'd40_0000;//40ms;
localparam                          ARCH                = 'h1;
localparam                          COMPLIANCE          = 'h2;
localparam                          ADDR_START          = 'h200;
localparam                          ADDR_TRAP_VECTOR    = 'h240;
localparam                          ADDR_TRAP_DEFAULT   = 'h1C0;

//------------------------------------------------------------------------------
// Internal signals
//------------------------------------------------------------------------------

logic                                   rst_n;
logic                                   rtc_clk     = 1'b0;
logic   [31:0]                          fuse_mhartid;
integer                                 imem_req_ack_stall;
integer                                 dmem_req_ack_stall;

logic [SCR1_IRQ_LINES_NUM-1:0]          irq_lines;
logic                                   soft_irq;

logic                                   trst_n;
logic                                   tck;
logic                                   tms;
logic                                   tdi;
logic                                   tdo;
logic                                   tdo_en;

AXI_BUS #(
    .AXI_ADDR_WIDTH ( 32     ),
    .AXI_DATA_WIDTH ( 32     ),
    .AXI_ID_WIDTH   ( 8 ),
    .AXI_USER_WIDTH ( 5     )
)
slaves[1:0]();

AXI_BUS #(
    .AXI_ADDR_WIDTH ( 32      ),
    .AXI_DATA_WIDTH ( 32      ),
    .AXI_ID_WIDTH   ( 8 ),
    .AXI_USER_WIDTH ( 5      )
)
masters[4:0]();

// 0 - UART
// 1 - SPI
// 2 - GPR
// 3 - TIMER
APB_BUS apb_masters[3:0] ();


// Wathdogs
int unsigned                            watchdogs_cnt;

int unsigned                            f_results;
int unsigned                            f_info;
string                                  s_results;
string                                  s_info;
`ifdef SIGNATURE_OUT
string                                  s_testname;
bit                                     b_single_run_flag;
`endif  //  SIGNATURE_OUT

logic [255:0]                           test_file;
bit                                     test_running;
int unsigned                            tests_passed;
int unsigned                            tests_total;

bit [1:0]                               rst_cnt;
bit                                     rst_init;

function int identify_test (logic [255:0] testname);
    bit res;
    logic [79:0] pattern_compliance;
    logic [22:0] pattern_arch;
begin
    pattern_compliance = 80'h636f6d706c69616e6365; // compliance
    pattern_arch       = 'h61726368;             // arch
    res = 0;
    for (int i = 0; i<= 176; i++) begin
        if(testname[i+:80] == pattern_compliance) begin
            return COMPLIANCE;
        end
    end
    for (int i = 0; i<= 233; i++) begin
        if(testname[i+:23] == pattern_arch) begin
            return ARCH;
        end
    end
    `ifdef SIGNATURE_OUT
        return ~res;
    `else
        return res;
    `endif
end
endfunction : identify_test

function logic [255:0] get_filename (logic [255:0] testname);
logic [255:0] res;
int i, j;
begin
    testname[7:0] = 8'h66;
    testname[15:8] = 8'h6C;
    testname[23:16] = 8'h65;

    for (i = 0; i <= 248; i += 8) begin
        if (testname[i+:8] == 0) begin
            break;
        end
    end
    i -= 8;
    for (j = 255; i >= 0;i -= 8) begin
        res[j-:8] = testname[i+:8];
        j -= 8;
    end
    for (; j >= 0;j -= 8) begin
        res[j-:8] = 0;
    end

    return res;
end
endfunction : get_filename

function logic [255:0] get_ref_filename (logic [255:0] testname);
    logic [255:0] res;
    int i, j;
    logic [79:0] pattern_compliance;
    logic [22:0] pattern_arch;
    begin
        pattern_compliance = 80'h636f6d706c69616e6365; // compliance
        pattern_arch       = 'h61726368;             // arch

        for(int i = 0; i <= 176; i++) begin
            if(testname[i+:80] == pattern_compliance) begin
                testname[(i-8)+:88] = 0;
                break;
            end
        end

        for(int i = 0; i <= 233; i++) begin
            if(testname[i+:23] == pattern_arch) begin
                testname[(i-8)+:31] = 0;
                break;
            end
        end

        for(i = 32; i <= 248; i += 8) begin
            if(testname[i+:8] == 0) break;
        end
        i -= 8;
        for(j = 255; i > 24; i -= 8) begin
            res[j-:8] = testname[i+:8];
            j -= 8;
        end
        for(; j >=0;j -= 8) begin
            res[j-:8] = 0;
        end

        return res;
    end
    endfunction : get_ref_filename

function logic [2047:0] remove_trailing_whitespaces (logic [2047:0] str);
int i;
begin
    for (i = 0; i <= 2040; i += 8) begin
        if (str[i+:8] != 8'h20) begin
            break;
        end
    end
    str = str >> i;
    return str;
end
endfunction: remove_trailing_whitespaces

// Reset logic
assign rst_n = &rst_cnt;

always_ff @(posedge clk) begin
    if (rst_init)       rst_cnt <= '0;
    else if (~&rst_cnt) rst_cnt <= rst_cnt + 1'b1;
end


initial begin
    trst_n  = 1'b0;
    tck     = 1'b0;
    tdi     = 1'b0;
    #900ns trst_n   = 1'b1;
    #500ns tms      = 1'b1;
    #800ns tms      = 1'b0;
    #500ns trst_n   = 1'b0;
    #100ns tms      = 1'b1;
end

//-------------------------------------------------------------------------------
// Run tests
//-------------------------------------------------------------------------------

`include "scr1_top_tb_runtests.sv"

//------------------------------------------------------------------------------
// Core instance
//------------------------------------------------------------------------------
scr1_top_axi i_top(
    // Reset
    .pwrup_rst_n            (rst_n                  ),
    .rst_n                  (rst_n                  ),
    .cpu_rst_n              (rst_n                  ),
    .sys_rst_n_o            (                       ),
    .sys_rdc_qlfy_o         (                       ),
    // Clock
    .clk                    (clk                    ),
    .rtc_clk                (rtc_clk                ),
    // Fuses
    .fuse_mhartid           (fuse_mhartid           ),
    .fuse_idcode            (`SCR1_TAP_IDCODE       ),
    // IRQ
    .irq_lines              (irq_lines              ),
    .soft_irq               (soft_irq               ),

    // DFT
    .test_mode              (1'b0                   ),
    .test_rst_n             (1'b1                   ),

    .trst_n                 (trst_n                 ),
    .tck                    (tck                    ),
    .tms                    (tms                    ),
    .tdi                    (tdi                    ),
    .tdo                    (tdo                    ),
    .tdo_en                 (tdo_en                 ),

    // Instruction memory interface
.io_axi_imem_awid       (slaves[0].aw_id       ),
    .io_axi_imem_awaddr     (slaves[0].aw_addr     ),
    .io_axi_imem_awlen      (slaves[0].aw_len      ),
    .io_axi_imem_awsize     (slaves[0].aw_size     ),
    .io_axi_imem_awburst    (),
    .io_axi_imem_awlock     (),
    .io_axi_imem_awcache    (),
    .io_axi_imem_awprot     (),
    .io_axi_imem_awregion   (),
    .io_axi_imem_awuser     (),
    .io_axi_imem_awqos      (),
    .io_axi_imem_awvalid    (slaves[0].aw_valid    ),
    .io_axi_imem_awready    (slaves[0].aw_ready    ),
    .io_axi_imem_wdata      (slaves[0].w_data      ),
    .io_axi_imem_wstrb      (slaves[0].w_strb      ),
    .io_axi_imem_wlast      (slaves[0].w_last      ),
    .io_axi_imem_wuser      (),
    .io_axi_imem_wvalid     (slaves[0].w_valid     ),
    .io_axi_imem_wready     (slaves[0].w_ready     ),
    .io_axi_imem_bid        (slaves[0].b_id        ),
    .io_axi_imem_bresp      (slaves[0].b_resp      ),
    .io_axi_imem_bvalid     (slaves[0].b_valid     ),
    .io_axi_imem_buser      (slaves[0].b_user      ),
    .io_axi_imem_bready     (slaves[0].b_ready     ),
    .io_axi_imem_arid       (slaves[0].ar_id       ),
    .io_axi_imem_araddr     (slaves[0].ar_addr     ),
    .io_axi_imem_arlen      (slaves[0].ar_len      ),
    .io_axi_imem_arsize     (slaves[0].ar_size     ),
    .io_axi_imem_arburst    (slaves[0].ar_burst    ),
    .io_axi_imem_arlock     (),
    .io_axi_imem_arcache    (),
    .io_axi_imem_arprot     (),
    .io_axi_imem_arregion   (),
    .io_axi_imem_aruser     (),
    .io_axi_imem_arqos      (),
    .io_axi_imem_arvalid    (slaves[0].ar_valid    ),
    .io_axi_imem_arready    (slaves[0].ar_ready    ),
    .io_axi_imem_rid        (slaves[0].r_id        ),
    .io_axi_imem_rdata      (slaves[0].r_data      ),
    .io_axi_imem_rresp      (slaves[0].r_resp      ),
    .io_axi_imem_rlast      (slaves[0].r_last      ),
    .io_axi_imem_ruser      (slaves[0].r_user      ),
    .io_axi_imem_rvalid     (slaves[0].r_valid     ),
    .io_axi_imem_rready     (slaves[0].r_ready     ),

    // Data memory interface
    .io_axi_dmem_awid       (slaves[1].aw_id       ),
    .io_axi_dmem_awaddr     (slaves[1].aw_addr     ),
    .io_axi_dmem_awlen      (slaves[1].aw_len      ),
    .io_axi_dmem_awsize     (slaves[1].aw_size     ),
    .io_axi_dmem_awburst    (),
    .io_axi_dmem_awlock     (),
    .io_axi_dmem_awcache    (),
    .io_axi_dmem_awprot     (),
    .io_axi_dmem_awregion   (),
    .io_axi_dmem_awuser     (),
    .io_axi_dmem_awqos      (),
    .io_axi_dmem_awvalid    (slaves[1].aw_valid    ),
    .io_axi_dmem_awready    (slaves[1].aw_ready    ),
    .io_axi_dmem_wdata      (slaves[1].w_data      ),
    .io_axi_dmem_wstrb      (slaves[1].w_strb      ),
    .io_axi_dmem_wlast      (slaves[1].w_last      ),
    .io_axi_dmem_wuser      (),
    .io_axi_dmem_wvalid     (slaves[1].w_valid     ),
    .io_axi_dmem_wready     (slaves[1].w_ready     ),
    .io_axi_dmem_bid        (slaves[1].b_id        ),
    .io_axi_dmem_bresp      (slaves[1].b_resp      ),
    .io_axi_dmem_bvalid     (slaves[1].b_valid     ),
    .io_axi_dmem_buser      (slaves[1].b_user      ),
    .io_axi_dmem_bready     (slaves[1].b_ready     ),
    .io_axi_dmem_arid       (slaves[1].ar_id       ),
    .io_axi_dmem_araddr     (slaves[1].ar_addr     ),
    .io_axi_dmem_arlen      (slaves[1].ar_len      ),
    .io_axi_dmem_arsize     (slaves[1].ar_size     ),
    .io_axi_dmem_arburst    (slaves[1].ar_burst    ),
    .io_axi_dmem_arlock     (),
    .io_axi_dmem_arcache    (),
    .io_axi_dmem_arprot     (),
    .io_axi_dmem_arregion   (),
    .io_axi_dmem_aruser     (),
    .io_axi_dmem_arqos      (),
    .io_axi_dmem_arvalid    (slaves[1].ar_valid    ),
    .io_axi_dmem_arready    (slaves[1].ar_ready    ),
    .io_axi_dmem_rid        (slaves[1].r_id        ),
    .io_axi_dmem_rdata      (slaves[1].r_data      ),
    .io_axi_dmem_rresp      (slaves[1].r_resp      ),
    .io_axi_dmem_rlast      (slaves[1].r_last      ),
    .io_axi_dmem_ruser      (slaves[1].r_user      ),
    .io_axi_dmem_rvalid     (slaves[1].r_valid     ),
    .io_axi_dmem_rready     (slaves[1].r_ready     )
);

//------------------------------------------------------------------------------
// Dummy memory 
//------------------------------------------------------------------------------
scr1_memory_tb_axi #(
    .SIZE    (SCR1_MEM_SIZE),
    .N_IF    (1            ),
    .W_ADR   (32           ),
    .W_DATA  (32           ),
    .W_ID    (5            )
) i_memory_tb (
    // Common
    .rst_n          (rst_n),
    .clk            (clk),

    .irq_lines      (),
    .soft_irq       (soft_irq),

    .awid           (masters[0].aw_id   ),
    .awaddr         (masters[0].aw_addr ),
    .awsize         (masters[0].aw_size ),
    .awlen          (masters[0].aw_len  ),
    .awvalid        (masters[0].aw_valid),
    .awready        (masters[0].aw_ready),
    .wdata          (masters[0].w_data  ),
    .wstrb          (masters[0].w_strb  ),
    .wvalid         (masters[0].w_valid ),
    .wlast          (masters[0].w_last  ),
    .wready         (masters[0].w_ready ),
    .bready         (masters[0].b_ready ),
    .bvalid         (masters[0].b_valid ),
    .bid            (masters[0].b_id    ),
    .bresp          (masters[0].b_resp  ),
    .arid           (masters[0].ar_id   ),
    .araddr         (masters[0].ar_addr ),
    .arburst        (masters[0].ar_burst),
    .arsize         (masters[0].ar_size ),
    .arlen          (masters[0].ar_len  ),
    .arvalid        (masters[0].ar_valid),
    .arready        (masters[0].ar_ready),
    .rvalid         (masters[0].r_valid ),
    .rready         (masters[0].r_ready ),
    .rid            (masters[0].r_id    ),
    .rdata          (masters[0].r_data  ),
    .rlast          (masters[0].r_last  ),
    .rresp          (masters[0].r_resp  )
);

axi_interconnect_wrap_5x5 #(
    .ID_WIDTH(8),
    .AWUSER_ENABLE(1),
    .AWUSER_WIDTH(5),
    .WUSER_ENABLE(1),
    .WUSER_WIDTH(5),
    .BUSER_ENABLE(1),
    .BUSER_WIDTH(5),
    .ARUSER_ENABLE(1),
    .ARUSER_WIDTH(5),
    .RUSER_ENABLE(1),
    .RUSER_WIDTH(5)
) axi_ic_i (
    .clk    (clk),
    .rst    (~rst_n),

    .s00_axi_awid                   (slaves[0].aw_id)   ,
    .s00_axi_awaddr                 (slaves[0].aw_addr) ,
    .s00_axi_awlen                  (slaves[0].aw_len)  ,
    .s00_axi_awsize                 (slaves[0].aw_size) ,
    .s00_axi_awburst                (slaves[0].aw_burst),
    .s00_axi_awlock                 (slaves[0].aw_lock) ,
    .s00_axi_awcache                (slaves[0].aw_cache),
    .s00_axi_awprot                 (slaves[0].aw_prot) ,
    .s00_axi_awqos                  (slaves[0].aw_qos)  ,
    .s00_axi_awuser                 (slaves[0].aw_user) ,
    .s00_axi_awvalid                (slaves[0].aw_valid),
    .s00_axi_awready                (slaves[0].aw_ready),
    .s00_axi_wdata                  (slaves[0].w_data)  ,
    .s00_axi_wstrb                  (slaves[0].w_strb)  ,
    .s00_axi_wlast                  (slaves[0].w_last)  ,
    .s00_axi_wuser                  (slaves[0].w_user)  ,
    .s00_axi_wvalid                 (slaves[0].w_valid) ,
    .s00_axi_wready                 (slaves[0].w_ready) ,
    .s00_axi_bid                    (slaves[0].b_id)    ,
    .s00_axi_bresp                  (slaves[0].b_resp)  ,
    .s00_axi_buser                  (slaves[0].b_user)  ,
    .s00_axi_bvalid                 (slaves[0].b_valid) ,
    .s00_axi_bready                 (slaves[0].b_ready) ,
    .s00_axi_arid                   (slaves[0].ar_id)   ,
    .s00_axi_araddr                 (slaves[0].ar_addr) ,
    .s00_axi_arlen                  (slaves[0].ar_len)  ,
    .s00_axi_arsize                 (slaves[0].ar_size) ,
    .s00_axi_arburst                (slaves[0].ar_burst),
    .s00_axi_arlock                 (slaves[0].ar_lock) ,
    .s00_axi_arcache                (slaves[0].ar_cache),
    .s00_axi_arprot                 (slaves[0].ar_prot) ,
    .s00_axi_arqos                  (slaves[0].ar_qos)  ,
    .s00_axi_aruser                 (slaves[0].ar_user) ,
    .s00_axi_arvalid                (slaves[0].ar_valid),
    .s00_axi_arready                (slaves[0].ar_ready),
    .s00_axi_rid                    (slaves[0].r_id)    ,
    .s00_axi_rdata                  (slaves[0].r_data)  ,
    .s00_axi_rresp                  (slaves[0].r_resp)  ,
    .s00_axi_rlast                  (slaves[0].r_last)  ,
    .s00_axi_ruser                  (slaves[0].r_user)  ,
    .s00_axi_rvalid                 (slaves[0].r_valid) ,
    .s00_axi_rready                 (slaves[0].r_ready) ,
 
    .s01_axi_awid                   (slaves[1].aw_id)   ,
    .s01_axi_awaddr                 (slaves[1].aw_addr) ,
    .s01_axi_awlen                  (slaves[1].aw_len)  ,
    .s01_axi_awsize                 (slaves[1].aw_size) ,
    .s01_axi_awburst                (slaves[1].aw_burst),
    .s01_axi_awlock                 (slaves[1].aw_lock) ,
    .s01_axi_awcache                (slaves[1].aw_cache),
    .s01_axi_awprot                 (slaves[1].aw_prot) ,
    .s01_axi_awqos                  (slaves[1].aw_qos)  ,
    .s01_axi_awuser                 (slaves[1].aw_user) ,
    .s01_axi_awvalid                (slaves[1].aw_valid),
    .s01_axi_awready                (slaves[1].aw_ready),
    .s01_axi_wdata                  (slaves[1].w_data)  ,
    .s01_axi_wstrb                  (slaves[1].w_strb)  ,
    .s01_axi_wlast                  (slaves[1].w_last)  ,
    .s01_axi_wuser                  (slaves[1].w_user)  ,
    .s01_axi_wvalid                 (slaves[1].w_valid) ,
    .s01_axi_wready                 (slaves[1].w_ready) ,
    .s01_axi_bid                    (slaves[1].b_id)    ,
    .s01_axi_bresp                  (slaves[1].b_resp)  ,
    .s01_axi_buser                  (slaves[1].b_user)  ,
    .s01_axi_bvalid                 (slaves[1].b_valid) ,
    .s01_axi_bready                 (slaves[1].b_ready) ,
    .s01_axi_arid                   (slaves[1].ar_id)   ,
    .s01_axi_araddr                 (slaves[1].ar_addr) ,
    .s01_axi_arlen                  (slaves[1].ar_len)  ,
    .s01_axi_arsize                 (slaves[1].ar_size) ,
    .s01_axi_arburst                (slaves[1].ar_burst),
    .s01_axi_arlock                 (slaves[1].ar_lock) ,
    .s01_axi_arcache                (slaves[1].ar_cache),
    .s01_axi_arprot                 (slaves[1].ar_prot) ,
    .s01_axi_arqos                  (slaves[1].ar_qos)  ,
    .s01_axi_aruser                 (slaves[1].ar_user) ,
    .s01_axi_arvalid                (slaves[1].ar_valid),
    .s01_axi_arready                (slaves[1].ar_ready),
    .s01_axi_rid                    (slaves[1].r_id)    ,
    .s01_axi_rdata                  (slaves[1].r_data)  ,
    .s01_axi_rresp                  (slaves[1].r_resp)  ,
    .s01_axi_rlast                  (slaves[1].r_last)  ,
    .s01_axi_ruser                  (slaves[1].r_user)  ,
    .s01_axi_rvalid                 (slaves[1].r_valid) ,
    .s01_axi_rready                 (slaves[1].r_ready) ,

    .m00_axi_awid                   (masters[0].aw_id)   ,
    .m00_axi_awaddr                 (masters[0].aw_addr) ,
    .m00_axi_awlen                  (masters[0].aw_len)  ,
    .m00_axi_awsize                 (masters[0].aw_size) ,
    .m00_axi_awburst                (masters[0].aw_burst),
    .m00_axi_awlock                 (masters[0].aw_lock) ,
    .m00_axi_awcache                (masters[0].aw_cache),
    .m00_axi_awprot                 (masters[0].aw_prot) ,
    .m00_axi_awqos                  (masters[0].aw_qos)  ,
    .m00_axi_awuser                 (masters[0].aw_user) ,
    .m00_axi_awvalid                (masters[0].aw_valid),
    .m00_axi_awready                (masters[0].aw_ready),
    .m00_axi_wdata                  (masters[0].w_data)  ,
    .m00_axi_wstrb                  (masters[0].w_strb)  ,
    .m00_axi_wlast                  (masters[0].w_last)  ,
    .m00_axi_wuser                  (masters[0].w_user)  ,
    .m00_axi_wvalid                 (masters[0].w_valid) ,
    .m00_axi_wready                 (masters[0].w_ready) ,
    .m00_axi_bid                    (masters[0].b_id)    ,
    .m00_axi_bresp                  (masters[0].b_resp)  ,
    .m00_axi_buser                  (masters[0].b_user)  ,
    .m00_axi_bvalid                 (masters[0].b_valid) ,
    .m00_axi_bready                 (masters[0].b_ready) ,
    .m00_axi_arid                   (masters[0].ar_id)   ,
    .m00_axi_araddr                 (masters[0].ar_addr) ,
    .m00_axi_arlen                  (masters[0].ar_len)  ,
    .m00_axi_arsize                 (masters[0].ar_size) ,
    .m00_axi_arburst                (masters[0].ar_burst),
    .m00_axi_arlock                 (masters[0].ar_lock) ,
    .m00_axi_arcache                (masters[0].ar_cache),
    .m00_axi_arprot                 (masters[0].ar_prot) ,
    .m00_axi_arqos                  (masters[0].ar_qos)  ,
    .m00_axi_aruser                 (masters[0].ar_user) ,
    .m00_axi_arvalid                (masters[0].ar_valid),
    .m00_axi_arready                (masters[0].ar_ready),
    .m00_axi_rid                    (masters[0].r_id)    ,
    .m00_axi_rdata                  (masters[0].r_data)  ,
    .m00_axi_rresp                  (masters[0].r_resp)  ,
    .m00_axi_rlast                  (masters[0].r_last)  ,
    .m00_axi_ruser                  (masters[0].r_user)  ,
    .m00_axi_rvalid                 (masters[0].r_valid) ,
    .m00_axi_rready                 (masters[0].r_ready) ,

    .m01_axi_awid                   (masters[1].aw_id)   ,
    .m01_axi_awaddr                 (masters[1].aw_addr) ,
    .m01_axi_awlen                  (masters[1].aw_len)  ,
    .m01_axi_awsize                 (masters[1].aw_size) ,
    .m01_axi_awburst                (masters[1].aw_burst),
    .m01_axi_awlock                 (masters[1].aw_lock) ,
    .m01_axi_awcache                (masters[1].aw_cache),
    .m01_axi_awprot                 (masters[1].aw_prot) ,
    .m01_axi_awqos                  (masters[1].aw_qos)  ,
    .m01_axi_awuser                 (masters[1].aw_user) ,
    .m01_axi_awvalid                (masters[1].aw_valid),
    .m01_axi_awready                (masters[1].aw_ready),
    .m01_axi_wdata                  (masters[1].w_data)  ,
    .m01_axi_wstrb                  (masters[1].w_strb)  ,
    .m01_axi_wlast                  (masters[1].w_last)  ,
    .m01_axi_wuser                  (masters[1].w_user)  ,
    .m01_axi_wvalid                 (masters[1].w_valid) ,
    .m01_axi_wready                 (masters[1].w_ready) ,
    .m01_axi_bid                    (masters[1].b_id)    ,
    .m01_axi_bresp                  (masters[1].b_resp)  ,
    .m01_axi_buser                  (masters[1].b_user)  ,
    .m01_axi_bvalid                 (masters[1].b_valid) ,
    .m01_axi_bready                 (masters[1].b_ready) ,
    .m01_axi_arid                   (masters[1].ar_id)   ,
    .m01_axi_araddr                 (masters[1].ar_addr) ,
    .m01_axi_arlen                  (masters[1].ar_len)  ,
    .m01_axi_arsize                 (masters[1].ar_size) ,
    .m01_axi_arburst                (masters[1].ar_burst),
    .m01_axi_arlock                 (masters[1].ar_lock) ,
    .m01_axi_arcache                (masters[1].ar_cache),
    .m01_axi_arprot                 (masters[1].ar_prot) ,
    .m01_axi_arqos                  (masters[1].ar_qos)  ,
    .m01_axi_aruser                 (masters[1].ar_user) ,
    .m01_axi_arvalid                (masters[1].ar_valid),
    .m01_axi_arready                (masters[1].ar_ready),
    .m01_axi_rid                    (masters[1].r_id)    ,
    .m01_axi_rdata                  (masters[1].r_data)  ,
    .m01_axi_rresp                  (masters[1].r_resp)  ,
    .m01_axi_rlast                  (masters[1].r_last)  ,
    .m01_axi_ruser                  (masters[1].r_user)  ,
    .m01_axi_rvalid                 (masters[1].r_valid) ,
    .m01_axi_rready                 (masters[1].r_ready) ,

    .m02_axi_awid                   (masters[2].aw_id)   ,
    .m02_axi_awaddr                 (masters[2].aw_addr) ,
    .m02_axi_awlen                  (masters[2].aw_len)  ,
    .m02_axi_awsize                 (masters[2].aw_size) ,
    .m02_axi_awburst                (masters[2].aw_burst),
    .m02_axi_awlock                 (masters[2].aw_lock) ,
    .m02_axi_awcache                (masters[2].aw_cache),
    .m02_axi_awprot                 (masters[2].aw_prot) ,
    .m02_axi_awqos                  (masters[2].aw_qos)  ,
    .m02_axi_awuser                 (masters[2].aw_user) ,
    .m02_axi_awvalid                (masters[2].aw_valid),
    .m02_axi_awready                (masters[2].aw_ready),
    .m02_axi_wdata                  (masters[2].w_data)  ,
    .m02_axi_wstrb                  (masters[2].w_strb)  ,
    .m02_axi_wlast                  (masters[2].w_last)  ,
    .m02_axi_wuser                  (masters[2].w_user)  ,
    .m02_axi_wvalid                 (masters[2].w_valid) ,
    .m02_axi_wready                 (masters[2].w_ready) ,
    .m02_axi_bid                    (masters[2].b_id)    ,
    .m02_axi_bresp                  (masters[2].b_resp)  ,
    .m02_axi_buser                  (masters[2].b_user)  ,
    .m02_axi_bvalid                 (masters[2].b_valid) ,
    .m02_axi_bready                 (masters[2].b_ready) ,
    .m02_axi_arid                   (masters[2].ar_id)   ,
    .m02_axi_araddr                 (masters[2].ar_addr) ,
    .m02_axi_arlen                  (masters[2].ar_len)  ,
    .m02_axi_arsize                 (masters[2].ar_size) ,
    .m02_axi_arburst                (masters[2].ar_burst),
    .m02_axi_arlock                 (masters[2].ar_lock) ,
    .m02_axi_arcache                (masters[2].ar_cache),
    .m02_axi_arprot                 (masters[2].ar_prot) ,
    .m02_axi_arqos                  (masters[2].ar_qos)  ,
    .m02_axi_aruser                 (masters[2].ar_user) ,
    .m02_axi_arvalid                (masters[2].ar_valid),
    .m02_axi_arready                (masters[2].ar_ready),
    .m02_axi_rid                    (masters[2].r_id)    ,
    .m02_axi_rdata                  (masters[2].r_data)  ,
    .m02_axi_rresp                  (masters[2].r_resp)  ,
    .m02_axi_rlast                  (masters[2].r_last)  ,
    .m02_axi_ruser                  (masters[2].r_user)  ,
    .m02_axi_rvalid                 (masters[2].r_valid) ,
    .m02_axi_rready                 (masters[2].r_ready) ,

    .m03_axi_awid                   (masters[3].aw_id)   ,
    .m03_axi_awaddr                 (masters[3].aw_addr) ,
    .m03_axi_awlen                  (masters[3].aw_len)  ,
    .m03_axi_awsize                 (masters[3].aw_size) ,
    .m03_axi_awburst                (masters[3].aw_burst),
    .m03_axi_awlock                 (masters[3].aw_lock) ,
    .m03_axi_awcache                (masters[3].aw_cache),
    .m03_axi_awprot                 (masters[3].aw_prot) ,
    .m03_axi_awqos                  (masters[3].aw_qos)  ,
    .m03_axi_awuser                 (masters[3].aw_user) ,
    .m03_axi_awvalid                (masters[3].aw_valid),
    .m03_axi_awready                (masters[3].aw_ready),
    .m03_axi_wdata                  (masters[3].w_data)  ,
    .m03_axi_wstrb                  (masters[3].w_strb)  ,
    .m03_axi_wlast                  (masters[3].w_last)  ,
    .m03_axi_wuser                  (masters[3].w_user)  ,
    .m03_axi_wvalid                 (masters[3].w_valid) ,
    .m03_axi_wready                 (masters[3].w_ready) ,
    .m03_axi_bid                    (masters[3].b_id)    ,
    .m03_axi_bresp                  (masters[3].b_resp)  ,
    .m03_axi_buser                  (masters[3].b_user)  ,
    .m03_axi_bvalid                 (masters[3].b_valid) ,
    .m03_axi_bready                 (masters[3].b_ready) ,
    .m03_axi_arid                   (masters[3].ar_id)   ,
    .m03_axi_araddr                 (masters[3].ar_addr) ,
    .m03_axi_arlen                  (masters[3].ar_len)  ,
    .m03_axi_arsize                 (masters[3].ar_size) ,
    .m03_axi_arburst                (masters[3].ar_burst),
    .m03_axi_arlock                 (masters[3].ar_lock) ,
    .m03_axi_arcache                (masters[3].ar_cache),
    .m03_axi_arprot                 (masters[3].ar_prot) ,
    .m03_axi_arqos                  (masters[3].ar_qos)  ,
    .m03_axi_aruser                 (masters[3].ar_user) ,
    .m03_axi_arvalid                (masters[3].ar_valid),
    .m03_axi_arready                (masters[3].ar_ready),
    .m03_axi_rid                    (masters[3].r_id)    ,
    .m03_axi_rdata                  (masters[3].r_data)  ,
    .m03_axi_rresp                  (masters[3].r_resp)  ,
    .m03_axi_rlast                  (masters[3].r_last)  ,
    .m03_axi_ruser                  (masters[3].r_user)  ,
    .m03_axi_rvalid                 (masters[3].r_valid) ,
    .m03_axi_rready                 (masters[3].r_ready) ,

    .m04_axi_awid                   (masters[4].aw_id)   ,
    .m04_axi_awaddr                 (masters[4].aw_addr) ,
    .m04_axi_awlen                  (masters[4].aw_len)  ,
    .m04_axi_awsize                 (masters[4].aw_size) ,
    .m04_axi_awburst                (masters[4].aw_burst),
    .m04_axi_awlock                 (masters[4].aw_lock) ,
    .m04_axi_awcache                (masters[4].aw_cache),
    .m04_axi_awprot                 (masters[4].aw_prot) ,
    .m04_axi_awqos                  (masters[4].aw_qos)  ,
    .m04_axi_awuser                 (masters[4].aw_user) ,
    .m04_axi_awvalid                (masters[4].aw_valid),
    .m04_axi_awready                (masters[4].aw_ready),
    .m04_axi_wdata                  (masters[4].w_data)  ,
    .m04_axi_wstrb                  (masters[4].w_strb)  ,
    .m04_axi_wlast                  (masters[4].w_last)  ,
    .m04_axi_wuser                  (masters[4].w_user)  ,
    .m04_axi_wvalid                 (masters[4].w_valid) ,
    .m04_axi_wready                 (masters[4].w_ready) ,
    .m04_axi_bid                    (masters[4].b_id)    ,
    .m04_axi_bresp                  (masters[4].b_resp)  ,
    .m04_axi_buser                  (masters[4].b_user)  ,
    .m04_axi_bvalid                 (masters[4].b_valid) ,
    .m04_axi_bready                 (masters[4].b_ready) ,
    .m04_axi_arid                   (masters[4].ar_id)   ,
    .m04_axi_araddr                 (masters[4].ar_addr) ,
    .m04_axi_arlen                  (masters[4].ar_len)  ,
    .m04_axi_arsize                 (masters[4].ar_size) ,
    .m04_axi_arburst                (masters[4].ar_burst),
    .m04_axi_arlock                 (masters[4].ar_lock) ,
    .m04_axi_arcache                (masters[4].ar_cache),
    .m04_axi_arprot                 (masters[4].ar_prot) ,
    .m04_axi_arqos                  (masters[4].ar_qos)  ,
    .m04_axi_aruser                 (masters[4].ar_user) ,
    .m04_axi_arvalid                (masters[4].ar_valid),
    .m04_axi_arready                (masters[4].ar_ready),
    .m04_axi_rid                    (masters[4].r_id)    ,
    .m04_axi_rdata                  (masters[4].r_data)  ,
    .m04_axi_rresp                  (masters[4].r_resp)  ,
    .m04_axi_rlast                  (masters[4].r_last)  ,
    .m04_axi_ruser                  (masters[4].r_user)  ,
    .m04_axi_rvalid                 (masters[4].r_valid) ,
    .m04_axi_rready                 (masters[4].r_ready) 
);

//-------------------------------------------------------------------------------
// AXI2APB Wraps
//-------------------------------------------------------------------------------

axi2apb_wrap #(
    .AXI_ADDR_WIDTH   (32),
    .AXI_DATA_WIDTH   (32),
    .AXI_USER_WIDTH   ( 5),
    .AXI_ID_WIDTH     ( 8),
    .APB_ADDR_WIDTH   (32),
    .APB_DATA_WIDTH   (32)
) axi2apb_uart (
    .clk_i (clk),
    .rst_ni (rst_n),
    .test_en_i (1'b0),

    .axi_slave  (masters[1]),
    .apb_master (apb_masters[0])
);

axi2apb_wrap #(
    .AXI_ADDR_WIDTH   (32),
    .AXI_DATA_WIDTH   (32),
    .AXI_USER_WIDTH   ( 5),
    .AXI_ID_WIDTH     ( 8),
    .APB_ADDR_WIDTH   (32),
    .APB_DATA_WIDTH   (32)
) axi2apb_spi (
    .clk_i (clk),
    .rst_ni (rst_n),
    .test_en_i (1'b0),

    .axi_slave  (masters[2]),
    .apb_master (apb_masters[1])
);

axi2apb_wrap #(
    .AXI_ADDR_WIDTH   (32),
    .AXI_DATA_WIDTH   (32),
    .AXI_USER_WIDTH   ( 5),
    .AXI_ID_WIDTH     ( 8),
    .APB_ADDR_WIDTH   (32),
    .APB_DATA_WIDTH   (32)
) axi2apb_gpr (
    .clk_i (clk),
    .rst_ni (rst_n),
    .test_en_i (1'b0),

    .axi_slave  (masters[3]),
    .apb_master (apb_masters[2])
);

axi2apb_wrap #(
    .AXI_ADDR_WIDTH   (32),
    .AXI_DATA_WIDTH   (32),
    .AXI_USER_WIDTH   ( 5),
    .AXI_ID_WIDTH     ( 8),
    .APB_ADDR_WIDTH   (32),
    .APB_DATA_WIDTH   (32)
) axi2apb_timer (
    .clk_i (clk),
    .rst_ni (rst_n),
    .test_en_i (1'b0),

    .axi_slave  (masters[4]),
    .apb_master (apb_masters[3])
);

//-------------------------------------------------------------------------------
// UART
//-------------------------------------------------------------------------------

logic uart_rx;
logic uart_tx;

apb_uart #(
    .APB_ADDR_WIDTH  (12) 
) uart_i (
    .CLK (clk),
    .RSTN (~rst_n),
    .PADDR (apb_masters[0].paddr),
    .PWDATA (apb_masters[0].pwdata),
    .PWRITE (apb_masters[0].pwrite),
    .PSEL   (apb_masters[0].psel),
    .PENABLE(apb_masters[0].penable),
    .PRDATA (apb_masters[0].prdata),
    .PREADY (apb_masters[0].pready),
    .PSLVERR(apb_masters[0].pslverr),

    .rx_i   (uart_rx),
    .tx_o   (uart_tx),

    .event_o (irq_lines[0])
);

//-------------------------------------------------------------------------------
// SPI
//-------------------------------------------------------------------------------

// logic spi_clk; 
// logic spi_csn0;
// logic spi_csn1;
// logic spi_csn2;
// logic spi_csn3;
// logic spi_mode;
// logic spi_sdo0;
// logic spi_sdo1;
// logic spi_sdo2;
// logic spi_sdo3;
// logic spi_sdi0;
// logic spi_sdi1;
// logic spi_sdi2;
// logic spi_sdi3;

// apb_spi_master #(
//     .BUFFER_DEPTH    (10),
//     .APB_ADDR_WIDTH  (12) 
// ) spi_i (
//     .HCLK (clk),
//     .HRESETn (rst_n),
//     .PADDR (apb_masters[1].paddr),
//     .PWDATA (apb_masters[1].pwdata),
//     .PWRITE (apb_masters[1].pwrite),
//     .PSEL   (apb_masters[1].psel),
//     .PENABLE(apb_masters[1].penable),
//     .PRDATA (apb_masters[1].prdata),
//     .PREADY (apb_masters[1].pready),
//     .PSLVERR(apb_masters[1].pslverr),

//     .events_o (irq_lines[1]),

//     .spi_clk (spi_clk ),
//     .spi_csn0(spi_csn0),
//     .spi_csn1(spi_csn1),
//     .spi_csn2(spi_csn2),
//     .spi_csn3(spi_csn3),
//     .spi_mode(spi_mode),
//     .spi_sdo0(spi_sdo0),
//     .spi_sdo1(spi_sdo1),
//     .spi_sdo2(spi_sdo2),
//     .spi_sdo3(spi_sdo3),
//     .spi_sdi0(spi_sdi0),
//     .spi_sdi1(spi_sdi1),
//     .spi_sdi2(spi_sdi2),
//     .spi_sdi3(spi_sdi3)
// );

//-------------------------------------------------------------------------------
// I2C_1
//-------------------------------------------------------------------------------

logic                      scl_pad_i;
logic                      scl_pad_o;
logic                      scl_padoen_o;
logic                      sda_pad_i;
logic                      sda_pad_o;
logic                      sda_padoen_o;

tri1          scl_io;
tri1          sda_io;

apb_i2c i2c_i_1(
    .HCLK (clk),
    .HRESETn (rst_n),
    .PADDR (apb_masters[1].paddr),
    .PWDATA (apb_masters[1].pwdata),
    .PWRITE (apb_masters[1].pwrite),
    .PSEL   (apb_masters[1].psel),
    .PENABLE(apb_masters[1].penable),
    .PRDATA (apb_masters[1].prdata),
    .PREADY (apb_masters[1].pready),
    .PSLVERR(apb_masters[1].pslverr),
    .interrupt_o(irq_lines[1]),
    .scl_pad_i(scl_pad_i),
    .scl_pad_o(scl_pad_o),
    .scl_padoen_o(scl_padoen_o),
    .sda_pad_i(sda_pad_i),
    .sda_pad_o(sda_pad_o),
    .sda_padoen_o(sda_padoen_o)
);

 i2c_buf i2c_buf_i_1
  (
    .scl_io       ( scl_io       ),
    .sda_io       ( sda_io       ),
    .scl_pad_i    ( scl_pad_i    ),
    .scl_pad_o    ( scl_pad_o    ),
    .scl_padoen_o ( scl_padoen_o ),
    .sda_pad_i    ( sda_pad_i    ),
    .sda_pad_o    ( sda_pad_o    ),
    .sda_padoen_o ( sda_padoen_o )
  );

//   i2c_eeprom_model i2c_eeprom_model_i
//   (
//     .scl_io ( scl_io  ),
//     .sda_io ( sda_io  ),
//     .rst_ni ( rst_n )
//   );

logic                      scl_2_pad_i;
logic                      scl_2_pad_o;
logic                      scl_2_padoen_o;
logic                      sda_2_pad_i;
logic                      sda_2_pad_o;
logic                      sda_2_padoen_o;

//  i2c_buf i2c_buf_i_2
//   (
//     .scl_io       ( scl_io       ),
//     .sda_io       ( sda_io       ),
//     .scl_pad_i    ( scl_2_pad_i    ),
//     .scl_pad_o    ( scl_2_pad_o    ),
//     .scl_padoen_o ( scl_2_padoen_o ),
//     .sda_pad_i    ( sda_2_pad_i    ),
//     .sda_pad_o    ( sda_2_pad_o    ),
//     .sda_padoen_o ( sda_2_padoen_o )
//   );

// apb_i2c i2c_i_2(
//     .HCLK (clk),
//     .HRESETn (rst_n),
//     .PADDR (apb_masters[2].paddr),
//     .PWDATA (apb_masters[2].pwdata),
//     .PWRITE (apb_masters[2].pwrite),
//     .PSEL   (apb_masters[2].psel),
//     .PENABLE(apb_masters[2].penable),
//     .PRDATA (apb_masters[2].prdata),
//     .PREADY (apb_masters[2].pready),
//     .PSLVERR(apb_masters[2].pslverr),
//     .interrupt_o(irq_lines[2]),
//     .scl_pad_i(scl_2_pad_i),
//     .scl_pad_o(scl_2_pad_o),
//     .scl_padoen_o(scl_2_padoen_o),
//     .sda_pad_i(sda_2_pad_i),
//     .sda_pad_o(sda_2_pad_o),
//     .sda_padoen_o(sda_2_padoen_o)
// );

i2c_slave i2c_slave_i (
    .clk (clk),
    .rst_n (rst_n),
    .scl_io ( scl_io       ),
    .sda_io ( sda_io       )
);

//-------------------------------------------------------------------------------
// GPR
//-------------------------------------------------------------------------------

// regs gpr_i (
//     .clk (clk),
//     .rst (~rst_n),
//     .paddr (apb_masters[2].paddr),
//     .pwdata (apb_masters[2].pwdata),
//     .pwrite (apb_masters[2].pwrite),
//     .psel   (apb_masters[2].psel),
//     .penable(apb_masters[2].penable),
//     .prdata (apb_masters[2].prdata),
//     .pready (apb_masters[2].pready),
//     .pslverr(apb_masters[2].pslverr)
// );

//-------------------------------------------------------------------------------
// TIMER
//-------------------------------------------------------------------------------

apb_timer #(
    .TIMER_CNT    (2),
    .APB_ADDR_WIDTH  (12) 
) timer_i (
    .HCLK (clk),
    .HRESETn (rst_n),
    .PADDR (apb_masters[3].paddr),
    .PWDATA (apb_masters[3].pwdata),
    .PWRITE (apb_masters[3].pwrite),
    .PSEL   (apb_masters[3].psel),
    .PENABLE(apb_masters[3].penable),
    .PRDATA (apb_masters[3].prdata),
    .PREADY (apb_masters[3].pready),
    .PSLVERR(apb_masters[3].pslverr),

    .irq_o (irq_lines[3])
);

endmodule