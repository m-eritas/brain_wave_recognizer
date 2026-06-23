library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_signal_generator is
    generic (
        -- Actual clock driving the module.
        CLK_HZ    : integer := 25000000;

        -- Logical EEG sample rate.
        SAMPLE_HZ : integer := 128
    );
    Port (
        clk: in  std_logic;
        rst: in  std_logic;

        -- 000 / others => silence
        -- 001 => Delta test, 2 Hz
        -- 010 => Theta test, 6 Hz
        -- 011 => Alpha test, 10 Hz
        -- 100 => Beta test, 20 Hz
        -- 101 => Gamma test, 40 Hz
        mode: in  std_logic_vector(2 downto 0);

        -- Q2.14 signed sample for the HLS brainwave_recognizer.
        sample_out: out std_logic_vector(15 downto 0);

        -- One-clock pulse when sample_out should be consumed by HLS.
        sample_valid: out std_logic
    );
end test_signal_generator;

architecture Behavioral of test_signal_generator is
    ---------------------
    -- Sine lookup table
    ---------------------
    -- 128 samples for one full sine cycle.
    -- Q2.14 signed integers, half-scale with amplitude 0.5 * 2^14 = 8192
    ----------------------
    constant LUT_SIZE : integer := 128;

    type sine_lut_t is array (0 to LUT_SIZE - 1) of signed(15 downto 0);

    constant SINE_LUT : sine_lut_t := (
        to_signed(     0, 16), to_signed(   402, 16), to_signed(   803, 16), to_signed(  1202, 16), to_signed(  1598, 16), to_signed(  1990, 16), to_signed(  2378, 16), to_signed(  2760, 16),
        to_signed(  3135, 16), to_signed(  3503, 16), to_signed(  3862, 16), to_signed(  4212, 16), to_signed(  4551, 16), to_signed(  4880, 16), to_signed(  5197, 16), to_signed(  5501, 16),
        to_signed(  5793, 16), to_signed(  6070, 16), to_signed(  6333, 16), to_signed(  6580, 16), to_signed(  6811, 16), to_signed(  7027, 16), to_signed(  7225, 16), to_signed(  7405, 16),
        to_signed(  7568, 16), to_signed(  7713, 16), to_signed(  7839, 16), to_signed(  7946, 16), to_signed(  8035, 16), to_signed(  8103, 16), to_signed(  8153, 16), to_signed(  8182, 16),
        to_signed(  8192, 16), to_signed(  8182, 16), to_signed(  8153, 16), to_signed(  8103, 16), to_signed(  8035, 16), to_signed(  7946, 16), to_signed(  7839, 16), to_signed(  7713, 16),
        to_signed(  7568, 16), to_signed(  7405, 16), to_signed(  7225, 16), to_signed(  7027, 16), to_signed(  6811, 16), to_signed(  6580, 16), to_signed(  6333, 16), to_signed(  6070, 16),
        to_signed(  5793, 16), to_signed(  5501, 16), to_signed(  5197, 16), to_signed(  4880, 16), to_signed(  4551, 16), to_signed(  4212, 16), to_signed(  3862, 16), to_signed(  3503, 16),
        to_signed(  3135, 16), to_signed(  2760, 16), to_signed(  2378, 16), to_signed(  1990, 16), to_signed(  1598, 16), to_signed(  1202, 16), to_signed(   803, 16), to_signed(   402, 16),
        to_signed(     0, 16), to_signed(  -402, 16), to_signed(  -803, 16), to_signed( -1202, 16), to_signed( -1598, 16), to_signed( -1990, 16), to_signed( -2378, 16), to_signed( -2760, 16),
        to_signed( -3135, 16), to_signed( -3503, 16), to_signed( -3862, 16), to_signed( -4212, 16), to_signed( -4551, 16), to_signed( -4880, 16), to_signed( -5197, 16), to_signed( -5501, 16),
        to_signed( -5793, 16), to_signed( -6070, 16), to_signed( -6333, 16), to_signed( -6580, 16), to_signed( -6811, 16), to_signed( -7027, 16), to_signed( -7225, 16), to_signed( -7405, 16),
        to_signed( -7568, 16), to_signed( -7713, 16), to_signed( -7839, 16), to_signed( -7946, 16), to_signed( -8035, 16), to_signed( -8103, 16), to_signed( -8153, 16), to_signed( -8182, 16),
        to_signed( -8192, 16), to_signed( -8182, 16), to_signed( -8153, 16), to_signed( -8103, 16), to_signed( -8035, 16), to_signed( -7946, 16), to_signed( -7839, 16), to_signed( -7713, 16),
        to_signed( -7568, 16), to_signed( -7405, 16), to_signed( -7225, 16), to_signed( -7027, 16), to_signed( -6811, 16), to_signed( -6580, 16), to_signed( -6333, 16), to_signed( -6070, 16),
        to_signed( -5793, 16), to_signed( -5501, 16), to_signed( -5197, 16), to_signed( -4880, 16), to_signed( -4551, 16), to_signed( -4212, 16), to_signed( -3862, 16), to_signed( -3503, 16),
        to_signed( -3135, 16), to_signed( -2760, 16), to_signed( -2378, 16), to_signed( -1990, 16), to_signed( -1598, 16), to_signed( -1202, 16), to_signed(  -803, 16), to_signed(  -402, 16)
    );

    ---------------------
    -- 128 Hz sample-valid generator
    ---------------------
    -- When the accumulator crosses CLK_HZ:
    --   generate one sample_valid pulse
    --   subtract CLK_HZ
    ---------------------
    signal tick_acc         : integer range 0 to CLK_HZ - 1 := 0;
    signal sample_valid_reg : std_logic := '0';

    ---------------------
    -- Sine phase state
    ---------------------
    signal phase_index : unsigned(6 downto 0) := (others => '0');
    signal phase_step  : unsigned(6 downto 0) := (others => '0');
    signal sample_sine : signed(15 downto 0) := (others => '0');

begin
    process(mode)
    begin
        case mode is
            when "001" => phase_step <= to_unsigned(2, 7);   -- Delta, 2 Hz
            when "010" => phase_step <= to_unsigned(6, 7);   -- Theta, 6 Hz
            when "011" => phase_step <= to_unsigned(10, 7);  -- Alpha, 10 Hz
            when "100" => phase_step <= to_unsigned(20, 7);  -- Beta, 20 Hz
            when "101" => phase_step <= to_unsigned(40, 7);  -- Gamma, 40 Hz
            when others => phase_step <= to_unsigned(0, 7);  -- Silence
        end case;
    end process;
    
    process(mode, phase_index)
    begin
        if mode = "000" or mode = "110" or mode = "111" then
            sample_sine <= (others => '0');
        else
            sample_sine <= SINE_LUT(to_integer(phase_index));
        end if;
    end process;

    --------------------------------------------------------------------
    -- Sample-valid pulse and phase update.
    --------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                tick_acc         <= 0;
                sample_valid_reg <= '0';
                phase_index      <= (others => '0');
            else
                sample_valid_reg <= '0';

                if tick_acc >= CLK_HZ - SAMPLE_HZ then
                    tick_acc <= tick_acc - (CLK_HZ - SAMPLE_HZ);

                    -- One-clock pulse.
                    sample_valid_reg <= '1';

                    -- Advance phase once per logical EEG sample.
                    phase_index <= phase_index + phase_step;
                else
                    tick_acc <= tick_acc + SAMPLE_HZ;
                end if;
            end if;
        end if;
    end process;

    sample_out   <= std_logic_vector(sample_sine);
    sample_valid <= sample_valid_reg;

end Behavioral;