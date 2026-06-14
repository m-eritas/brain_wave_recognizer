//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.1.2 (win64) Build 5164865 Thu Sep  5 14:37:11 MDT 2024
//Date        : Sat Jun 13 23:53:28 2026
//Host        : MSI running 64-bit major release  (build 9200)
//Command     : generate_target design_1.bd
//Design      : design_1
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=design_1,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=9,numReposBlks=9,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=1,numHdlrefBlks=2,numPkgbdBlks=0,bdsource=USER,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "design_1.hwdef" *) 
module design_1
   (rst,
    sys_clk,
    vga_b,
    vga_g,
    vga_hsync,
    vga_r,
    vga_vsync);
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.RST RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.RST, INSERT_VIP 0, POLARITY ACTIVE_HIGH" *) input rst;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.SYS_CLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.SYS_CLK, ASSOCIATED_RESET ext_reset_in_0, CLK_DOMAIN design_1_clk_in1_0, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input sys_clk;
  output [3:0]vga_b;
  output [3:0]vga_g;
  output vga_hsync;
  output [3:0]vga_r;
  output vga_vsync;

  wire [2:0]band_sel_dout;
  wire brainwave_recognizer_0_flag_out;
  wire clk_in1_0_1;
  wire clk_wiz_0_clk_out1;
  wire clk_wiz_0_locked;
  wire [7:0]cpu_mode_dout;
  wire [1:0]mode_dout;
  wire [0:0]proc_sys_reset_0_peripheral_reset;
  wire reset_0_1;
  wire [1:0]sens_sel_dout;
  wire [15:0]test_signal_generator_0_sample_out;
  wire [3:0]vga_display_0_b;
  wire [3:0]vga_display_0_g;
  wire vga_display_0_hsync;
  wire [3:0]vga_display_0_r;
  wire vga_display_0_vsync;

  assign clk_in1_0_1 = sys_clk;
  assign reset_0_1 = rst;
  assign vga_b[3:0] = vga_display_0_b;
  assign vga_g[3:0] = vga_display_0_g;
  assign vga_hsync = vga_display_0_hsync;
  assign vga_r[3:0] = vga_display_0_r;
  assign vga_vsync = vga_display_0_vsync;
  design_1_xlconstant_0_2 band_sel
       (.dout(band_sel_dout));
  design_1_brainwave_recognizer_0_0 brainwave_recognizer_0
       (.ap_clk(clk_wiz_0_clk_out1),
        .ap_rst(proc_sys_reset_0_peripheral_reset),
        .band_sel(band_sel_dout),
        .flag_out(brainwave_recognizer_0_flag_out),
        .sample(test_signal_generator_0_sample_out),
        .sens_sel(sens_sel_dout));
  design_1_clk_wiz_0_0 clk_wiz_0
       (.clk_in1(clk_in1_0_1),
        .clk_out1(clk_wiz_0_clk_out1),
        .locked(clk_wiz_0_locked),
        .reset(reset_0_1));
  design_1_xlconstant_0_1 cpu_mode
       (.dout(cpu_mode_dout));
  design_1_xlconstant_0_4 mode
       (.dout(mode_dout));
  design_1_proc_sys_reset_0_0 proc_sys_reset_0
       (.aux_reset_in(1'b1),
        .dcm_locked(clk_wiz_0_locked),
        .ext_reset_in(reset_0_1),
        .mb_debug_sys_rst(1'b0),
        .peripheral_reset(proc_sys_reset_0_peripheral_reset),
        .slowest_sync_clk(clk_wiz_0_clk_out1));
  design_1_xlconstant_0_3 sens_sel
       (.dout(sens_sel_dout));
  design_1_test_signal_generator_0_0 test_signal_generator_0
       (.clk(clk_wiz_0_clk_out1),
        .mode(mode_dout),
        .rst(proc_sys_reset_0_peripheral_reset),
        .sample_out(test_signal_generator_0_sample_out));
  design_1_vga_display_0_0 vga_display_0
       (.b(vga_display_0_b),
        .band_sel(band_sel_dout),
        .clk(clk_wiz_0_clk_out1),
        .cpu_mode(cpu_mode_dout),
        .g(vga_display_0_g),
        .hsync(vga_display_0_hsync),
        .r(vga_display_0_r),
        .rst(proc_sys_reset_0_peripheral_reset),
        .vsync(vga_display_0_vsync),
        .wave_detect(brainwave_recognizer_0_flag_out));
endmodule
