`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 03/21/2023 11:49:47 AM
// Design Name:
// Module Name: caliptra_package_top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Vivado does not support using a SystemVerilog as the top level file in an package.
//
//////////////////////////////////////////////////////////////////////////////////

`default_nettype wire

`define CALIPTRA_APB_ADDR_WIDTH      32 // bit-width APB address
`define CALIPTRA_APB_DATA_WIDTH      32 // bit-width APB data

module caliptra_package_top (
    input wire core_clk,

    // Caliptra AXI Interface
    input  wire [31:0] S_AXI_CALIPTRA_AWADDR,
    input  wire [1:0] S_AXI_CALIPTRA_AWBURST,
    input  wire [2:0] S_AXI_CALIPTRA_AWSIZE,
    input  wire [7:0] S_AXI_CALIPTRA_AWLEN,
    input  wire [31:0] S_AXI_CALIPTRA_AWUSER,
    input  wire [15:0] S_AXI_CALIPTRA_AWID,
    input  wire S_AXI_CALIPTRA_AWLOCK,
    input  wire S_AXI_CALIPTRA_AWVALID,
    output wire S_AXI_CALIPTRA_AWREADY,
    // W
    input  wire [31:0] S_AXI_CALIPTRA_WDATA,
    input  wire [3:0] S_AXI_CALIPTRA_WSTRB,
    input  wire S_AXI_CALIPTRA_WVALID,
    output wire S_AXI_CALIPTRA_WREADY,
    input  wire S_AXI_CALIPTRA_WLAST,
    // B
    output wire [1:0] S_AXI_CALIPTRA_BRESP,
    output wire [15:0] S_AXI_CALIPTRA_BID,
    output wire S_AXI_CALIPTRA_BVALID,
    input  wire S_AXI_CALIPTRA_BREADY,
    // AR
    input  wire [31:0] S_AXI_CALIPTRA_ARADDR,
    input  wire [1:0] S_AXI_CALIPTRA_ARBURST,
    input  wire [2:0] S_AXI_CALIPTRA_ARSIZE,
    input  wire [7:0] S_AXI_CALIPTRA_ARLEN,
    input  wire [31:0] S_AXI_CALIPTRA_ARUSER,
    input  wire [15:0] S_AXI_CALIPTRA_ARID,
    input  wire S_AXI_CALIPTRA_ARLOCK,
    input  wire S_AXI_CALIPTRA_ARVALID,
    output wire S_AXI_CALIPTRA_ARREADY,
    // R
    output wire [31:0] S_AXI_CALIPTRA_RDATA,
    output wire [3:0] S_AXI_CALIPTRA_RRESP,
    output wire [15:0] S_AXI_CALIPTRA_RID,
    output wire S_AXI_CALIPTRA_RLAST,
    output wire S_AXI_CALIPTRA_RVALID,
    input  wire S_AXI_CALIPTRA_RREADY,

    // ROM AXI Interface
    input  wire                       axi_bram_clk,
    input  wire                       axi_bram_en,
    input  wire [3:0]                 axi_bram_we,
    input  wire [15:0]                axi_bram_addr,
    input  wire [31:0]                axi_bram_din,
    output wire [31:0]                axi_bram_dout,
    input  wire                       axi_bram_rst,

    // JTAG Interface
    input wire [4:0]                  jtag_in,     // JTAG input signals concatenated
    output wire [4:0]                 jtag_out,    // JTAG tdo

    // FPGA Realtime register AXI Interface
    input	wire                      S_AXI_ARESETN,
    input	wire                      S_AXI_AWVALID,
    output	wire                      S_AXI_AWREADY,
    input	wire [31:0]               S_AXI_AWADDR,
    input	wire [2:0]                S_AXI_AWPROT,
    input	wire                      S_AXI_WVALID,
    output	wire                      S_AXI_WREADY,
    input	wire [31:0]               S_AXI_WDATA,
    input	wire [3:0]                S_AXI_WSTRB,
    output	wire                      S_AXI_BVALID,
    input	wire                      S_AXI_BREADY,
    output	wire [1:0]                S_AXI_BRESP,
    input	wire                      S_AXI_ARVALID,
    output	wire                      S_AXI_ARREADY,
    input	wire [31:0]               S_AXI_ARADDR,
    input	wire [2:0]                S_AXI_ARPROT,
    output	wire                      S_AXI_RVALID,
    input	wire                      S_AXI_RREADY,
    output	wire [31:0]               S_AXI_RDATA,
    output	wire [1:0]                S_AXI_RRESP
    );

