library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_display is
    Port (
        clk         : in  std_logic;                     -- pixel clock (e.g., 25 MHz)
        rst         : in  std_logic;

        which_band  : in  std_logic_vector(2 downto 0);      -- 5 brainwave bands (delta to gamma)
        sensibility        : in  std_logic_vector(1 downto 0);      -- sensitivity level
        waveform_in : in  std_logic_vector(7 downto 0);      -- waveform amplitude (optional)

        hsync       : out std_logic;
        vsync       : out std_logic;
        r           : out std_logic_vector(3 downto 0);
        g           : out std_logic_vector(3 downto 0);
        b           : out std_logic_vector(3 downto 0)
    );
end vga_display;

architecture Behavioral of vga_display is

begin

    -- TODO: VGA timing + pixel logic

end Behavioral;
