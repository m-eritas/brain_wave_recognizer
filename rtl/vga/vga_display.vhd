library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_display is
    Port (
        clk: in std_logic; --25 MHz pixel clock
        rst: in std_logic;

        wave_detect: in std_logic; -- from HLS flag_out
        band_sel: in std_logic_vector(2 downto 0); -- 0-4: Delta, Theta, Alpha, Beta, Gamma

        sample_in: in std_logic_vector(15 downto 0); -- raw/synthetic Q2.14 sample
        sample_valid: in std_logic; -- one-clock pulse at 128 Hz

        env_in: in std_logic_vector(17 downto 0); -- HLS envelope output
        threshold_in: in std_logic_vector(17 downto 0); -- HLS threshold output

        hsync: out std_logic;
        vsync: out std_logic;
        r: out std_logic_vector(3 downto 0);
        g: out std_logic_vector(3 downto 0);
        b: out std_logic_vector(3 downto 0)
    );
end vga_display;

architecture Behavioral of vga_display is

    ---------------------
    -- VGA 640x480 @ 60 Hz timing, using 25 MHz pixel clock
    ---------------------
    constant H_VISIBLE: integer := 640;
    constant H_SYNC_START: integer := 656;
    constant H_SYNC_END: integer := 752;
    constant H_TOTAL: integer := 800;

    constant V_VISIBLE: integer := 480;
    constant V_SYNC_START: integer := 490;
    constant V_SYNC_END: integer := 492;
    constant V_TOTAL: integer := 525;

    ---------------------
    -- Dashboard layout
    ---------------------
    constant STATUS_TOP: integer := 0;
    constant STATUS_BOTTOM: integer := 39;

    constant BAR_X_LEFT: integer := 45;
    constant BAR_X_RIGHT: integer := 65;
    constant BAR_BOX_LEFT: integer := 30;
    constant BAR_BOX_RIGHT: integer := 90;
    constant BAR_TOP: integer := 70;
    constant BAR_BOTTOM: integer := 220;
    constant BAR_HEIGHT: integer := BAR_BOTTOM - BAR_TOP;

    constant WAVE_TOP: integer := 280;
    constant WAVE_BOTTOM: integer := 439;
    constant WAVE_HEIGHT: integer := WAVE_BOTTOM - WAVE_TOP + 1;

    -- Display scaling for env/threshold.
    constant ENV_DISPLAY_MAX: integer := 65535;

    ---------------------
    -- VGA counters
    ---------------------
    signal h_count: unsigned(9 downto 0) := (others => '0');
    signal v_count: unsigned(9 downto 0) := (others => '0');
    signal video_on: std_logic := '0';

    ---------------------
    -- Waveform buffer output
    ---------------------
    signal wave_y: std_logic_vector(8 downto 0);

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

    function abs_int(
        value_in: integer
    ) return integer is
    begin
        if value_in < 0 then
            return -value_in;
        else
            return value_in;
        end if;
    end function;

    function env_to_y(
        value_vec: std_logic_vector(17 downto 0)
    ) return integer is
        variable value_i: integer;
        variable height_i: integer;
        variable y_i: integer;
    begin
        value_i := to_integer(unsigned(value_vec));
        value_i := clamp_int(value_i, 0, ENV_DISPLAY_MAX);

        height_i := (value_i * BAR_HEIGHT) / ENV_DISPLAY_MAX;
        y_i := BAR_BOTTOM - height_i;

        return clamp_int(y_i, BAR_TOP, BAR_BOTTOM);
    end function;

