library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm_audio is
    generic (
        CLK_HZ: integer := 25000000;
        PWM_BITS: integer := 8
    );
    port (
        clk: in std_logic;
        rst: in std_logic;

        wave_detect: in std_logic;
        band_sel: in std_logic_vector(2 downto 0);

        audio_pwm: out std_logic
    );
end pwm_audio;

architecture Behavioral of pwm_audio is

    constant PWM_LEVELS: integer := 2 ** PWM_BITS;

    -- Tone half-periods in clock cycles.
    -- Frequency = CLK_HZ / (2 * HALF_PERIOD)
    constant DELTA_HALF: integer := CLK_HZ / (2 * 262);
    constant THETA_HALF: integer := CLK_HZ / (2 * 330);
    constant ALPHA_HALF: integer := CLK_HZ / (2 * 440);
    constant BETA_HALF: integer := CLK_HZ / (2 * 660);
    constant GAMMA_HALF: integer := CLK_HZ / (2 * 880);

    signal tone_half_period: integer range 1 to CLK_HZ := ALPHA_HALF;
    signal tone_counter: integer range 0 to CLK_HZ := 0;
    signal tone_square: std_logic := '0';

    signal pwm_counter: unsigned(PWM_BITS - 1 downto 0) := (others => '0');
    signal duty: unsigned(PWM_BITS - 1 downto 0) := (others => '0');

begin

    ---------------------
    -- Select audible tone by detected band.
    ---------------------
    process(band_sel)
    begin
        case band_sel is
            when "000" => tone_half_period <= DELTA_HALF;
            when "001" => tone_half_period <= THETA_HALF;
            when "010" => tone_half_period <= ALPHA_HALF;
            when "011" => tone_half_period <= BETA_HALF;
            when "100" => tone_half_period <= GAMMA_HALF;
            when others => tone_half_period <= ALPHA_HALF;
        end case;
    end process;

    ---------------------
    -- Audio tone generator.
    ---------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                tone_counter <= 0;
                tone_square <= '0';

            elsif wave_detect = '0' then
                tone_counter <= 0;
                tone_square <= '0';

            else
                if tone_counter >= tone_half_period - 1 then
                    tone_counter <= 0;
                    tone_square <= not tone_square;
                else
                    tone_counter <= tone_counter + 1;
                end if;
            end if;
        end if;
    end process;

    ---------------------
    -- PWM carrier.
    ---------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                pwm_counter <= (others => '0');
            else
                pwm_counter <= pwm_counter + 1;
            end if;
        end if;
    end process;

    ---------------------
    -- Duty-cycle modulation.
    ---------------------
    process(wave_detect, tone_square)
    begin
        if wave_detect = '0' then
            duty <= to_unsigned(0, PWM_BITS);
        elsif tone_square = '1' then
            duty <= to_unsigned((3 * PWM_LEVELS) / 4, PWM_BITS);
        else
            duty <= to_unsigned(PWM_LEVELS / 4, PWM_BITS);
        end if;
    end process;

    audio_pwm <= '1' when pwm_counter < duty else '0';

end Behavioral;