caliptra_wrapper_top cptra_wrapper (
    .core_clk(core_clk),

    // Caliptra AXI Interface
    .S_AXI_CALIPTRA_AWADDR(S_AXI_CALIPTRA_AWADDR),
    .S_AXI_CALIPTRA_AWBURST(S_AXI_CALIPTRA_AWBURST),
    .S_AXI_CALIPTRA_AWSIZE(S_AXI_CALIPTRA_AWSIZE),
    .S_AXI_CALIPTRA_AWLEN(S_AXI_CALIPTRA_AWLEN),
    .S_AXI_CALIPTRA_AWUSER(S_AXI_CALIPTRA_AWUSER),
    .S_AXI_CALIPTRA_AWID(S_AXI_CALIPTRA_AWID),
    .S_AXI_CALIPTRA_AWLOCK(S_AXI_CALIPTRA_AWLOCK),
    .S_AXI_CALIPTRA_AWVALID(S_AXI_CALIPTRA_AWVALID),
    .S_AXI_CALIPTRA_AWREADY(S_AXI_CALIPTRA_AWREADY),
    .S_AXI_CALIPTRA_WDATA(S_AXI_CALIPTRA_WDATA),
    .S_AXI_CALIPTRA_WSTRB(S_AXI_CALIPTRA_WSTRB),
    .S_AXI_CALIPTRA_WVALID(S_AXI_CALIPTRA_WVALID),
    .S_AXI_CALIPTRA_WREADY(S_AXI_CALIPTRA_WREADY),
    .S_AXI_CALIPTRA_WLAST(S_AXI_CALIPTRA_WLAST),
    .S_AXI_CALIPTRA_BRESP(S_AXI_CALIPTRA_BRESP),
    .S_AXI_CALIPTRA_BID(S_AXI_CALIPTRA_BID),
    .S_AXI_CALIPTRA_BVALID(S_AXI_CALIPTRA_BVALID),
    .S_AXI_CALIPTRA_BREADY(S_AXI_CALIPTRA_BREADY),
    .S_AXI_CALIPTRA_ARADDR(S_AXI_CALIPTRA_ARADDR),
    .S_AXI_CALIPTRA_ARBURST(S_AXI_CALIPTRA_ARBURST),
    .S_AXI_CALIPTRA_ARSIZE(S_AXI_CALIPTRA_ARSIZE),
    .S_AXI_CALIPTRA_ARLEN(S_AXI_CALIPTRA_ARLEN),
    .S_AXI_CALIPTRA_ARUSER(S_AXI_CALIPTRA_ARUSER),
    .S_AXI_CALIPTRA_ARID(S_AXI_CALIPTRA_ARID),
    .S_AXI_CALIPTRA_ARLOCK(S_AXI_CALIPTRA_ARLOCK),
    .S_AXI_CALIPTRA_ARVALID(S_AXI_CALIPTRA_ARVALID),
    .S_AXI_CALIPTRA_ARREADY(S_AXI_CALIPTRA_ARREADY),
    .S_AXI_CALIPTRA_RDATA(S_AXI_CALIPTRA_RDATA),
    .S_AXI_CALIPTRA_RRESP(S_AXI_CALIPTRA_RRESP),
    .S_AXI_CALIPTRA_RID(S_AXI_CALIPTRA_RID),
    .S_AXI_CALIPTRA_RLAST(S_AXI_CALIPTRA_RLAST),
    .S_AXI_CALIPTRA_RVALID(S_AXI_CALIPTRA_RVALID),
    .S_AXI_CALIPTRA_RREADY(S_AXI_CALIPTRA_RREADY),

    // SOC access to program ROM
    .axi_bram_clk(axi_bram_clk),
    .axi_bram_en(axi_bram_en),
    .axi_bram_we(axi_bram_we),
    .axi_bram_addr(axi_bram_addr[15:2]),
    .axi_bram_wrdata(axi_bram_din),
    .axi_bram_rddata(axi_bram_dout),
    .axi_bram_rst(axi_bram_rst),

    // EL2 JTAG interface
    .jtag_tck(jtag_in[0]),
    .jtag_tdi(jtag_in[1]),
    .jtag_tms(jtag_in[2]),
    .jtag_trst_n(jtag_in[3]),
    .jtag_tdo(jtag_out[4]),

    // FPGA Realtime register AXI Interface
    .S_AXI_ARESETN(S_AXI_ARESETN),
    .S_AXI_AWVALID(S_AXI_AWVALID),
    .S_AXI_AWREADY(S_AXI_AWREADY),
    .S_AXI_AWADDR(S_AXI_AWADDR),
    .S_AXI_AWPROT(S_AXI_AWPROT),
    .S_AXI_WVALID(S_AXI_WVALID),
    .S_AXI_WREADY(S_AXI_WREADY),
    .S_AXI_WDATA(S_AXI_WDATA),
    .S_AXI_WSTRB(S_AXI_WSTRB),
    .S_AXI_BVALID(S_AXI_BVALID),
    .S_AXI_BREADY(S_AXI_BREADY),
    .S_AXI_BRESP(S_AXI_BRESP),
    .S_AXI_ARVALID(S_AXI_ARVALID),
    .S_AXI_ARREADY(S_AXI_ARREADY),
    .S_AXI_ARADDR(S_AXI_ARADDR),
    .S_AXI_ARPROT(S_AXI_ARPROT),
    .S_AXI_RVALID(S_AXI_RVALID),
    .S_AXI_RREADY(S_AXI_RREADY),
    .S_AXI_RDATA(S_AXI_RDATA),
    .S_AXI_RRESP(S_AXI_RRESP)
);

endmodule
