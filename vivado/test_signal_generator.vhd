library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity test_signal_generator is
    Port (
        clk        : in  std_logic;
        rst        : in  std_logic;

        -- 00 = silence
        -- 01 = alpha-like 10 Hz signal
        -- 10 = beta-like 20 Hz signal
        -- 11 = silence
        mode       : in  std_logic_vector(1 downto 0);

        -- Q2.14 signed sample for the HLS brainwave_recognizer
        sample_out : out std_logic_vector(15 downto 0)
    );
end test_signal_generator;

architecture Behavioral of test_signal_generator is

    --------------------------------------------------------------------
    -- These LUTs are Q2.14 signed samples.
    --
    -- Logical sampling rate assumption: Fs = 128 Hz.
    --
    -- 64-sample alpha LUT:
    --   5 cycles in 64 samples = 10 Hz at Fs = 128 Hz.
    --
    -- 64-sample beta LUT:
    --   10 cycles in 64 samples = 20 Hz at Fs = 128 Hz.
    --
    -- Amplitude is half-scale:
    --   0.5 * 2^14 = 8192.
    --------------------------------------------------------------------

    type sample_lut_t is array (0 to 63) of signed(15 downto 0);

    constant ALPHA_LUT : sample_lut_t := (
        to_signed(     0, 16),
        to_signed(  3862, 16),
        to_signed(  6811, 16),
        to_signed(  8153, 16),
        to_signed(  7568, 16),
        to_signed(  5197, 16),
        to_signed(  1598, 16),
        to_signed( -2378, 16),
        to_signed( -5793, 16),
        to_signed( -7839, 16),
        to_signed( -8035, 16),
        to_signed( -6333, 16),
        to_signed( -3135, 16),
        to_signed(   803, 16),
        to_signed(  4551, 16),
        to_signed(  7225, 16),
        to_signed(  8192, 16),
        to_signed(  7225, 16),
        to_signed(  4551, 16),
        to_signed(   803, 16),
        to_signed( -3135, 16),
        to_signed( -6333, 16),
        to_signed( -8035, 16),
        to_signed( -7839, 16),
        to_signed( -5793, 16),
        to_signed( -2378, 16),
        to_signed(  1598, 16),
        to_signed(  5197, 16),
        to_signed(  7568, 16),
        to_signed(  8153, 16),
        to_signed(  6811, 16),
        to_signed(  3862, 16),
        to_signed(     0, 16),
        to_signed( -3862, 16),
        to_signed( -6811, 16),
        to_signed( -8153, 16),
        to_signed( -7568, 16),
        to_signed( -5197, 16),
        to_signed( -1598, 16),
        to_signed(  2378, 16),
        to_signed(  5793, 16),
        to_signed(  7839, 16),
        to_signed(  8035, 16),
        to_signed(  6333, 16),
        to_signed(  3135, 16),
        to_signed(  -803, 16),
        to_signed( -4551, 16),
        to_signed( -7225, 16),
        to_signed( -8192, 16),
        to_signed( -7225, 16),
        to_signed( -4551, 16),
        to_signed(  -803, 16),
        to_signed(  3135, 16),
        to_signed(  6333, 16),
        to_signed(  8035, 16),
        to_signed(  7839, 16),
        to_signed(  5793, 16),
        to_signed(  2378, 16),
        to_signed( -1598, 16),
        to_signed( -5197, 16),
        to_signed( -7568, 16),
        to_signed( -8153, 16),
        to_signed( -6811, 16),
        to_signed( -3862, 16)
    );

    constant BETA_LUT : sample_lut_t := (
        to_signed(     0, 16),
        to_signed(  6811, 16),
        to_signed(  7568, 16),
        to_signed(  1598, 16),
        to_signed( -5793, 16),
        to_signed( -8035, 16),
        to_signed( -3135, 16),
        to_signed(  4551, 16),
        to_signed(  8192, 16),
        to_signed(  4551, 16),
        to_signed( -3135, 16),
        to_signed( -8035, 16),
        to_signed( -5793, 16),
        to_signed(  1598, 16),
        to_signed(  7568, 16),
        to_signed(  6811, 16),
        to_signed(     0, 16),
        to_signed( -6811, 16),
        to_signed( -7568, 16),
        to_signed( -1598, 16),
        to_signed(  5793, 16),
        to_signed(  8035, 16),
        to_signed(  3135, 16),
        to_signed( -4551, 16),
        to_signed( -8192, 16),
        to_signed( -4551, 16),
        to_signed(  3135, 16),
        to_signed(  8035, 16),
        to_signed(  5793, 16),
        to_signed( -1598, 16),
        to_signed( -7568, 16),
        to_signed( -6811, 16),
        to_signed(     0, 16),
        to_signed(  6811, 16),
        to_signed(  7568, 16),
        to_signed(  1598, 16),
        to_signed( -5793, 16),
        to_signed( -8035, 16),
        to_signed( -3135, 16),
        to_signed(  4551, 16),
        to_signed(  8192, 16),
        to_signed(  4551, 16),
        to_signed( -3135, 16),
        to_signed( -8035, 16),
        to_signed( -5793, 16),
        to_signed(  1598, 16),
        to_signed(  7568, 16),
        to_signed(  6811, 16),
        to_signed(     0, 16),
        to_signed( -6811, 16),
        to_signed( -7568, 16),
        to_signed( -1598, 16),
        to_signed(  5793, 16),
        to_signed(  8035, 16),
        to_signed(  3135, 16),
        to_signed( -4551, 16),
        to_signed( -8192, 16),
        to_signed( -4551, 16),
        to_signed(  3135, 16),
        to_signed(  8035, 16),
        to_signed(  5793, 16),
        to_signed( -1598, 16),
        to_signed( -7568, 16),
        to_signed( -6811, 16)
    );

    signal lut_index  : unsigned(5 downto 0) := (others => '0');
    signal sample_reg : signed(15 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                lut_index  <= (others => '0');
                sample_reg <= (others => '0');
            else
                lut_index <= lut_index + 1;

                case mode is
                    when "00" =>
                        sample_reg <= (others => '0');

                    when "01" =>
                        sample_reg <= ALPHA_LUT(to_integer(lut_index));

                    when "10" =>
                        sample_reg <= BETA_LUT(to_integer(lut_index));

                    when others =>
                        sample_reg <= (others => '0');
                end case;
            end if;
        end if;
    end process;

    sample_out <= std_logic_vector(sample_reg);

end Behavioral;