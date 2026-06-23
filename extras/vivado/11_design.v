//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.1.2 (win64) Build 5164865 Thu Sep  5 14:37:11 MDT 2024
//Date        : Wed Jun 24 00:11:56 2026
//Host        : MSI running 64-bit major release  (build 9200)
//Command     : generate_target design_1.bd
//Design      : design_1
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CORE_GENERATION_INFO = "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=design_1,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=9,numReposBlks=9,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=1,numHdlrefBlks=3,numPkgbdBlks=0,bdsource=USER,synth_mode=Hierarchical}" *) (* HW_HANDOFF = "design_1.hwdef" *) 
module design_1
   (audio_pwm,
    rst,
    sys_clk,
    vga_b,
    vga_g,
    vga_hsync,
    vga_r,
    vga_vsync);
  output audio_pwm;
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 RST.RST RST" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME RST.RST, INSERT_VIP 0, POLARITY ACTIVE_HIGH" *) input rst;
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 CLK.SYS_CLK CLK" *) (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME CLK.SYS_CLK, CLK_DOMAIN design_1_clk_in1_0, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, INSERT_VIP 0, PHASE 0.0" *) input sys_clk;
  output [3:0]vga_b;
  output [3:0]vga_g;
  output vga_hsync;
  output [3:0]vga_r;
  output vga_vsync;

  wire [2:0]band_sel_dout;
  wire [17:0]brainwave_recognizer_env_out;
  wire brainwave_recognizer_flag_out;
  wire [17:0]brainwave_recognizer_threshold_out;
  wire clk_in1_0_1;
  wire clk_wiz_clk_out1;
  wire clk_wiz_locked;
  wire [2:0]mode_dout;
  wire [0:0]proc_sys_reset_0_peripheral_reset;
  wire pwm_audio_audio_pwm;
  wire rst_1;
  wire [15:0]test_signal_generator_sample_out;
  wire test_signal_generator_sample_valid;
  wire [1:0]threshold_sel_dout;
  wire [3:0]vga_display_b;
  wire [3:0]vga_display_g;
  wire vga_display_hsync;
  wire [3:0]vga_display_r;
  wire vga_display_vsync;

  assign audio_pwm = pwm_audio_audio_pwm;
  assign clk_in1_0_1 = sys_clk;
  assign rst_1 = rst;
  assign vga_b[3:0] = vga_display_b;
  assign vga_g[3:0] = vga_display_g;
  assign vga_hsync = vga_display_hsync;
  assign vga_r[3:0] = vga_display_r;
  assign vga_vsync = vga_display_vsync;
  design_1_xlconstant_1_0 band_sel
       (.dout(band_sel_dout));
  design_1_brainwave_recognizer_0_0 brainwave_recognizer
       (.ap_clk(clk_wiz_clk_out1),
        .ap_rst(proc_sys_reset_0_peripheral_reset),
        .band_sel(band_sel_dout),
        .env_out(brainwave_recognizer_env_out),
        .flag_out(brainwave_recognizer_flag_out),
        .sample(test_signal_generator_sample_out),
        .sample_valid(test_signal_generator_sample_valid),
        .threshold_out(brainwave_recognizer_threshold_out),
        .threshold_sel(threshold_sel_dout));
  design_1_clk_wiz_0_0 clk_wiz
       (.clk_in1(clk_in1_0_1),
        .clk_out1(clk_wiz_clk_out1),
        .locked(clk_wiz_locked),
        .reset(1'b0));
  design_1_xlconstant_0_0 mode
       (.dout(mode_dout));
  design_1_proc_sys_reset_0_0 proc_sys_reset_0
       (.aux_reset_in(1'b1),
        .dcm_locked(clk_wiz_locked),
        .ext_reset_in(rst_1),
        .mb_debug_sys_rst(1'b0),
        .peripheral_reset(proc_sys_reset_0_peripheral_reset),
        .slowest_sync_clk(clk_wiz_clk_out1));
  design_1_pwm_audio_0_0 pwm_audio
       (.audio_pwm(pwm_audio_audio_pwm),
        .band_sel(band_sel_dout),
        .clk(clk_wiz_clk_out1),
        .rst(proc_sys_reset_0_peripheral_reset),
        .wave_detect(brainwave_recognizer_flag_out));
  design_1_test_signal_generator_0_0 test_signal_generator
       (.clk(clk_wiz_clk_out1),
        .mode(mode_dout),
        .rst(proc_sys_reset_0_peripheral_reset),
        .sample_out(test_signal_generator_sample_out),
        .sample_valid(test_signal_generator_sample_valid));
  design_1_xlconstant_2_0 threshold_sel
       (.dout(threshold_sel_dout));
  design_1_vga_display_0_0 vga_display
       (.b(vga_display_b),
        .band_sel(band_sel_dout),
        .clk(clk_wiz_clk_out1),
        .env_in(brainwave_recognizer_env_out),
        .g(vga_display_g),
        .hsync(vga_display_hsync),
        .r(vga_display_r),
        .rst(proc_sys_reset_0_peripheral_reset),
        .sample_in(test_signal_generator_sample_out),
        .sample_valid(test_signal_generator_sample_valid),
        .threshold_in(brainwave_recognizer_threshold_out),
        .vsync(vga_display_vsync),
        .wave_detect(brainwave_recognizer_flag_out));
endmodule
