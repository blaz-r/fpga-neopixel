library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity neopixel_controller_tb is
    --  Port ( );
end neopixel_controller_tb;

architecture Behavioral of neopixel_controller_tb is

    component top is
        Generic(
            px_count_width : integer := 6;
            px_num : integer := 60;
            bits_per_pixel : integer := 24);
        Port ( 
             CLK100MHZ : in STD_LOGIC;
             JA1 : out STD_LOGIC;
             rst : in STD_LOGIC;
             start : in STD_LOGIC);
    end component;

    signal clk: std_logic := '0';
    signal rst : std_logic := '1';
    signal start : std_logic := '0';
    signal JA1: std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    UUT: top
        generic map (
            px_count_width => 6,
            px_num => 60,
            bits_per_pixel => 24
        )
        port map (
            CLK100MHZ => clk,
            rst => rst,
            start => start,
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
        start <= '1';

        wait for CLK_PERIOD*420;
        rst <= '0';

        wait for CLK_PERIOD*420;
        rst <= '1';

        wait for CLK_PERIOD*420;
        start <= '0';
        rst <= '0';

        wait for CLK_PERIOD*420;
        start <= '1';

        wait;

    end process;

end Behavioral;
