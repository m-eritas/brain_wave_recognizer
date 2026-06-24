library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity waveform_buffer is
    generic (
        WIDTH: integer := 640;
        PLOT_TOP: integer := 280;
        PLOT_HEIGHT: integer := 160;
        SAMPLE_SCALE_DIV: integer := 256
    );
    Port (
        clk: in std_logic;
        rst: in std_logic;

        sample_in: in std_logic_vector(15 downto 0); -- signed Q2.14 sample
        sample_valid: in std_logic; -- one-clock valid pulse

        display_x: in std_logic_vector(9 downto 0); -- current VGA x position
        wave_y: out std_logic_vector(8 downto 0) -- screen y coordinate
    );
end waveform_buffer;

architecture Behavioral of waveform_buffer is
    subtype y_coord_t is unsigned(8 downto 0);
    type wave_mem_t is array (0 to WIDTH - 1) of y_coord_t;

    signal wave_mem: wave_mem_t := (others => to_unsigned(PLOT_TOP + PLOT_HEIGHT / 2, 9));
    signal write_index: integer range 0 to WIDTH - 1 := 0;

    function clamp_int(
        value_in: integer;
        min_in: integer;
        max_in: integer
    ) return integer is
    begin
        if value_in < min_in then
            return min_in;
        elsif value_in > max_in then
            return max_in;
        else
            return value_in;
        end if;
    end function;

    function sample_to_y(
        sample_vec: std_logic_vector(15 downto 0)
    ) return y_coord_t is
        variable sample_int: integer;
        variable center_y: integer;
        variable raw_y: integer;
        variable clamped_y: integer;
    begin
        sample_int := to_integer(signed(sample_vec));

        center_y := PLOT_TOP + (PLOT_HEIGHT / 2);

        -- Positive sample goes upward on the screen.
        -- Negative sample goes downward.
        raw_y := center_y - (sample_int / SAMPLE_SCALE_DIV);

        clamped_y := clamp_int(raw_y, PLOT_TOP, PLOT_TOP + PLOT_HEIGHT - 1);

        return to_unsigned(clamped_y, 9);
    end function;

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                write_index <= 0;
                wave_mem <= (others => to_unsigned(PLOT_TOP + PLOT_HEIGHT / 2, 9));

            elsif sample_valid = '1' then
                wave_mem(write_index) <= sample_to_y(sample_in);

                if write_index = WIDTH - 1 then
                    write_index <= 0;
                else
                    write_index <= write_index + 1;
                end if;
            end if;
        end if;
    end process;

    process(display_x, write_index, wave_mem)
        variable x_int: integer;
        variable read_idx: integer;
    begin
        x_int := to_integer(unsigned(display_x));

        if x_int < WIDTH then
            read_idx := write_index + x_int;

            if read_idx >= WIDTH then
                read_idx := read_idx - WIDTH;
            end if;

            wave_y <= std_logic_vector(wave_mem(read_idx));
        else
            wave_y <= std_logic_vector(to_unsigned(PLOT_TOP + PLOT_HEIGHT / 2, 9));
        end if;
    end process;
end Behavioral;
