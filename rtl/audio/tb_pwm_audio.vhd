library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_pwm_audio is
end tb_pwm_audio;

architecture sim of tb_pwm_audio is

    ---------------------
    -- Uses a lower simulated clock to keep simulation short.
    ---------------------
    constant CLK_HZ: integer := 1000000;
    constant PWM_BITS: integer := 8;
    constant CLK_PERIOD: time := 1 us;

    constant PWM_LEVELS: integer := 2 ** PWM_BITS;

    signal clk: std_logic := '0';
    signal rst: std_logic := '1';

    signal wave_detect: std_logic := '0';
    signal band_sel: std_logic_vector(2 downto 0) := "010";

    signal audio_pwm: std_logic;

    ---------------------
    -- Wait helper
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

    ---------------------
    -- Count how many cycles audio_pwm is high.
    ---------------------
    procedure count_high_cycles(
        signal clk_sig: in std_logic;
        signal pwm_sig: in std_logic;
        constant cycles: in natural;
        variable high_count: out integer
       ) is
    variable local_count: integer := 0;
    begin
        local_count := 0;

        for i in 1 to cycles loop
            wait until rising_edge(clk_sig);
            wait for 1 ns;

            if pwm_sig = '1' then
                local_count := local_count + 1;
            end if;
        end loop;

        high_count := local_count;
    end procedure;
    ---------------------
    -- Assert that PWM stays silent.
    ---------------------
    procedure expect_silent(
        signal clk_sig: in std_logic;
        signal pwm_sig: in std_logic;
        constant cycles: in natural
    ) is
        variable high_count: integer := 0;
    begin
        count_high_cycles(clk_sig, pwm_sig, cycles, high_count);

        assert high_count = 0
            report "audio_pwm was not silent when it should be silent"
            severity error;
    end procedure;

begin

    ---------------------
    -- DUT
    ---------------------
    dut : entity work.pwm_audio
        generic map (
            CLK_HZ => CLK_HZ,
            PWM_BITS => PWM_BITS
        )
        port map (
            clk => clk,
            rst => rst,
            wave_detect => wave_detect,
            band_sel => band_sel,
            audio_pwm => audio_pwm
        );

    ---------------------
    -- Clock generation
    ---------------------
    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    ---------------------
    -- Test process
    ---------------------
    stim_process: process

        procedure check_band_pwm(
            constant band_value: in integer;
            constant band_name: in string
        ) is
            variable frame_high: integer := 0;
            variable saw_low_duty: boolean := false;
            variable saw_high_duty: boolean := false;
        begin
            report "Testing PWM band: " & band_name severity note;

            wave_detect <= '0';
            band_sel <= std_logic_vector(to_unsigned(band_value, 3));

            wait_clocks(clk, 50);

            expect_silent(clk, audio_pwm, 512);

            wave_detect <= '1';

            for frame in 0 to 39 loop
                count_high_cycles(clk, audio_pwm, PWM_LEVELS, frame_high);

                if frame_high >= 50 and frame_high <= 80 then
                    saw_low_duty := true;
                end if;

                if frame_high >= 176 and frame_high <= 208 then
                    saw_high_duty := true;
                end if;
            end loop;

            assert saw_low_duty
                report "Did not observe low-duty PWM frame for band " & band_name
                severity error;

            assert saw_high_duty
                report "Did not observe high-duty PWM frame for band " & band_name
                severity error;

            ---------------------
            -- Disable detection again.
            -- Output must become silent.
            ---------------------
            wave_detect <= '0';

            wait_clocks(clk, 10);

            expect_silent(clk, audio_pwm, 512);

            report "PASS PWM band: " & band_name severity note;
        end procedure;

        variable high_count: integer := 0;

    begin

        ---------------------
        -- Reset
        ---------------------
        rst <= '1';
        wave_detect <= '0';
        band_sel <= "010";

        wait_clocks(clk, 10);

        rst <= '0';

        wait_clocks(clk, 10);

        ---------------------
        -- Test 1: silent when wave_detect = 0
        ---------------------
        report "TEST: silent when wave_detect=0" severity note;

        wave_detect <= '0';
        band_sel <= "010";

        expect_silent(clk, audio_pwm, 1024);

        report "PASS: silent when wave_detect=0" severity note;

        ---------------------
        -- Test 2: alpha active smoke test
        ---------------------
        report "TEST: alpha active PWM is not stuck" severity note;

        wave_detect <= '1';
        band_sel <= "010"; -- Alpha

        count_high_cycles(clk, audio_pwm, 4096, high_count);

        assert high_count > 0
            report "audio_pwm stayed low during alpha detection"
            severity error;

        assert high_count < 4096
            report "audio_pwm stayed high during alpha detection"
            severity error;

        report "PASS: alpha active PWM is not stuck" severity note;

        ---------------------
        -- Test 3: all valid bands produce PWM activity
        ---------------------
        check_band_pwm(0, "Delta");
        check_band_pwm(1, "Theta");
        check_band_pwm(2, "Alpha");
        check_band_pwm(3, "Beta");
        check_band_pwm(4, "Gamma");

        ---------------------
        -- Test 4: invalid band selector should still produce valid default tone
        -- In pwm_audio.vhd, others => ALPHA_HALF.
        ---------------------
        check_band_pwm(7, "Invalid selector defaults to Alpha tone");

        report "tb_pwm_audio passed." severity note;

        wait;
    end process;
end sim;
