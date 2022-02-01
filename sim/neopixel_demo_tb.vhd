library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity neopixel_demo_tb is
    --  Port ( );
end neopixel_demo_tb;

architecture Behavioral of neopixel_demo_tb is

    component top_demo is
        Port (
            CLK100MHZ : in STD_LOGIC;
            JA1 : out STD_LOGIC;
            rst : in STD_LOGIC;
            start_rgb : in STD_LOGIC;
            start_rgbw : in STD_LOGIC;
            start_anim: in STD_LOGIC);
    end component;

    signal clk: std_logic := '0';
    signal rst : std_logic := '1';
    signal start_rgb : std_logic := '0';
    signal start_rgbw : std_logic := '0';
    signal start_anim : std_logic := '0';
    signal JA1: std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    UUT: top_demo
        port map (
            CLK100MHZ => clk,
            rst => rst,
            start_rgb => start_rgb,
            start_rgbw => start_rgbw,
            start_anim => start_anim,
            JA1 => JA1
        );

    STIM_CLK: process
    begin
        wait for CLK_PERIOD/2;
        clk <= not clk;
    end process;

    STIM: process
    begin

        wait for CLK_PERIOD*420;
        start_rgb <= '1';

        wait for CLK_PERIOD*420;
        rst <= '0';

        wait for CLK_PERIOD*420;
        rst <= '1';

        wait for CLK_PERIOD*420;
        start_rgb <= '0';
        rst <= '0';

        wait for CLK_PERIOD*420;
        start_rgb <= '1';

        wait;

    end process;

end Behavioral;
