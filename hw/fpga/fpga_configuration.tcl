# Create path variables
set fpgaDir [file dirname [info script]]
set outputDir $fpgaDir/caliptra_build
set packageDir $outputDir/caliptra_package
set adapterDir $outputDir/soc_adapter_package
# Clean and create output directory.
file delete -force $outputDir
file mkdir $outputDir
file mkdir $packageDir
file mkdir $adapterDir

# Simplistic processing of command line arguments to enable different features
# Defaults:
set BUILD FALSE
set GUI   FALSE
set JTAG  TRUE
set ITRNG TRUE
set CG_EN FALSE
set RTL_VERSION latest
set BOARD ZCU104
foreach arg $argv {
    regexp {(.*)=(.*)} $arg fullmatch option value
    set $option "$value"
}
# If VERSION was not set by tclargs, set it from the commit ID.
# This assumes it is run from within caliptra-sw. If building from outside caliptra-sw call with "VERSION=[hex number]"
if {[info exists VERSION] == 0} {
  set VERSION [exec git rev-parse --short HEAD]
}

# Path to rtl
set rtlDir $fpgaDir/../$RTL_VERSION/rtl
puts "JTAG: $JTAG"
puts "ITRNG: $ITRNG"
puts "CG_EN: $CG_EN"
puts "RTL_VERSION: $RTL_VERSION"
puts "Using RTL directory $rtlDir"

# Set Verilog defines for:
#     Caliptra clock gating module
#     VEER clock gating module
#     VEER core FPGA optimizations (disables clock gating)
if {$CG_EN} {
  set VERILOG_OPTIONS {TECH_SPECIFIC_ICG USER_ICG=fpga_real_icg TECH_SPECIFIC_EC_RV_ICG USER_EC_RV_ICG=fpga_rv_clkhdr}
  set GATED_CLOCK_CONVERSION auto
} else {
  set VERILOG_OPTIONS {TECH_SPECIFIC_ICG USER_ICG=fpga_fake_icg RV_FPGA_OPTIMIZE TEC_RV_ICG=clockhdr}
  set GATED_CLOCK_CONVERSION off
}
if {$ITRNG} {
  # Add option to use Caliptra's internal TRNG instead of ETRNG
  lappend VERILOG_OPTIONS CALIPTRA_INTERNAL_TRNG
}

# Start the Vivado GUI for interactive debug
if {$GUI} {
  start_gui
}

if {$BOARD eq "ZCU104"} {
  set PART xczu7ev-ffvc1156-2-e
} elseif {$BOARD eq "VCK190"} {
  set PART xcvc1902-vsva2197-2MP-e-S
} else {
  puts "Board $BOARD not supported"
  exit
}

# Create a project to package Caliptra.
# Packaging Caliptra allows Vivado to recognize the APB bus as an endpoint for the memory map.
create_project caliptra_package_project $outputDir -part $PART
set_property board_part xilinx.com:vck190:part0:3.1 [current_project]

set_property verilog_define $VERILOG_OPTIONS [current_fileset]

# Add VEER Headers
add_files $rtlDir/src/riscv_core/veer_el2/rtl/el2_param.vh
add_files $rtlDir/src/riscv_core/veer_el2/rtl/pic_map_auto.h
add_files $rtlDir/src/riscv_core/veer_el2/rtl/el2_pdef.vh

