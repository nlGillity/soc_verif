// Created with Corsair v1.0.4

module regs #(
    parameter ADDR_W = 32,
    parameter DATA_W = 32,
    parameter STRB_W = DATA_W / 8
)(
    // System
    input clk,
    input rst,
    // GPR0.value

    // GPR1.value

    // GPR2.value

    // GPR3.value

    // GPR4.value

    // GPR5.value

    // GPR6.value

    // GPR7.value

    // APB
    input               psel,
    input  [ADDR_W-1:0] paddr,
    input               penable,
    input               pwrite,
    input  [DATA_W-1:0] pwdata,
    input  [STRB_W-1:0] pstrb,
    output [DATA_W-1:0] prdata,
    output              pready,
    output              pslverr
);
wire              wready;
wire [ADDR_W-1:0] waddr;
wire [DATA_W-1:0] wdata;
wire              wen;
wire [STRB_W-1:0] wstrb;
wire [DATA_W-1:0] rdata;
wire              rvalid;
wire [ADDR_W-1:0] raddr;
wire              ren;
// APB interface
assign prdata  = rdata;
assign pslverr = 1'b0; // always OKAY
assign pready  = wen             ? wready :
                 (ren & penable) ? rvalid : 1'b1;

// Local Bus interface
assign waddr = paddr & 8'hFF;
assign wdata = pwdata;
assign wstrb = 4'b1111;
assign wen   = psel & penable & pwrite;

assign raddr = paddr & 8'hFF;
assign ren   = psel & penable & (~pwrite);

//------------------------------------------------------------------------------
// CSR:
// [0x0] - GPR0 - GPR0 register
//------------------------------------------------------------------------------
wire [31:0] csr_gpr0_rdata;

