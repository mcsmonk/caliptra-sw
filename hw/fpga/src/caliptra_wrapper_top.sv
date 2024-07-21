// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
`default_nettype wire

`include "common_defines.sv"
`include "config_defines.svh"
`include "caliptra_reg_defines.svh"
`include "caliptra_macros.svh"

import caliptra_fpga_realtime_regs_pkg::*;
import soc_ifc_pkg::*;

module caliptra_wrapper_top (
    input bit core_clk,
    
    //// Caliptra APB Interface
    //input  wire [`CALIPTRA_APB_ADDR_WIDTH-1:0] PADDR,
    //input  wire                       PENABLE,
    //input  wire [2:0]                 PPROT,
    //output wire [`CALIPTRA_APB_DATA_WIDTH-1:0] PRDATA,
    //output wire                       PREADY,
    //input  wire                       PSEL,
    //output wire                       PSLVERR,
    //input  wire [`CALIPTRA_APB_DATA_WIDTH-1:0] PWDATA,
    //input  wire                       PWRITE,
    // Caliptra AXI Interface
    input  wire [31:0/*`CALIPTRA_SLAVE_ADDR_WIDTH(`CALIPTRA_SLAVE_SEL_SOC_IFC)-1:0*/] S_AXI_CALIPTRA_AWADDR,
    input  wire [1:0] S_AXI_CALIPTRA_AWBURST,
    input  wire [2:0] S_AXI_CALIPTRA_AWSIZE,
    input  wire [7:0] S_AXI_CALIPTRA_AWLEN,
    input  wire [31:0/*`CALIPTRA_AXI_USER_WIDTH-1:0*/] S_AXI_CALIPTRA_AWUSER,
    input  wire [4:0/*`CALIPTRA_AXI_ID_WIDTH-1:0*/] S_AXI_CALIPTRA_AWID,
    input  wire S_AXI_CALIPTRA_AWLOCK,
    input  wire S_AXI_CALIPTRA_AWVALID,
    output wire S_AXI_CALIPTRA_AWREADY,
    // W
    input  wire [31:0/*`CALIPTRA_AXI_DATA_WIDTH-1:0*/] S_AXI_CALIPTRA_WDATA,
    input  wire [3:0/*`CALIPTRA_AXI_DATA_WIDTH/8:0*/] S_AXI_CALIPTRA_WSTRB,
    input  wire S_AXI_CALIPTRA_WVALID,
    output wire S_AXI_CALIPTRA_WREADY,
    input  wire S_AXI_CALIPTRA_WLAST,
    // B
    output wire [1:0] S_AXI_CALIPTRA_BRESP,
    output wire [4:0/*`CALIPTRA_AXI_ID_WIDTH-1:0*/] S_AXI_CALIPTRA_BID,
    output wire S_AXI_CALIPTRA_BVALID,
    input  wire S_AXI_CALIPTRA_BREADY,
    // AR
    input  wire [31:0/*`CALIPTRA_SLAVE_ADDR_WIDTH(`CALIPTRA_SLAVE_SEL_SOC_IFC)-1:0*/] S_AXI_CALIPTRA_ARADDR,
    input  wire [1:0] S_AXI_CALIPTRA_ARBURST,
    input  wire [2:0] S_AXI_CALIPTRA_ARSIZE,
    input  wire [7:0] S_AXI_CALIPTRA_ARLEN,
    input  wire [31:0/*`CALIPTRA_AXI_USER_WIDTH-1:0*/] S_AXI_CALIPTRA_ARUSER,
    input  wire [4:0/*`CALIPTRA_AXI_ID_WIDTH-1:0*/] S_AXI_CALIPTRA_ARID,
    input  wire S_AXI_CALIPTRA_ARLOCK,
    input  wire S_AXI_CALIPTRA_ARVALID,
    output wire S_AXI_CALIPTRA_ARREADY,
    // R
    output wire [31:0/*`CALIPTRA_AXI_DATA_WIDTH-1:0*/] S_AXI_CALIPTRA_RDATA,
    output wire [3:0/*`CALIPTRA_AXI_DATA_WIDTH/8:0*/] S_AXI_CALIPTRA_RRESP,
    output wire [4:0] S_AXI_CALIPTRA_RID,
    output wire S_AXI_CALIPTRA_RLAST,
    output wire S_AXI_CALIPTRA_RVALID,
    input  wire S_AXI_CALIPTRA_RREADY,

    // ROM AXI Interface
    input  logic axi_bram_clk,
    input  logic axi_bram_en,
    input  logic [3:0] axi_bram_we,
    input  logic [13:0] axi_bram_addr,
    input  logic [31:0] axi_bram_wrdata,
    output logic [31:0] axi_bram_rddata,
    input  logic axi_bram_rst,

    // JTAG Interface
    input logic                       jtag_tck,    // JTAG clk
    input logic                       jtag_tms,    // JTAG tms
    input logic                       jtag_tdi,    // JTAG tdi
    input logic                       jtag_trst_n, // JTAG reset
    output logic                      jtag_tdo,    // JTAG tdo

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

    import soc_ifc_pkg::*;

    logic                       BootFSM_BrkPoint;

    logic mbox_sram_cs;
    logic mbox_sram_we;
    logic [14:0] mbox_sram_addr;
    logic [MBOX_DATA_AND_ECC_W-1:0] mbox_sram_wdata;
    logic [MBOX_DATA_AND_ECC_W-1:0] mbox_sram_rdata;

    logic imem_cs;
    logic [`CALIPTRA_IMEM_ADDR_WIDTH-1:0] imem_addr;
    logic [`CALIPTRA_IMEM_DATA_WIDTH-1:0] imem_rdata;

    axi_if #(
        .AW(`CALIPTRA_SLAVE_ADDR_WIDTH(`CALIPTRA_SLAVE_SEL_SOC_IFC)),
        .DW(`CALIPTRA_AXI_DATA_WIDTH),
        .IW(`CALIPTRA_AXI_ID_WIDTH),
        .UW(`CALIPTRA_AXI_USER_WIDTH)
    ) s_axi (.clk(core_clk), .rst_n(hwif_out.interface_regs.control.cptra_rst_b.value));

    // AW
    assign s_axi.w_sub.awaddr   = S_AXI_CALIPTRA_AWADDR;
    assign s_axi.w_sub.awburst  = S_AXI_CALIPTRA_AWBURST;
    assign s_axi.w_sub.awsize   = S_AXI_CALIPTRA_AWSIZE;
    assign s_axi.w_sub.awlen    = S_AXI_CALIPTRA_AWLEN;
    assign s_axi.w_sub.awuser   = S_AXI_CALIPTRA_AWUSER;
    assign s_axi.w_sub.awid     = S_AXI_CALIPTRA_AWID;
    assign s_axi.w_sub.awlock   = S_AXI_CALIPTRA_AWLOCK;
    assign s_axi.w_sub.awvalid  = S_AXI_CALIPTRA_AWVALID;
    assign S_AXI_CALIPTRA_AWREADY = s_axi.w_sub.awready;
    // W
    assign s_axi.w_sub.wdata    = S_AXI_CALIPTRA_WDATA;
    assign s_axi.w_sub.wstrb    = S_AXI_CALIPTRA_WSTRB;
    assign s_axi.w_sub.wvalid   = S_AXI_CALIPTRA_WVALID;
    assign S_AXI_CALIPTRA_WREADY = s_axi.w_sub.wready;
    assign s_axi.w_sub.wlast    = S_AXI_CALIPTRA_WLAST;
    // B
    assign S_AXI_CALIPTRA_BRESP  = s_axi.w_sub.bresp;
    assign S_AXI_CALIPTRA_BID    = s_axi.w_sub.bid;
    assign S_AXI_CALIPTRA_BVALID = s_axi.w_sub.bvalid;
    assign s_axi.w_sub.bready  = S_AXI_CALIPTRA_BREADY;
    // AR
    assign s_axi.r_sub.araddr  = S_AXI_CALIPTRA_ARADDR;
    assign s_axi.r_sub.arburst = S_AXI_CALIPTRA_ARBURST;
    assign s_axi.r_sub.arsize  = S_AXI_CALIPTRA_ARSIZE;
    assign s_axi.r_sub.arlen   = S_AXI_CALIPTRA_ARLEN;
    assign s_axi.r_sub.aruser  = S_AXI_CALIPTRA_ARUSER;
    assign s_axi.r_sub.arid    = S_AXI_CALIPTRA_ARID;
    assign s_axi.r_sub.arlock  = S_AXI_CALIPTRA_ARLOCK;
    assign s_axi.r_sub.arvalid = S_AXI_CALIPTRA_ARVALID;
    assign S_AXI_CALIPTRA_ARREADY = s_axi.r_sub.arready;
    // R
    assign S_AXI_CALIPTRA_RDATA  = s_axi.r_sub.rdata;
    assign S_AXI_CALIPTRA_RRESP  = s_axi.r_sub.rresp;
    assign S_AXI_CALIPTRA_RID    = s_axi.r_sub.rid;
    assign S_AXI_CALIPTRA_RLAST  = s_axi.r_sub.rlast;
    assign S_AXI_CALIPTRA_RVALID = s_axi.r_sub.rvalid;
    assign s_axi.r_sub.rready = S_AXI_CALIPTRA_RREADY;


    el2_mem_if el2_mem_export ();

    initial begin
        BootFSM_BrkPoint = 1'b1; //Set to 1 even before anything starts
    end

    // TRNG Interface
    logic etrng_req;
    logic [3:0] itrng_data;
    logic itrng_valid;

//=========================================================================-
// DUT instance
//=========================================================================-
caliptra_top caliptra_top_dut (
    .cptra_pwrgood              (hwif_out.interface_regs.control.cptra_pwrgood.value),
    .cptra_rst_b                (hwif_out.interface_regs.control.cptra_rst_b.value),
    .clk                        (core_clk),

    .cptra_obf_key              ({hwif_out.interface_regs.cptra_obf_key[7].value.value,
                                  hwif_out.interface_regs.cptra_obf_key[6].value.value,
                                  hwif_out.interface_regs.cptra_obf_key[5].value.value,
                                  hwif_out.interface_regs.cptra_obf_key[4].value.value,
                                  hwif_out.interface_regs.cptra_obf_key[3].value.value,
                                  hwif_out.interface_regs.cptra_obf_key[2].value.value,
                                  hwif_out.interface_regs.cptra_obf_key[1].value.value,
                                  hwif_out.interface_regs.cptra_obf_key[0].value.value}),

    .jtag_tck(jtag_tck),
    .jtag_tdi(jtag_tdi),
    .jtag_tms(jtag_tms),
    .jtag_trst_n(jtag_trst_n),
    .jtag_tdo(jtag_tdo),

    // SoC APB Interface
    //.PADDR(PADDR),
    //.PPROT(PPROT), // TODO: PPROT not provided?
    //.PAUSER(hwif_out.interface_regs.pauser.pauser.value),
    //.PENABLE(PENABLE),
    //.PRDATA(PRDATA),
    //.PREADY(PREADY),
    //.PSEL(PSEL),
    //.PSLVERR(PSLVERR),
    //.PWDATA(PWDATA),
    //.PWRITE(PWRITE),

    //SoC AXI Interface
    .s_axi_w_if(s_axi.w_sub),
    .s_axi_r_if(s_axi.r_sub),

    // AXI Manager INF
    // TODO: How to use this?
    //m_axi_w_if(axi_if.w_mgr),
    //m_axi_r_if(axi_if.r_mgr),

    .qspi_clk_o (),
    .qspi_cs_no (),
    .qspi_d_i   (),
    .qspi_d_o   (),
    .qspi_d_en_o(),

    .el2_mem_export(el2_mem_export.veer_sram_src),

    .ready_for_fuses(hwif_in.interface_regs.status.ready_for_fuses.next),
    .ready_for_fw_push(hwif_in.interface_regs.status.ready_for_fw_push.next),
    .ready_for_runtime(hwif_in.interface_regs.status.ready_for_runtime.next),

    .mbox_sram_cs(mbox_sram_cs),
    .mbox_sram_we(mbox_sram_we),
    .mbox_sram_addr(mbox_sram_addr),
    .mbox_sram_wdata(mbox_sram_wdata),
    .mbox_sram_rdata(mbox_sram_rdata),

    .imem_cs(imem_cs),
    .imem_addr(imem_addr),
    .imem_rdata(imem_rdata),

    .mailbox_data_avail(hwif_in.interface_regs.status.mailbox_data_avail.next),
    .mailbox_flow_done(hwif_in.interface_regs.status.mailbox_flow_done.next),

    // TODO: New addition
    .recovery_data_avail(0),

    .BootFSM_BrkPoint(BootFSM_BrkPoint),

    //SoC Interrupts
    .cptra_error_fatal    (hwif_in.interface_regs.status.cptra_error_fatal.next),
    .cptra_error_non_fatal(hwif_in.interface_regs.status.cptra_error_non_fatal.next),

    .etrng_req             (etrng_req),
    .itrng_data            (itrng_data),
    .itrng_valid           (itrng_valid),

    .generic_input_wires({hwif_out.interface_regs.generic_input_wires[0].value.value, hwif_out.interface_regs.generic_input_wires[1].value.value}),
    .generic_output_wires({hwif_in.interface_regs.generic_output_wires[0].value.next, hwif_in.interface_regs.generic_output_wires[1].value.next}),

    .security_state({hwif_out.interface_regs.control.ss_debug_locked.value, hwif_out.interface_regs.control.ss_device_lifecycle.value}),
    .scan_mode     (scan_mode) //FIXME TIE-OFF
);


// EL2 Memory
caliptra_veer_sram_export veer_sram_export_inst (
    .el2_mem_export(el2_mem_export.veer_sram_sink)
);

// Mailbox RAM
fpga_mbox_ram mbox_ram1
(
    .clka(core_clk),

    .ena(mbox_sram_cs),
    .wea(mbox_sram_we),
    .addra(mbox_sram_addr),
    .dina(mbox_sram_wdata),

    .douta(mbox_sram_rdata)
);

// SRAM for imem/ROM
fpga_imem imem_inst1(
    // Port A for Caliptra
    .clka(core_clk),
    .ena(imem_cs),
    .wea(8'h0),
    .addra(imem_addr),
    .dina(0),
    .douta(imem_rdata),
    // Port B to the AXI bus for loading ROM
    .clkb(axi_bram_clk),
    .enb(axi_bram_en),
    .web(axi_bram_we),
    .addrb(axi_bram_addr),
    .dinb(axi_bram_wrdata),
    .doutb(axi_bram_rddata),
    .rstb(axi_bram_rst)
);

    axi4lite_intf s_axil ();

    caliptra_fpga_realtime_regs__in_t hwif_in;
    caliptra_fpga_realtime_regs__out_t hwif_out;

    assign S_AXI_AWREADY = s_axil.AWREADY;
    assign S_AXI_WREADY = s_axil.WREADY;
    assign S_AXI_BVALID = s_axil.BVALID;
    assign S_AXI_BRESP = s_axil.BRESP;
    assign S_AXI_ARREADY = s_axil.ARREADY;
    assign S_AXI_RVALID = s_axil.RVALID;
    assign S_AXI_RDATA = s_axil.RDATA;
    assign S_AXI_RRESP = s_axil.RRESP;

    always_comb begin
        s_axil.AWVALID = S_AXI_AWVALID;
        s_axil.AWADDR = S_AXI_AWADDR;
        s_axil.AWPROT = S_AXI_AWPROT;

        s_axil.WVALID = S_AXI_WVALID;
        s_axil.WDATA = S_AXI_WDATA;
        s_axil.WSTRB = S_AXI_WSTRB;

        s_axil.BREADY = S_AXI_BREADY;

        s_axil.ARVALID = S_AXI_ARVALID;
        s_axil.ARADDR = S_AXI_ARADDR;
        s_axil.ARPROT = S_AXI_ARPROT;

        s_axil.RREADY = S_AXI_RREADY;
    end

    // Register Block
    caliptra_fpga_realtime_regs regs (
        .clk(core_clk),
        .rst(~S_AXI_ARESETN),

        .s_axil(s_axil),

        .hwif_in (hwif_in),
        .hwif_out(hwif_out)
    );

    // Valid = !Empty
    logic log_fifo_empty;
    assign hwif_in.fifo_regs.log_fifo_data.char_valid.next = ~log_fifo_empty;
    assign hwif_in.fifo_regs.log_fifo_status.log_fifo_empty.next = log_fifo_empty;

    // When rd_swacc is asserted, use the value of "valid" from when it was sampled.
    reg log_fifo_valid_f;
    always@(posedge core_clk) begin
        log_fifo_valid_f <= ~log_fifo_empty;
    end

    // Hierarchical references to generic output wires register. Use as input to log FIFO.
    logic fifo_write_en;
    logic [7:0] fifo_char;
    assign fifo_write_en = caliptra_top_dut.soc_ifc_top1.i_soc_ifc_reg.field_combo.CPTRA_GENERIC_OUTPUT_WIRES[0].generic_wires.load_next;
    assign fifo_char[7:0] = caliptra_top_dut.soc_ifc_top1.i_soc_ifc_reg.field_combo.CPTRA_GENERIC_OUTPUT_WIRES[0].generic_wires.next[7:0];

    log_fifo log_fifo_inst(
        .clk (core_clk),
        .srst (~S_AXI_ARESETN),
        .dout (hwif_in.fifo_regs.log_fifo_data.next_char.next),
        .empty (log_fifo_empty),
        .full (hwif_in.fifo_regs.log_fifo_status.log_fifo_full.next),
        .din (fifo_char),
        .wr_en (fifo_write_en),
        .rd_en (log_fifo_valid_f & hwif_out.fifo_regs.log_fifo_data.next_char.rd_swacc),
        .prog_full () // [get_bd_pins zynq_ultra_ps_e_0/pl_ps_irq0]
    );


`ifdef CALIPTRA_INTERNAL_TRNG

    reg throttled_etrng_req;
    // wr_swacc is asserted one cycle before the hwif_out has the new value. Delay wr_en by one cycle.
    reg trng_fifo_wr_en;
    always@(posedge core_clk) begin
        trng_fifo_wr_en <= hwif_out.fifo_regs.itrng_fifo_data.itrng_data.wr_swacc;
    end

    itrng_fifo trng_fifo_inst(
        .clk (core_clk),
        .srst (hwif_out.fifo_regs.itrng_fifo_status.itrng_fifo_reset.value),
        .dout (itrng_data),
        .empty (hwif_in.fifo_regs.itrng_fifo_status.itrng_fifo_empty.next),
        .full (hwif_in.fifo_regs.itrng_fifo_status.itrng_fifo_full.next),
        .din (hwif_out.fifo_regs.itrng_fifo_data.itrng_data.value),
        .wr_en (trng_fifo_wr_en),
        .rd_en (throttled_etrng_req),
        .valid (itrng_valid)
    );

    // Throttle etrng_req.
    reg [31:0] counter;
    always@(posedge core_clk) begin
        if (counter == 0) begin
            throttled_etrng_req <= etrng_req;
            counter <= hwif_out.interface_regs.itrng_divisor.itrng_divisor.value;
        end else begin
            throttled_etrng_req <= 0;
            counter <= counter - 1;
        end
    end
`else
    assign itrng_data  = 4'b0;
    assign itrng_valid = 1'b0;
`endif

    reg [31:0] cycle_count;
    always@(posedge core_clk or negedge hwif_out.interface_regs.control.cptra_rst_b.value) begin
        if (~hwif_out.interface_regs.control.cptra_rst_b.value) begin
            cycle_count <= 0;
        end
        else begin
            cycle_count <= cycle_count + 1;
        end
    end
    assign hwif_in.interface_regs.cycle_count.cycle_count.next = cycle_count;

endmodule