# Add VEER sources
add_files [ glob $rtlDir/src/riscv_core/veer_el2/rtl/*.sv ]
add_files [ glob $rtlDir/src/riscv_core/veer_el2/rtl/*/*.sv ]
add_files [ glob $rtlDir/src/riscv_core/veer_el2/rtl/*/*.v ]

# Add Caliptra Headers
add_files [ glob $rtlDir/src/*/rtl/*.svh ]
# Add Caliptra Sources
add_files [ glob $rtlDir/src/*/rtl/*.sv ]
add_files [ glob $rtlDir/src/*/rtl/*.v ]

# Remove spi_host files that aren't used yet and are flagged as having syntax errors
# TODO: Re-include these files when spi_host is used.
remove_files [ glob $rtlDir/src/spi_host/rtl/*.sv ]

# Remove Caliptra files that need to be replaced by FPGA specific versions
# Replace RAM with FPGA block ram
remove_files [ glob $rtlDir/src/ecc/rtl/ecc_ram_tdp_file.sv ]
# Key Vault is very large. Replacing KV with a version with the minimum number of entries.
remove_files [ glob $rtlDir/src/keyvault/rtl/kv_reg.sv ]

# Add FPGA specific sources
add_files [ glob $fpgaDir/src/*.sv]
add_files [ glob $fpgaDir/src/*.v]

# Mark all Verilog sources as SystemVerilog because some of them have SystemVerilog syntax.
set_property file_type SystemVerilog [get_files *.v]

# Exception: caliptra_package_top.v needs to be Verilog to be included in a Block Diagram.
set_property file_type Verilog [get_files  $fpgaDir/src/caliptra_package_top.v]

# Add include paths
set_property include_dirs $rtlDir/src/integration/rtl [current_fileset]


# Set caliptra_package_top as top in case next steps fail so that the top is something useful.
set_property top caliptra_package_top [current_fileset]

# Create block diagram that includes an instance of caliptra_package_top
create_bd_design "caliptra_package_bd"
create_bd_cell -type module -reference caliptra_package_top caliptra_package_top_0
save_bd_design
close_bd_design [get_bd_designs caliptra_package_bd]

# Package IP
ipx::package_project -root_dir $packageDir -vendor design -library user -taxonomy /UserIP -import_files -set_current false
ipx::unload_core $packageDir/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $packageDir $packageDir/component.xml
ipx::infer_bus_interfaces xilinx.com:interface:apb_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interfaces xilinx.com:interface:bram_rtl:1.0 [ipx::current_core]
ipx::add_bus_parameter MASTER_TYPE [ipx::get_bus_interfaces axi_bram -of_objects [ipx::current_core]]
ipx::associate_bus_interfaces -busif S_AXI -clock core_clk [ipx::current_core]
set_property core_revision 1 [ipx::current_core]
ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]

# Close temp project
close_project
# Close caliptra_package_project
close_project

# Packaging complete

# Create a project for the SOC connections
create_project caliptra_fpga_project $outputDir -part $PART

# Include the packaged IP
set_property  ip_repo_paths  "$packageDir $adapterDir" [current_project]
update_ip_catalog

# Create SOC block design
create_bd_design "caliptra_fpga_project_bd"

# Add Caliptra package
create_bd_cell -type ip -vlnv design:user:caliptra_package_top:1.0 caliptra_package_top_0

# Add Zynq/Versal PS
if {$BOARD eq "ZCU104"} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e ps_0
  set_property -dict [list \
    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {20} \
    CONFIG.PSU__USE__IRQ0 {1} \
    CONFIG.PSU__GPIO_EMIO__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__GPIO_EMIO__PERIPHERAL__IO {5} \
  ] [get_bd_cells ps_0]

  # Create variables to adapt between PS
  set ps_m_axi ps_0/M_AXI_HPM0_LPD
  set ps_pl_clk ps_0/pl_clk0
  set ps_axi_aclk ps_0/maxihpm0_lpd_aclk
  set ps_pl_resetn ps_0/pl_resetn0
  set ps_gpio_i ps_0/emio_gpio_i
  set ps_gpio_o ps_0/emio_gpio_o

  # Create XDC file with constraints
  set xdc_fd [ open $outputDir/jtag_constraints.xdc w ]
  puts $xdc_fd {create_clock -period 5000.000 -name {jtag_clk} -waveform {0.000 2500.000} [get_pins {caliptra_fpga_project_bd_i/ps_0/inst/PS8_i/EMIOGPIOO[0]}]}
  puts $xdc_fd {set_clock_groups -asynchronous -group [get_clocks {jtag_clk}]}
  close $xdc_fd

} else {
  # Create interface ports
  set ddr4_dimm1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_dimm1 ]

  set ddr4_dimm1_sma_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ddr4_dimm1_sma_clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {200000000} \
   ] $ddr4_dimm1_sma_clk

  create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips ps_0
  set_property -dict [list \
    CONFIG.CLOCK_MODE {Custom} \
    CONFIG.DDR_MEMORY_MODE {Enable} \
    CONFIG.DEBUG_MODE {JTAG} \
    CONFIG.DESIGN_MODE {1} \
    CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
    CONFIG.PS_PMC_CONFIG { \
      CLOCK_MODE {Custom} \
      DDR_MEMORY_MODE {Connectivity to DDR via NOC} \
      DEBUG_MODE {JTAG} \
      DESIGN_MODE {1} \
      PMC_CRP_PL0_REF_CTRL_FREQMHZ {20} \
      PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 25}}} \
      PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 51}}} \
      PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_OSPI_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0 .. 11}} {MODE Single}} \
      PMC_QSPI_COHERENCY {0} \
      PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}} \
      PMC_QSPI_PERIPHERAL_DATA_MODE {x4} \
      PMC_QSPI_PERIPHERAL_ENABLE {1} \
      PMC_QSPI_PERIPHERAL_MODE {Dual Parallel} \
      PMC_REF_CLK_FREQMHZ {33.3333} \
      PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}} \
      PMC_SD1_COHERENCY {0} \
      PMC_SD1_DATA_TRANSFER_MODE {8Bit} \
      PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x3} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x36} {CLK_50_DDR_OTAP_DLY 0x3} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE 1} {IO\
{PMC_MIO 26 .. 36}}} \
      PMC_SD1_SLOT_TYPE {SD 3.0} \
      PMC_USE_PMC_NOC_AXI0 {1} \
      PS_CAN1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 40 .. 41}}} \
      PS_CRL_CAN1_REF_CTRL_FREQMHZ {160} \
      PS_ENET0_MDIO {{ENABLE 1} {IO {PS_MIO 24 .. 25}}} \
      PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}} \
      PS_ENET1_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 12 .. 23}}} \
      PS_GEN_IPI0_ENABLE {1} \
      PS_GEN_IPI0_MASTER {A72} \
      PS_GEN_IPI1_ENABLE {1} \
      PS_GEN_IPI2_ENABLE {1} \
      PS_GEN_IPI3_ENABLE {1} \
      PS_GEN_IPI4_ENABLE {1} \
      PS_GEN_IPI5_ENABLE {1} \
      PS_GEN_IPI6_ENABLE {1} \
      PS_HSDP_EGRESS_TRAFFIC {JTAG} \
      PS_HSDP_INGRESS_TRAFFIC {JTAG} \
      PS_HSDP_MODE {NONE} \
      PS_I2C0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 46 .. 47}}} \
      PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}} \
      PS_MIO19 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO21 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_PCIE_EP_RESET1_IO {PMC_MIO 38} \
      PS_PCIE_EP_RESET2_IO {PMC_MIO 39} \
      PS_PCIE_RESET {ENABLE 1} \
      PS_PL_CONNECTIVITY_MODE {Custom} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
      PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}} \
      PS_USE_FPD_AXI_NOC0 {1} \
      PS_USE_FPD_AXI_NOC1 {1} \
      PS_USE_FPD_CCI_NOC {1} \
      PS_USE_FPD_CCI_NOC0 {1} \
      PS_USE_M_AXI_FPD {1} \
      PS_USE_NOC_LPD_AXI0 {1} \
      PS_USE_PMCPL_CLK0 {1} \
      PS_USE_PMCPL_CLK1 {0} \
      PS_USE_PMCPL_CLK2 {0} \
      PS_USE_PMCPL_CLK3 {0} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
      PS_GPIO_EMIO_WIDTH {5} \
      PS_GPIO_EMIO_PERIPHERAL_ENABLE {1} \
    } \
  ] [get_bd_cells ps_0]
  #  CONFIG.PS_BOARD_INTERFACE {ps_pmc_fixed_io} \
  #  PS_BOARD_INTERFACE {ps_pmc_fixed_io} \
  
  # Create instance: axi_noc_0, and set properties
  set axi_noc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc axi_noc_0 ]
  set_property -dict [ list \
   CONFIG.CONTROLLERTYPE {DDR4_SDRAM} \
   CONFIG.MC_CHAN_REGION1 {DDR_LOW1} \
   CONFIG.MC_COMPONENT_WIDTH {x8} \
   CONFIG.MC_DATAWIDTH {64} \
   CONFIG.MC_INPUTCLK0_PERIOD {5000} \
   CONFIG.MC_INTERLEAVE_SIZE {128} \
   CONFIG.MC_MEMORY_DEVICETYPE {UDIMMs} \
   CONFIG.MC_MEMORY_SPEEDGRADE {DDR4-3200AA(22-22-22)} \
   CONFIG.MC_NO_CHANNELS {Single} \
   CONFIG.MC_RANK {1} \
   CONFIG.MC_ROWADDRESSWIDTH {16} \
   CONFIG.MC_STACKHEIGHT {1} \
   CONFIG.MC_SYSTEM_CLOCK {Differential} \
   CONFIG.NUM_CLKS {8} \
   CONFIG.NUM_MC {1} \
   CONFIG.NUM_MCP {4} \
   CONFIG.NUM_MI {0} \
   CONFIG.NUM_SI {8} \
 ] $axi_noc_0
  #  CONFIG.CH0_DDR4_0_BOARD_INTERFACE {ddr4_dimm1} \
  #  CONFIG.sys_clk0_BOARD_INTERFACE {ddr4_dimm1_sma_clk} \

set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S00_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {MC_1 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S01_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {MC_2 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S02_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {MC_3 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S03_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S04_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S05_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {MC_1 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S06_AXI]
set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {MC_2 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S07_AXI]
#set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S03_AXI:S02_AXI:S00_AXI:S01_AXI:S04_AXI:S07_AXI:S06_AXI:S05_AXI}] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S00_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S01_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_2 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S02_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_cci} \
 ] [get_bd_intf_pins /axi_noc_0/S03_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_rpu} \
 ] [get_bd_intf_pins /axi_noc_0/S04_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.REGION {0} \
   CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}} \
   CONFIG.CATEGORY {ps_pmc} \
 ] [get_bd_intf_pins /axi_noc_0/S05_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_1 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins /axi_noc_0/S06_AXI]

  set_property -dict [ list \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.CONNECTIONS {MC_2 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} } \
   CONFIG.CATEGORY {ps_nci} \
 ] [get_bd_intf_pins /axi_noc_0/S07_AXI]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk0]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S01_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk1]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S02_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk2]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S03_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk3]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S04_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk4]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S05_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk5]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S06_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk6]

  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S07_AXI} \
 ] [get_bd_pins /axi_noc_0/aclk7]



  # Create variables to adapt between PS
  set ps_m_axi ps_0/M_AXI_FPD
  set ps_pl_clk ps_0/pl0_ref_clk
  set ps_axi_aclk ps_0/m_axi_fpd_aclk
  set ps_pl_resetn ps_0/pl0_resetn
  set ps_gpio_i ps_0/LPD_GPIO_i
  set ps_gpio_o ps_0/LPD_GPIO_o
  #connect_bd_intf_net -intf_net ps_0_M_AXI_FPD [get_bd_intf_pins ps_0/M_AXI_FPD] [get_bd_intf_pins PL/S00_AXI]

  # Connect DDR
  connect_bd_intf_net -intf_net axi_noc_0_CH0_DDR4_0 [get_bd_intf_ports ddr4_dimm1] [get_bd_intf_pins axi_noc_0/CH0_DDR4_0]
  connect_bd_intf_net -intf_net ddr4_dimm1_sma_clk_1 [get_bd_intf_ports ddr4_dimm1_sma_clk] [get_bd_intf_pins axi_noc_0/sys_clk0]
  # Connect axi_noc_0 to cips
  connect_bd_intf_net -intf_net ps_0_FPD_AXI_NOC_0 [get_bd_intf_pins axi_noc_0/S06_AXI] [get_bd_intf_pins ps_0/FPD_AXI_NOC_0]
  connect_bd_intf_net -intf_net ps_0_FPD_AXI_NOC_1 [get_bd_intf_pins axi_noc_0/S07_AXI] [get_bd_intf_pins ps_0/FPD_AXI_NOC_1]
  connect_bd_intf_net -intf_net ps_0_FPD_CCI_NOC_0 [get_bd_intf_pins axi_noc_0/S00_AXI] [get_bd_intf_pins ps_0/FPD_CCI_NOC_0]
  connect_bd_intf_net -intf_net ps_0_FPD_CCI_NOC_1 [get_bd_intf_pins axi_noc_0/S01_AXI] [get_bd_intf_pins ps_0/FPD_CCI_NOC_1]
  connect_bd_intf_net -intf_net ps_0_FPD_CCI_NOC_2 [get_bd_intf_pins axi_noc_0/S02_AXI] [get_bd_intf_pins ps_0/FPD_CCI_NOC_2]
  connect_bd_intf_net -intf_net ps_0_FPD_CCI_NOC_3 [get_bd_intf_pins axi_noc_0/S03_AXI] [get_bd_intf_pins ps_0/FPD_CCI_NOC_3]
  connect_bd_intf_net -intf_net ps_0_LPD_AXI_NOC_0 [get_bd_intf_pins axi_noc_0/S04_AXI] [get_bd_intf_pins ps_0/LPD_AXI_NOC_0]
  connect_bd_intf_net -intf_net ps_0_PMC_NOC_AXI_0 [get_bd_intf_pins axi_noc_0/S05_AXI] [get_bd_intf_pins ps_0/PMC_NOC_AXI_0]
  # axi_noc_0 clocks
  connect_bd_net [get_bd_pins axi_noc_0/aclk0] [get_bd_pins ps_0/fpd_cci_noc_axi0_clk]
  connect_bd_net [get_bd_pins axi_noc_0/aclk1] [get_bd_pins ps_0/fpd_cci_noc_axi1_clk]
  connect_bd_net [get_bd_pins axi_noc_0/aclk2] [get_bd_pins ps_0/fpd_cci_noc_axi2_clk]
  connect_bd_net [get_bd_pins axi_noc_0/aclk3] [get_bd_pins ps_0/fpd_cci_noc_axi3_clk]
  connect_bd_net [get_bd_pins axi_noc_0/aclk4] [get_bd_pins ps_0/lpd_axi_noc_clk]
  connect_bd_net [get_bd_pins axi_noc_0/aclk5] [get_bd_pins ps_0/pmc_axi_noc_axi0_clk]
  connect_bd_net [get_bd_pins axi_noc_0/aclk6] [get_bd_pins ps_0/fpd_axi_noc_axi0_clk]
  connect_bd_net [get_bd_pins axi_noc_0/aclk7] [get_bd_pins ps_0/fpd_axi_noc_axi1_clk]

  # Create XDC file with constraints
  set xdc_fd [ open $outputDir/jtag_constraints.xdc w ]
  puts $xdc_fd {create_clock -period 5000.000 -name {jtag_clk} -waveform {0.000 2500.000} [get_pins {caliptra_fpga_project_bd_i/ps_0/inst/pspmc_0/inst/PS9_inst/EMIOGPIO2O[0]}]}
  puts $xdc_fd {set_clock_groups -asynchronous -group [get_clocks {jtag_clk}]}
  close $xdc_fd
}

# Add AXI Interconnect
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_interconnect_0
set_property -dict [list \
  CONFIG.NUM_MI {3} \
  CONFIG.NUM_SI {1} \
] [get_bd_cells axi_interconnect_0]

# Add AXI APB Bridge for Caliptra
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_apb_bridge:3.0 axi_apb_bridge_0
set_property -dict [list \
  CONFIG.C_APB_NUM_SLAVES {1} \
  CONFIG.C_M_APB_PROTOCOL {apb4} \
] [get_bd_cells axi_apb_bridge_0]

# Add AXI BRAM Controller for backdoor access to IMEM
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
set_property CONFIG.SINGLE_PORT_BRAM {1} [get_bd_cells axi_bram_ctrl_0]

# Create reset block
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0

# Move blocks around on the block diagram. This step is optional.
set_property location {1 177 345} [get_bd_cells ps_0]
set_property location {2 696 373} [get_bd_cells axi_interconnect_0]
set_property location {2 707 654} [get_bd_cells proc_sys_reset_0]
set_property location {3 1041 439} [get_bd_cells axi_apb_bridge_0]
set_property location {3 1151 617} [get_bd_cells axi_bram_ctrl_0]
set_property location {4 1335 456} [get_bd_cells caliptra_package_top_0]

# Create AXI bus connections
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins $ps_m_axi]
# AXI for FPGA wrapper registers
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins caliptra_package_top_0/S_AXI]
# AXI to APB for Caliptra
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins axi_apb_bridge_0/AXI4_LITE]
connect_bd_intf_net [get_bd_intf_pins axi_apb_bridge_0/APB_M] [get_bd_intf_pins caliptra_package_top_0/s_apb]
# AXI connection to program ROM
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins caliptra_package_top_0/axi_bram] [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]

# Create reset connections
connect_bd_net [get_bd_pins $ps_pl_resetn] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net -net proc_sys_reset_0_peripheral_aresetn \
  [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
  [get_bd_pins axi_apb_bridge_0/s_axi_aresetn] \
  [get_bd_pins axi_interconnect_0/aresetn] \
  [get_bd_pins caliptra_package_top_0/S_AXI_ARESETN] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
# Create clock connections
connect_bd_net -net ps_0_pl0_ref_clk \
  [get_bd_pins $ps_pl_clk] \
  [get_bd_pins $ps_axi_aclk] \
  [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
  [get_bd_pins axi_apb_bridge_0/s_axi_aclk] \
  [get_bd_pins axi_interconnect_0/aclk] \
  [get_bd_pins caliptra_package_top_0/core_clk] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]

# Create address segments
# TODO: Had to change memory aperatures
assign_bd_address -offset 0xB0000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces ps_0/Data] [get_bd_addr_segs caliptra_package_top_0/S_AXI/reg0] -force
assign_bd_address -offset 0xB2000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces ps_0/Data] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
assign_bd_address -offset 0xC0000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces ps_0/Data] [get_bd_addr_segs caliptra_package_top_0/s_apb/Reg] -force
# NoC - TODO still have problems with this
#assign_bd_address -offset 0xA4000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces ps_0/M_AXI_FPD] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW0] -force
#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S04_AXI/C0_DDR_LOW0] -force
#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C0_DDR_LOW0] -force
#assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces ps_0/FPD_CCI_NOC_0] [get_bd_addr_segs axi_noc_0/S00_AXI/C0_DDR_LOW1] -force
#assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces ps_0/LPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S04_AXI/C0_DDR_LOW1] -force
#assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces ps_0/PMC_NOC_AXI_0] [get_bd_addr_segs axi_noc_0/S05_AXI/C0_DDR_LOW1] -force
#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S01_AXI/C1_DDR_LOW0] -force
#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_0/FPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S06_AXI/C1_DDR_LOW0] -force
#assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces ps_0/FPD_CCI_NOC_1] [get_bd_addr_segs axi_noc_0/S01_AXI/C1_DDR_LOW1] -force
#assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces ps_0/FPD_AXI_NOC_0] [get_bd_addr_segs axi_noc_0/S06_AXI/C1_DDR_LOW1] -force
#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S02_AXI/C2_DDR_LOW0] -force
#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_0/FPD_AXI_NOC_1] [get_bd_addr_segs axi_noc_0/S07_AXI/C2_DDR_LOW0] -force
#assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces ps_0/FPD_CCI_NOC_2] [get_bd_addr_segs axi_noc_0/S02_AXI/C2_DDR_LOW1] -force
#assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces ps_0/FPD_AXI_NOC_1] [get_bd_addr_segs axi_noc_0/S07_AXI/C2_DDR_LOW1] -force
#assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces ps_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S03_AXI/C3_DDR_LOW0] -force
#assign_bd_address -offset 0x000800000000 -range 0x000180000000 -target_address_space [get_bd_addr_spaces ps_0/FPD_CCI_NOC_3] [get_bd_addr_segs axi_noc_0/S03_AXI/C3_DDR_LOW1] -force
# all get_bd_addr_segs
#/axi_bram_ctrl_0/S_AXI/Mem0
#/axi_noc_0/S01_AXI/C1_DDR_LOW0
#/axi_noc_0/S01_AXI/C1_DDR_LOW1
#/axi_noc_0/S02_AXI/C2_DDR_LOW0
#/axi_noc_0/S02_AXI/C2_DDR_LOW1
#/axi_noc_0/S03_AXI/C3_DDR_LOW0
#/axi_noc_0/S03_AXI/C3_DDR_LOW1
#/axi_noc_0/S04_AXI/C0_DDR_LOW0
#/axi_noc_0/S04_AXI/C0_DDR_LOW1
#/axi_noc_0/S05_AXI/C0_DDR_LOW0
#/axi_noc_0/S05_AXI/C0_DDR_LOW1
#/axi_noc_0/S06_AXI/C1_DDR_LOW0
#/axi_noc_0/S06_AXI/C1_DDR_LOW1
#/axi_noc_0/S07_AXI/C2_DDR_LOW0
#/axi_noc_0/S07_AXI/C2_DDR_LOW1
#/caliptra_package_top_0/S_AXI/reg0
#/caliptra_package_top_0/s_apb/Reg
#/ps_0/M_AXI_FPD/SEG_axi_bram_ctrl_0_Mem0
#/ps_0/M_AXI_FPD/SEG_caliptra_package_top_0_Reg
#/ps_0/M_AXI_FPD/SEG_caliptra_package_top_0_reg0


# Connect JTAG signals to PS GPIO pins
connect_bd_net [get_bd_pins caliptra_package_top_0/jtag_out] [get_bd_pins $ps_gpio_i]
connect_bd_net [get_bd_pins caliptra_package_top_0/jtag_in] [get_bd_pins $ps_gpio_o]

# Add constraints for JTAG signals
add_files -fileset constrs_1 $outputDir/jtag_constraints.xdc

save_bd_design
set_property verilog_define $VERILOG_OPTIONS [current_fileset]

# Create the HDL wrapper for the block design and add it. This will be set as top.
make_wrapper -files [get_files $outputDir/caliptra_fpga_project.srcs/sources_1/bd/caliptra_fpga_project_bd/caliptra_fpga_project_bd.bd] -top
add_files -norecurse $outputDir/caliptra_fpga_project.gen/sources_1/bd/caliptra_fpga_project_bd/hdl/caliptra_fpga_project_bd_wrapper.v

update_compile_order -fileset sources_1

# Assign the gated clock conversion setting in the caliptra_package_top out of context run.
create_ip_run [get_files *.bd]
set_property STEPS.SYNTH_DESIGN.ARGS.GATED_CLOCK_CONVERSION $GATED_CLOCK_CONVERSION [get_runs caliptra_fpga_project_bd_caliptra_package_top_0_0_synth_1]

# The FPGA loading methods currently in use require the bin file to be generated.
if {$BOARD eq "ZCU104"} {
  set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]
}

# Place DDR MC pins... why wasn't this automatic? Is this right?
place_ports {ddr4_dimm1_act_n[0]} AR47 {ddr4_dimm1_adr[0]} AL46 {ddr4_dimm1_adr[10]} AL42 {ddr4_dimm1_adr[11]} AK38 {ddr4_dimm1_adr[12]} AN42 {ddr4_dimm1_adr[13]} AU45 {ddr4_dimm1_adr[14]} AK39 {ddr4_dimm1_adr[15]} AK40 {ddr4_dimm1_adr[16]} AL44 {ddr4_dimm1_adr[1]} AU44 {ddr4_dimm1_adr[2]} AR44 {ddr4_dimm1_adr[3]} AM41 {ddr4_dimm1_adr[4]} AL41 {ddr4_dimm1_adr[5]} AL37 {ddr4_dimm1_adr[6]} AM38 {ddr4_dimm1_adr[7]} AP43 {ddr4_dimm1_adr[8]} AN47 {ddr4_dimm1_adr[9]} AT44 {ddr4_dimm1_ba[0]} AN43 {ddr4_dimm1_ba[1]} AL47 {ddr4_dimm1_bg[0]} AP42 {ddr4_dimm1_bg[1]} AT47 {ddr4_dimm1_ck_c[0]} AT46 {ddr4_dimm1_ck_t[0]} AR46 {ddr4_dimm1_cke[0]} AR45 {ddr4_dimm1_cs_n[0]} AL43 {ddr4_dimm1_dm_n[0]} BC41 {ddr4_dimm1_dm_n[1]} BB43 {ddr4_dimm1_dm_n[2]} BB44 {ddr4_dimm1_dm_n[3]} AR42 {ddr4_dimm1_dm_n[4]} AH46 {ddr4_dimm1_dm_n[5]} AH45 {ddr4_dimm1_dm_n[6]} AG41 {ddr4_dimm1_dm_n[7]} AG39 {ddr4_dimm1_dq[0]} BE41 {ddr4_dimm1_dq[10]} AV42 {ddr4_dimm1_dq[11]} AV43 {ddr4_dimm1_dq[12]} BE42 {ddr4_dimm1_dq[13]} BD42 {ddr4_dimm1_dq[14]} AW43 {ddr4_dimm1_dq[15]} AW42 {ddr4_dimm1_dq[16]} BD45 {ddr4_dimm1_dq[17]} BC45 {ddr4_dimm1_dq[18]} AV45 {ddr4_dimm1_dq[19]} AW44 {ddr4_dimm1_dq[1]} BF41 {ddr4_dimm1_dq[20]} BD44 {ddr4_dimm1_dq[21]} BE45 {ddr4_dimm1_dq[22]} AW45 {ddr4_dimm1_dq[23]} AY44 {ddr4_dimm1_dq[24]} AM37 {ddr4_dimm1_dq[25]} AN38 {ddr4_dimm1_dq[26]} AR39 {ddr4_dimm1_dq[27]} AT39 {ddr4_dimm1_dq[28]} AT40 {ddr4_dimm1_dq[29]} AT41 {ddr4_dimm1_dq[2]} AV41 {ddr4_dimm1_dq[30]} AP39 {ddr4_dimm1_dq[31]} AN40 {ddr4_dimm1_dq[32]} AJ47 {ddr4_dimm1_dq[33]} AH47 {ddr4_dimm1_dq[34]} AE46 {ddr4_dimm1_dq[35]} AD45 {ddr4_dimm1_dq[36]} AK47 {ddr4_dimm1_dq[37]} AK46 {ddr4_dimm1_dq[38]} AE47 {ddr4_dimm1_dq[39]} AD47 {ddr4_dimm1_dq[3]} AU41 {ddr4_dimm1_dq[40]} AJ45 {ddr4_dimm1_dq[41]} AJ44 {ddr4_dimm1_dq[42]} AE44 {ddr4_dimm1_dq[43]} AD44 {ddr4_dimm1_dq[44]} AK45 {ddr4_dimm1_dq[45]} AK44 {ddr4_dimm1_dq[46]} AE45 {ddr4_dimm1_dq[47]} AF44 {ddr4_dimm1_dq[48]} AH41 {ddr4_dimm1_dq[49]} AH40 {ddr4_dimm1_dq[4]} BG41 {ddr4_dimm1_dq[50]} AD40 {ddr4_dimm1_dq[51]} AC39 {ddr4_dimm1_dq[52]} AH39 {ddr4_dimm1_dq[53]} AJ40 {ddr4_dimm1_dq[54]} AD41 {ddr4_dimm1_dq[55]} AE40 {ddr4_dimm1_dq[56]} AG37 {ddr4_dimm1_dq[57]} AH38 {ddr4_dimm1_dq[58]} AD37 {ddr4_dimm1_dq[59]} AC37 {ddr4_dimm1_dq[5]} BF42 {ddr4_dimm1_dq[60]} AH37 {ddr4_dimm1_dq[61]} AJ38 {ddr4_dimm1_dq[62]} AD39 {ddr4_dimm1_dq[63]} AD38 {ddr4_dimm1_dq[6]} AW41 {ddr4_dimm1_dq[7]} AW40 {ddr4_dimm1_dq[8]} BC42 {ddr4_dimm1_dq[9]} BC43 {ddr4_dimm1_dqs_c[0]} BA41 {ddr4_dimm1_dqs_c[1]} BA43 {ddr4_dimm1_dqs_c[2]} BA44 {ddr4_dimm1_dqs_c[3]} AP41 {ddr4_dimm1_dqs_c[4]} AF46 {ddr4_dimm1_dqs_c[5]} AG44 {ddr4_dimm1_dqs_c[6]} AF40 {ddr4_dimm1_dqs_c[7]} AF37 {ddr4_dimm1_dqs_t[0]} AY41 {ddr4_dimm1_dqs_t[1]} AY42 {ddr4_dimm1_dqs_t[2]} AY45 {ddr4_dimm1_dqs_t[3]} AP40 {ddr4_dimm1_dqs_t[4]} AF47 {ddr4_dimm1_dqs_t[5]} AH43 {ddr4_dimm1_dqs_t[6]} AF39 {ddr4_dimm1_dqs_t[7]} AE38 {ddr4_dimm1_odt[0]} AM39 {ddr4_dimm1_reset_n[0]} AD42 {ddr4_dimm1_sma_clk_clk_n[0]} AF43 {ddr4_dimm1_sma_clk_clk_p[0]} AE42


# Start build
if {$BUILD} {
  launch_runs synth_1 -jobs 10
  wait_on_runs synth_1
  launch_runs impl_1 -jobs 10
  wait_on_runs impl_1
  open_run impl_1
  report_utilization -file $outputDir/utilization.txt
  # Embed git hash in USR_ACCESS register for bitstream identification.
  set_property BITSTREAM.CONFIG.USR_ACCESS 0x$VERSION [current_design]
  write_bitstream -bin_file $outputDir/caliptra_fpga
}