wire csr_gpr0_wen;
assign csr_gpr0_wen = wen && (waddr == 32'h0);

wire csr_gpr0_ren;
assign csr_gpr0_ren = ren && (raddr == 32'h0);
reg csr_gpr0_ren_ff;
always @(posedge clk) begin
    if (rst) begin
        csr_gpr0_ren_ff <= 1'b0;
    end else begin
        csr_gpr0_ren_ff <= csr_gpr0_ren;
    end
end
//---------------------
// Bit field:
// GPR0[31:0] - value - register value
// access: rw, hardware: n
//---------------------
reg [31:0] csr_gpr0_value_ff;

assign csr_gpr0_rdata[31:0] = csr_gpr0_value_ff;


always @(posedge clk) begin
    if (rst) begin
        csr_gpr0_value_ff <= 32'h0;
    end else  begin
     if (csr_gpr0_wen) begin
            if (wstrb[0]) begin
                csr_gpr0_value_ff[7:0] <= wdata[7:0];
            end
            if (wstrb[1]) begin
                csr_gpr0_value_ff[15:8] <= wdata[15:8];
            end
            if (wstrb[2]) begin
                csr_gpr0_value_ff[23:16] <= wdata[23:16];
            end
            if (wstrb[3]) begin
                csr_gpr0_value_ff[31:24] <= wdata[31:24];
            end
        end else begin
            csr_gpr0_value_ff <= csr_gpr0_value_ff;
        end
    end
end


//------------------------------------------------------------------------------
// CSR:
// [0x4] - GPR1 - GPR1 register
//------------------------------------------------------------------------------
wire [31:0] csr_gpr1_rdata;

wire csr_gpr1_wen;
assign csr_gpr1_wen = wen && (waddr == 32'h4);

wire csr_gpr1_ren;
assign csr_gpr1_ren = ren && (raddr == 32'h4);
reg csr_gpr1_ren_ff;
always @(posedge clk) begin
    if (rst) begin
        csr_gpr1_ren_ff <= 1'b0;
    end else begin
        csr_gpr1_ren_ff <= csr_gpr1_ren;
    end
end
//---------------------
// Bit field:
// GPR1[31:0] - value - register value
// access: rw, hardware: n
//---------------------
reg [31:0] csr_gpr1_value_ff;

assign csr_gpr1_rdata[31:0] = csr_gpr1_value_ff;


always @(posedge clk) begin
    if (rst) begin
        csr_gpr1_value_ff <= 32'h0;
    end else  begin
     if (csr_gpr1_wen) begin
            if (wstrb[0]) begin
                csr_gpr1_value_ff[7:0] <= wdata[7:0];
            end
            if (wstrb[1]) begin
                csr_gpr1_value_ff[15:8] <= wdata[15:8];
            end
            if (wstrb[2]) begin
                csr_gpr1_value_ff[23:16] <= wdata[23:16];
            end
            if (wstrb[3]) begin
                csr_gpr1_value_ff[31:24] <= wdata[31:24];
            end
        end else begin
            csr_gpr1_value_ff <= csr_gpr1_value_ff;
        end
    end
end


//------------------------------------------------------------------------------
// CSR:
// [0x8] - GPR2 - GPR2 register
//------------------------------------------------------------------------------
wire [31:0] csr_gpr2_rdata;

wire csr_gpr2_wen;
assign csr_gpr2_wen = wen && (waddr == 32'h8);

wire csr_gpr2_ren;
assign csr_gpr2_ren = ren && (raddr == 32'h8);
reg csr_gpr2_ren_ff;
always @(posedge clk) begin
    if (rst) begin
        csr_gpr2_ren_ff <= 1'b0;
    end else begin
        csr_gpr2_ren_ff <= csr_gpr2_ren;
    end
end
//---------------------
// Bit field:
// GPR2[31:0] - value - register value
// access: rw, hardware: n
//---------------------
reg [31:0] csr_gpr2_value_ff;

assign csr_gpr2_rdata[31:0] = csr_gpr2_value_ff;


always @(posedge clk) begin
    if (rst) begin
        csr_gpr2_value_ff <= 32'h0;
    end else  begin
     if (csr_gpr2_wen) begin
            if (wstrb[0]) begin
                csr_gpr2_value_ff[7:0] <= wdata[7:0];
            end
            if (wstrb[1]) begin
                csr_gpr2_value_ff[15:8] <= wdata[15:8];
            end
            if (wstrb[2]) begin
                csr_gpr2_value_ff[23:16] <= wdata[23:16];
            end
            if (wstrb[3]) begin
                csr_gpr2_value_ff[31:24] <= wdata[31:24];
            end
        end else begin
            csr_gpr2_value_ff <= csr_gpr2_value_ff;
        end
    end
end


//------------------------------------------------------------------------------
// CSR:
// [0xc] - GPR3 - GPR3 register
//------------------------------------------------------------------------------
wire [31:0] csr_gpr3_rdata;

wire csr_gpr3_wen;
assign csr_gpr3_wen = wen && (waddr == 32'hc);

wire csr_gpr3_ren;
assign csr_gpr3_ren = ren && (raddr == 32'hc);
reg csr_gpr3_ren_ff;
always @(posedge clk) begin
    if (rst) begin
        csr_gpr3_ren_ff <= 1'b0;
    end else begin
        csr_gpr3_ren_ff <= csr_gpr3_ren;
    end
end
//---------------------
// Bit field:
// GPR3[31:0] - value - register value
// access: rw, hardware: n
//---------------------
reg [31:0] csr_gpr3_value_ff;

assign csr_gpr3_rdata[31:0] = csr_gpr3_value_ff;


always @(posedge clk) begin
    if (rst) begin
        csr_gpr3_value_ff <= 32'h0;
    end else  begin
     if (csr_gpr3_wen) begin
            if (wstrb[0]) begin
                csr_gpr3_value_ff[7:0] <= wdata[7:0];
            end
            if (wstrb[1]) begin
                csr_gpr3_value_ff[15:8] <= wdata[15:8];
            end
            if (wstrb[2]) begin
                csr_gpr3_value_ff[23:16] <= wdata[23:16];
            end
            if (wstrb[3]) begin
                csr_gpr3_value_ff[31:24] <= wdata[31:24];
            end
        end else begin
            csr_gpr3_value_ff <= csr_gpr3_value_ff;
        end
    end
end


//------------------------------------------------------------------------------
// CSR:
// [0x10] - GPR4 - GPR4 register
//------------------------------------------------------------------------------
wire [31:0] csr_gpr4_rdata;

wire csr_gpr4_wen;
assign csr_gpr4_wen = wen && (waddr == 32'h10);

wire csr_gpr4_ren;
assign csr_gpr4_ren = ren && (raddr == 32'h10);
reg csr_gpr4_ren_ff;
always @(posedge clk) begin
    if (rst) begin
        csr_gpr4_ren_ff <= 1'b0;
    end else begin
        csr_gpr4_ren_ff <= csr_gpr4_ren;
    end
end
//---------------------
// Bit field:
// GPR4[31:0] - value - register value
// access: rw, hardware: n
//---------------------
reg [31:0] csr_gpr4_value_ff;

assign csr_gpr4_rdata[31:0] = csr_gpr4_value_ff;


always @(posedge clk) begin
    if (rst) begin
        csr_gpr4_value_ff <= 32'h0;
    end else  begin
     if (csr_gpr4_wen) begin
            if (wstrb[0]) begin
                csr_gpr4_value_ff[7:0] <= wdata[7:0];
            end
            if (wstrb[1]) begin
                csr_gpr4_value_ff[15:8] <= wdata[15:8];
            end
            if (wstrb[2]) begin
                csr_gpr4_value_ff[23:16] <= wdata[23:16];
            end
            if (wstrb[3]) begin
                csr_gpr4_value_ff[31:24] <= wdata[31:24];
            end
        end else begin
            csr_gpr4_value_ff <= csr_gpr4_value_ff;
        end
    end
end


//------------------------------------------------------------------------------
// CSR:
// [0x14] - GPR5 - GPR5 register
//------------------------------------------------------------------------------
wire [31:0] csr_gpr5_rdata;

wire csr_gpr5_wen;
assign csr_gpr5_wen = wen && (waddr == 32'h14);

wire csr_gpr5_ren;
assign csr_gpr5_ren = ren && (raddr == 32'h14);
reg csr_gpr5_ren_ff;
always @(posedge clk) begin
    if (rst) begin
        csr_gpr5_ren_ff <= 1'b0;
    end else begin
        csr_gpr5_ren_ff <= csr_gpr5_ren;
    end
end
//---------------------
// Bit field:
// GPR5[31:0] - value - register value
// access: rw, hardware: n
//---------------------
reg [31:0] csr_gpr5_value_ff;

assign csr_gpr5_rdata[31:0] = csr_gpr5_value_ff;


always @(posedge clk) begin
    if (rst) begin
        csr_gpr5_value_ff <= 32'h0;
    end else  begin
     if (csr_gpr5_wen) begin
            if (wstrb[0]) begin
                csr_gpr5_value_ff[7:0] <= wdata[7:0];
            end
            if (wstrb[1]) begin
                csr_gpr5_value_ff[15:8] <= wdata[15:8];
            end
            if (wstrb[2]) begin
                csr_gpr5_value_ff[23:16] <= wdata[23:16];
            end
            if (wstrb[3]) begin
                csr_gpr5_value_ff[31:24] <= wdata[31:24];
            end
        end else begin
            csr_gpr5_value_ff <= csr_gpr5_value_ff;
        end
    end
end


//------------------------------------------------------------------------------
// CSR:
// [0x18] - GPR6 - GPR6 register
//------------------------------------------------------------------------------
wire [31:0] csr_gpr6_rdata;


wire csr_gpr6_ren;
assign csr_gpr6_ren = ren && (raddr == 32'h18);
reg csr_gpr6_ren_ff;
always @(posedge clk) begin
    if (rst) begin
        csr_gpr6_ren_ff <= 1'b0;
    end else begin
        csr_gpr6_ren_ff <= csr_gpr6_ren;
    end
end
//---------------------
// Bit field:
// GPR6[31:0] - value - register value
// access: ro, hardware: n
//---------------------
reg [31:0] csr_gpr6_value_ff;

assign csr_gpr6_rdata[31:0] = csr_gpr6_value_ff;


always @(posedge clk) begin
    if (rst) begin
        csr_gpr6_value_ff <= 32'hdeadbeef;
    end else  begin
      begin
            csr_gpr6_value_ff <= csr_gpr6_value_ff;
        end
    end
end


//------------------------------------------------------------------------------
// CSR:
// [0x1c] - GPR7 - GPR7 register
//------------------------------------------------------------------------------
wire [31:0] csr_gpr7_rdata;


wire csr_gpr7_ren;
assign csr_gpr7_ren = ren && (raddr == 32'h1c);
reg csr_gpr7_ren_ff;
always @(posedge clk) begin
    if (rst) begin
        csr_gpr7_ren_ff <= 1'b0;
    end else begin
        csr_gpr7_ren_ff <= csr_gpr7_ren;
    end
end
//---------------------
// Bit field:
// GPR7[31:0] - value - register value
// access: ro, hardware: n
//---------------------
reg [31:0] csr_gpr7_value_ff;

assign csr_gpr7_rdata[31:0] = csr_gpr7_value_ff;


always @(posedge clk) begin
    if (rst) begin
        csr_gpr7_value_ff <= 32'hffffffff;
    end else  begin
      begin
            csr_gpr7_value_ff <= csr_gpr7_value_ff;
        end
    end
end


//------------------------------------------------------------------------------
// Write ready
//------------------------------------------------------------------------------
assign wready = 1'b1;

//------------------------------------------------------------------------------
// Read address decoder
//------------------------------------------------------------------------------
reg [31:0] rdata_ff;
always @(posedge clk) begin
    if (rst) begin
        rdata_ff <= 32'h0;
    end else if (ren) begin
        case (raddr)
            32'h0: rdata_ff <= csr_gpr0_rdata;
            32'h4: rdata_ff <= csr_gpr1_rdata;
            32'h8: rdata_ff <= csr_gpr2_rdata;
            32'hc: rdata_ff <= csr_gpr3_rdata;
            32'h10: rdata_ff <= csr_gpr4_rdata;
            32'h14: rdata_ff <= csr_gpr5_rdata;
            32'h18: rdata_ff <= csr_gpr6_rdata;
            32'h1c: rdata_ff <= csr_gpr7_rdata;
            default: rdata_ff <= 32'h0;
        endcase
    end else begin
        rdata_ff <= 32'h0;
    end
end
assign rdata = rdata_ff;

//------------------------------------------------------------------------------
// Read data valid
//------------------------------------------------------------------------------
reg rvalid_ff;
always @(posedge clk) begin
    if (rst) begin
        rvalid_ff <= 1'b0;
    end else if (ren && rvalid) begin
        rvalid_ff <= 1'b0;
    end else if (ren) begin
        rvalid_ff <= 1'b1;
    end
end

assign rvalid = rvalid_ff;

endmodule