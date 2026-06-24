library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_vga_display is
end tb_vga_display;

architecture sim of tb_vga_display is

    ---------------------
    -- VGA 640x480 @ 60 Hz using 25 MHz pixel clock.
    ---------------------
    constant CLK_PERIOD: time := 40 ns;
    constant H_SYNC_WIDTH: integer := 96;
    constant V_SYNC_WIDTH_CLK: integer := 1600; -- 2 lines * 800 clocks/line

    ---------------------
    -- DUT signals
    ---------------------
    signal clk: std_logic := '0';
    signal rst: std_logic := '1';

    signal wave_detect: std_logic := '0';
    signal band_sel: std_logic_vector(2 downto 0) := "010"; -- Alpha

    signal sample_in: std_logic_vector(15 downto 0) := (others => '0');
    signal sample_valid: std_logic := '0';

    signal env_in: std_logic_vector(17 downto 0) := (others => '0');
    signal threshold_in: std_logic_vector(17 downto 0) := (others => '0');

    signal hsync: std_logic;
    signal vsync: std_logic;
    signal r: std_logic_vector(3 downto 0);
    signal g: std_logic_vector(3 downto 0);
    signal b: std_logic_vector(3 downto 0);

    ---------------------
    -- Helper procedure
    ---------------------
    procedure wait_clocks(
        signal clk_sig: in std_logic;
        constant n: in natural
    ) is
    begin
        for i in 1 to n loop
            wait until rising_edge(clk_sig);
        end loop;
        wait for 1 ns;
    end procedure;

begin
    ---------------------
    -- Device under test
    ---------------------
    dut : entity work.vga_display
        port map (
            clk => clk,
            rst => rst,

            wave_detect => wave_detect,
            band_sel => band_sel,

            sample_in => sample_in,
            sample_valid => sample_valid,

            env_in => env_in,
            threshold_in => threshold_in,

            hsync => hsync,
            vsync => vsync,
            r => r,
            g => g,
            b => b
        );

    ---------------------
    -- 25 MHz clock generation
    ---------------------
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    ---------------------
    -- Main test process
    ---------------------
    stim_process : process
        variable h_low_count: integer := 0;
        variable v_low_count: integer := 0;
    begin
        ---------------------
        -- Initial values
        ---------------------
        rst <= '1';
        wave_detect <= '0';
        band_sel <= "010"; -- Alpha

        sample_in <= (others => '0');
        sample_valid <= '0';

        -- nonzero values so the bar/threshold logic is active.
        env_in <= std_logic_vector(to_unsigned(45000, 18));
        threshold_in <= std_logic_vector(to_unsigned(23592, 18));

        wait_clocks(clk, 5);

        rst <= '0';

        wait_clocks(clk, 2);

        ---------------------
        -- Test 1: idle status banner colour
        ---------------------
        assert (r = "0000" and g = "0011" and b = "0000")
            report "Idle status banner RGB is wrong"
            severity error;

        ---------------------
        -- Test 2: alpha detection changes top banner colour
        ---------------------
        wave_detect <= '1';
        band_sel    <= "010"; -- Alpha

        wait_clocks(clk, 2);

        assert (r = "0000" and g = "1111" and b = "0000")
            report "Alpha detected banner RGB is wrong"
            severity error;

        ---------------------
        -- Test 3: hsync pulse width and horizontal blanking
        ---------------------
        wait until falling_edge(hsync);
        wait for 1 ns;

        -- During hsync, we are outside the visible region.
        -- RGB must be black.
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

        ---------------------
        -- Test 4: vsync pulse width and vertical blanking
        ---------------------
        wait until falling_edge(vsync);
        wait for 1 ns;

        -- During vsync, RGB must be black.
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

        report "tb_vga_display passed: interface, timing, blanking, and banner colour checks are OK."
            severity note;
        wait;
    end process;
end sim;
