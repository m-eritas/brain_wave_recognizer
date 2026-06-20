library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.env.all;

entity tb_test_signal_generator is
end tb_test_signal_generator;

architecture sim of tb_test_signal_generator is

    ---------------------
    -- Testbench checks the real 25 MHz / 128 Hz timing.
    ---------------------
    constant CLK_HZ_TB    : integer := 25000000;
    constant SAMPLE_HZ_TB : integer := 128;
    constant CLK_PERIOD : time := 40 ns;

    -- 25,000,000 / 128 = 195,312.5
    constant FIRST_VALID_CYCLES  : natural := 195313;
    constant SECOND_VALID_CYCLES : natural := 195312;
    constant THIRD_VALID_CYCLES  : natural := 195313;

    signal clk          : std_logic := '0';
    signal rst          : std_logic := '1';
    signal mode         : std_logic_vector(2 downto 0) := "011"; -- alpha
    signal sample_out   : std_logic_vector(15 downto 0);
    signal sample_valid : std_logic;

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

    procedure wait_for_valid(
        signal clk_sig   : in std_logic;
        signal valid_sig : in std_logic;
        constant max_cycles : in natural;
        variable cycles_out : out natural
    ) is
        variable c : natural := 0;
    begin
        loop
            wait until rising_edge(clk_sig);
            wait for 1 ns;
            c := c + 1;

            if valid_sig = '1' then
                cycles_out := c;
                return;
            end if;

            assert c < max_cycles
                report "sample_valid did not pulse within " & natural'image(max_cycles) & " cycles"
                severity failure;
        end loop;
    end procedure;

begin

    -- DUT
    dut : entity work.test_signal_generator
        generic map (
            CLK_HZ    => CLK_HZ_TB,
            SAMPLE_HZ => SAMPLE_HZ_TB
        )
        port map (
            clk          => clk,
            rst          => rst,
            mode         => mode,
            sample_out   => sample_out,
            sample_valid => sample_valid
        );

    -- Clock generation
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Main test
    stim_process : process
        variable cycles      : natural := 0;
        variable first_sample : std_logic_vector(15 downto 0);
        variable second_sample: std_logic_vector(15 downto 0);
    begin
        rst  <= '1';
        mode <= "011"; -- alpha, phase_step = 10
        wait_clocks(clk, 5);

        rst <= '0';
        wait for 1 ns;

        -- 1 sample_valid pulse
        wait_for_valid(clk, sample_valid, FIRST_VALID_CYCLES + 10, cycles);

        assert cycles = FIRST_VALID_CYCLES
            report "Wrong first sample_valid timing: got " & natural'image(cycles) &
                   ", expected " & natural'image(FIRST_VALID_CYCLES)
            severity error;

        assert sample_out /= x"0000"
            report "Alpha mode produced zero sample at first valid pulse"
            severity error;

        first_sample := sample_out;

        -- 2 sample_valid pulse
        wait_for_valid(clk, sample_valid, SECOND_VALID_CYCLES + 10, cycles);

        assert cycles = SECOND_VALID_CYCLES
            report "Wrong second sample_valid timing: got " & natural'image(cycles) &
                   ", expected " & natural'image(SECOND_VALID_CYCLES)
            severity error;

        assert sample_out /= first_sample
            report "sample_out did not change between alpha valid pulses"
            severity error;

        second_sample := sample_out;

        -- 3 sample_valid pulse
        wait_for_valid(clk, sample_valid, THIRD_VALID_CYCLES + 10, cycles);

        assert cycles = THIRD_VALID_CYCLES
            report "Wrong third sample_valid timing: got " & natural'image(cycles) &
                   ", expected " & natural'image(THIRD_VALID_CYCLES)
            severity error;

        assert sample_out /= second_sample
            report "sample_out did not change at third alpha valid pulse"
            severity error;

        -- Silence mode must force sample_out to zero.
        mode <= "000";
        wait for 1 ns;

        assert sample_out = x"0000"
            report "Silence mode did not force sample_out to zero"
            severity error;

        report "tb_test_signal_generator passed: 25 MHz / 128 Hz timing and mode behavior are OK."
            severity note;

        finish;
    end process;
end sim;
