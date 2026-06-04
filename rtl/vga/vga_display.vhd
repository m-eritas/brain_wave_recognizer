library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_display is
    Port (
        clk: in  std_logic;        -- pixel clock (e.g., 25 MHz)
        rst: in  std_logic;

        wave_detect: in std_logic;        -- from HLS flag_out
        band_sel: in  std_logic_vector(2 downto 0);      -- selected EEG band (delta to gamma)
        --cpu_mode: in  std_logic_vector(7 downto 0);  -- For later CPU implementation

        hsync: out std_logic;
        vsync: out std_logic;
        r: out std_logic_vector(3 downto 0);
        g: out std_logic_vector(3 downto 0);
        b: out std_logic_vector(3 downto 0)
    );
end vga_display;

architecture Behavioral of vga_display is
    -- Horizontal timing: 640 visible + 16 front porch + 96 sync + 48 back porch = 800
    constant H_VISIBLE: integer := 640;
    constant H_SYNC_START: integer := 656;
    constant H_SYNC_END: integer := 752;
    constant H_TOTAL: integer := 800;

    -- Vertical timing: 480 visible + 10 front porch + 2 sync + 33 back porch = 525
    constant V_VISIBLE: integer := 480;
    constant V_SYNC_START: integer := 490;
    constant V_SYNC_END: integer := 492;
    constant V_TOTAL: integer := 525;

    signal h_count: unsigned(9 downto 0) := (others => '0');
    signal v_count: unsigned(9 downto 0) := (others => '0');
    signal video_on: std_logic;
begin
    --------------------------------------------
    -- Horizontal and vertical pixel counters
    --------------------------------------------
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

    --------------------------------------------
    -- VGA sync generation
    -- Sync signals are active-low.
    --------------------------------------------
    hsync <= '0' when (
        h_count >= to_unsigned(H_SYNC_START, h_count'length) and
        h_count <  to_unsigned(H_SYNC_END,   h_count'length)
    ) else '1';

    vsync <= '0' when (
        v_count >= to_unsigned(V_SYNC_START, v_count'length) and
        v_count <  to_unsigned(V_SYNC_END,   v_count'length)
    ) else '1';

    --------------------------------------------
    -- Visible area flag
    --------------------------------------------
    video_on <= '1' when (
        h_count < to_unsigned(H_VISIBLE, h_count'length) and
        v_count < to_unsigned(V_VISIBLE, v_count'length)
    ) else '0';

    --------------------------------------------
    -- Pixel colour logic
    --   cpu_mode is tied to x"00".
    --   Screen is dim green when idle.
    --   Screen becomes bright band-color when wave_detect = '1'.
    --   (TODO) cpu_mode can override the display color.
    --------------------------------------------
    process(video_on, wave_detect, band_sel, cpu_mode)
    begin
        -- Default: black
        r <= "0000";
        g <= "0000";
        b <= "0000";

        if video_on = '1' then
            -- TODO CPU OVERIDE
            if cpu_mode /= x"00" then
                case cpu_mode(2 downto 0) is
                    when "001" =>  -- relaxed / alpha
                        r <= "0000";
                        g <= "1111";
                        b <= "0000";
                    when "010" =>  -- focused / beta
                        r <= "0000";
                        g <= "1000";
                        b <= "1111";
                    when "011" =>  -- drowsy / theta
                        r <= "1111";
                        g <= "1111";
                        b <= "0000";
                    when others =>
                        r <= "1111";
                        g <= "1111";
                        b <= "1111";
                end case;

            elsif wave_detect = '1' then
                -- Detection colour depends on selected EEG band.
                case band_sel is
                    when "000" =>  -- Delta
                        r <= "0000";
                        g <= "0000";
                        b <= "1111";
                    when "001" =>  -- Theta
                        r <= "0000";
                        g <= "1111";
                        b <= "1111";
                    when "010" =>  -- Alpha
                        r <= "0000";
                        g <= "1111";
                        b <= "0000";
                    when "011" =>  -- Beta
                        r <= "1111";
                        g <= "0100";
                        b <= "0000";
                    when "100" =>  -- Gamma
                        r <= "1111";
                        g <= "0000";
                        b <= "1111";
                    when others =>
                        r <= "1111";
                        g <= "1111";
                        b <= "1111";
                end case;
            else
                -- Idle visible screen: dim green.
                r <= "0000";
                g <= "0010";
                b <= "0000";
            end if;
        end if;
    end process;                              
end Behavioral;