begin

    ---------------------
    -- Waveform history buffer
    ---------------------
    waveform_buffer_inst: entity work.waveform_buffer
        generic map (
            WIDTH => 640,
            PLOT_TOP => WAVE_TOP,
            PLOT_HEIGHT => WAVE_HEIGHT,
            SAMPLE_SCALE_DIV => 256
        )
        port map (
            clk => clk,
            rst => rst,
            sample_in => sample_in,
            sample_valid => sample_valid,
            display_x => std_logic_vector(h_count),
            wave_y => wave_y
        );

    ---------------------
    -- Horizontal and vertical pixel counters
    ---------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                h_count <= (others => '0');
                v_count <= (others => '0');

            elsif h_count = to_unsigned(H_TOTAL - 1, h_count'length) then
                h_count <= (others => '0');

                if v_count = to_unsigned(V_TOTAL - 1, v_count'length) then
                    v_count <= (others => '0');
                else
                    v_count <= v_count + 1;
                end if;

            else
                h_count <= h_count + 1;
            end if;
        end if;
    end process;

    ---------------------
    -- VGA sync signals
    ---------------------
    hsync <= '0' when (
        h_count >= to_unsigned(H_SYNC_START, h_count'length) and h_count < to_unsigned(H_SYNC_END, h_count'length)
    ) else '1';

    vsync <= '0' when (
        v_count >= to_unsigned(V_SYNC_START, v_count'length) and v_count < to_unsigned(V_SYNC_END, v_count'length)
    ) else '1';

    ---------------------
    -- Visible area.
    ---------------------
    video_on <= '1' when (
        h_count < to_unsigned(H_VISIBLE, h_count'length) and v_count < to_unsigned(V_VISIBLE, v_count'length)
    ) else '0';

    ---------------------
    -- Pixel drawing.
    ---------------------
    process(video_on, h_count, v_count, wave_detect, band_sel, env_in, threshold_in, wave_y)
        variable x_i: integer;
        variable y_i: integer;
        variable wave_y_i: integer;
        variable env_y_i: integer;
        variable threshold_y_i: integer;
    begin
        x_i := to_integer(h_count);
        y_i := to_integer(v_count);

        wave_y_i := to_integer(unsigned(wave_y));
        env_y_i := env_to_y(env_in);
        threshold_y_i := env_to_y(threshold_in);

        -- Default: black.
        r <= "0000"; g <= "0000"; b <= "0000";

        if video_on = '1' then
            r <= "0000"; g <= "0001"; b <= "0001";
            ---------------------
            -- Top status banner.
            ---------------------
            if y_i >= STATUS_TOP and y_i <= STATUS_BOTTOM then

                if wave_detect = '1' then
                    -- detection color depends on selected EEG band.
                    case band_sel is
                        when "000" =>  -- Delta: blue
                            r <= "0000"; g <= "0000"; b <= "1111";

                        when "001" =>  -- Theta: cyan
                            r <= "0000"; g <= "1111"; b <= "1111";

                        when "010" =>  -- Alpha: green
                            r <= "0000"; g <= "1111"; b <= "0000";

                        when "011" =>  -- Beta: orange/red
                            r <= "1111"; g <= "0100"; b <= "0000";

                        when "100" =>  -- Gamma: magenta
                            r <= "1111"; g <= "0000"; b <= "1111";

                        when others =>
                            r <= "1111"; g <= "1111"; b <= "1111";
                    end case;
                else
                    -- Idle banner.
                    r <= "0000"; g <= "0011"; b <= "0000";
                end if;
            end if;

            ---------------------
            -- Envelope bar box border.
            ---------------------
            if (
                (x_i >= BAR_BOX_LEFT and x_i <= BAR_BOX_RIGHT and (y_i = BAR_TOP or y_i = BAR_BOTTOM)) or
                (y_i >= BAR_TOP and y_i <= BAR_BOTTOM and (x_i = BAR_BOX_LEFT or x_i = BAR_BOX_RIGHT))
            ) then
                r <= "0100"; g <= "0100"; b <= "0100";
            end if;

            ---------------------
            -- Envelope bar fill.
            ---------------------
            if (
                x_i >= BAR_X_LEFT and x_i <= BAR_X_RIGHT and y_i >= env_y_i and y_i <= BAR_BOTTOM
            ) then
                r <= "0000"; g <= "1111"; b <= "1000";
            end if;

            ---------------------
            -- Threshold marker line.
            ---------------------
            if (
                x_i >= BAR_BOX_LEFT + 3 and x_i <= BAR_BOX_RIGHT - 3 and abs_int(y_i - threshold_y_i) <= 1
            ) then
                r <= "1111"; g <= "0000"; b <= "0000";
            end if;

            ---------------------
            -- Waveform plot border.
            ---------------------
            if (
                (x_i >= 0 and x_i <= H_VISIBLE - 1 and (y_i = WAVE_TOP or y_i = WAVE_BOTTOM)) or
                (y_i >= WAVE_TOP and y_i <= WAVE_BOTTOM and (x_i = 0 or x_i = H_VISIBLE - 1))
            ) then
                r <= "0100"; g <= "0100"; b <= "0100";
            end if;

            ---------------------
            -- Waveform line.
            ---------------------
            if (
                y_i >= WAVE_TOP and y_i <= WAVE_BOTTOM and
                abs_int(y_i - wave_y_i) <= 1
            ) then
                r <= "1111"; g <= "1111"; b <= "1111";
            end if;
        end if;
    end process;
end Behavioral;
