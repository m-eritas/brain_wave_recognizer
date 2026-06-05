library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.env.all;

entity tb_vga_display is
end tb_vga_display;

architecture sim of tb_vga_display is
    --------------------------------------------------------------------
    -- VGA 640x480 @ 60 Hz uses ~25 MHz pixel clock.
    -- 25 MHz period = 40 ns.
    --------------------------------------------------------------------
    constant CLK_PERIOD: time    := 40 ns;
    constant H_SYNC_WIDTH: integer := 96;
    constant V_SYNC_WIDTH_CLK: integer := 1600; -- 2 lines * 800 clocks/line

    signal clk: std_logic := '0';
    signal rst: std_logic := '1';

    signal wave_detect: std_logic := '0';
    signal band_sel: std_logic_vector(2 downto 0) := "010"; -- Alpha
    signal cpu_mode: std_logic_vector(7 downto 0) := x"00"; -- Track A

    signal hsync: std_logic;
    signal vsync: std_logic;
    signal r: std_logic_vector(3 downto 0);
    signal g: std_logic_vector(3 downto 0);
    signal b: std_logic_vector(3 downto 0);

    --------------------------------------------------------------------
    -- Helper procedure: wait for N rising clock edges, then allow outputs
    -- to settle for a small delta of simulation time.
    --------------------------------------------------------------------
    procedure wait_clocks(
        signal clk_sig : in std_logic;
        constant n     : in natural
    ) is
    begin
        for i in 1 to n loop
            wait until rising_edge(clk_sig);
        end loop;
        wait for 1 ns;
    end procedure;

begin
    --------------------------------------------------------------------
    -- Device under test
    --------------------------------------------------------------------
    dut : entity work.vga_display
        port map (
            clk         => clk,
            rst         => rst,
            wave_detect => wave_detect,
            band_sel    => band_sel,
            cpu_mode    => cpu_mode,
            hsync       => hsync,
            vsync       => vsync,
            r           => r,
            g           => g,
            b           => b
        );

    --------------------------------------------------------------------
    -- 25 MHz clock generation
    --------------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    --------------------------------------------------------------------
    -- Main test process
    --------------------------------------------------------------------
    stim_process : process
        variable h_low_count : integer := 0;
        variable v_low_count : integer := 0;
    begin
        rst         <= '1';
        wave_detect <= '0';
        band_sel    <= "010"; -- Alpha
        cpu_mode    <= x"00";

        wait_clocks(clk, 5);

        rst <= '0';

        wait_clocks(clk, 2);

        ----------------------------------------------------------------
        -- Test 1: visible idle color (dim green)
        -- Expected from the minimal vga_display:
        ----------------------------------------------------------------
        assert (r = "0000" and g = "0010" and b = "0000")
            report "Idle visible RGB is wrong"
            severity error;

        ----------------------------------------------------------------
        -- Test 2: wave_detect changes visible colour (bright green for alpha)
        ----------------------------------------------------------------
        wave_detect <= '1';
        wait_clocks(clk, 2);

        assert (r = "0000" and g = "1111" and b = "0000")
            report "Detected alpha RGB is wrong"
            severity error;

        ----------------------------------------------------------------
        -- Test 3: hsync pulse width and horizontal blanking
        ----------------------------------------------------------------
        wait until falling_edge(hsync);
        wait for 1 ns;

        -- Horizontal blanking during hsync (RGB black even if wave detected)
        assert (r = "0000" and g = "0000" and b = "0000")
            report "RGB is not black during horizontal blanking"
            severity error;

        h_low_count := 0;

        while hsync = '0' loop
            h_low_count := h_low_count + 1;
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;

        assert h_low_count = H_SYNC_WIDTH
            report "Wrong hsync low width"
            severity error;

        ----------------------------------------------------------------
        -- Test 4: vsync pulse width and vertical blanking
        ----------------------------------------------------------------
        wait until falling_edge(vsync);
        wait for 1 ns;

        -- Vertical blanking during vsync (RGB black)
        assert (r = "0000" and g = "0000" and b = "0000")
            report "RGB is not black during vertical blanking"
            severity error;

        v_low_count := 0;

        while vsync = '0' loop
            v_low_count := v_low_count + 1;
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;

        assert v_low_count = V_SYNC_WIDTH_CLK
            report "Wrong vsync low width"
            severity error;

        ----------------------------------------------------------------
        -- Done
        ----------------------------------------------------------------
        report "tb_vga_display passed: timing, blanking, and colour checks are OK."
            severity note;

        finish;
    end process;
end sim;