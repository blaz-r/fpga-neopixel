----------------------------------------------------------------------------------------
--  RAM, 30 rows of 32 bits
--  Each row represents 1 RGBW pixel (led) on strip
--  first row represents bits for first pixel, first pixel being the one closest to fpga
--  bits are in GRBW order, so from left to right first 8 bits represent green, next 8 red, next 8 blue and final 8 represent white
----------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM_30x32 is
    Port ( clk : in STD_LOGIC;
         we : in STD_LOGIC;
         addr_in : in unsigned (5 downto 0);
         addr_out : in unsigned (5 downto 0);
         data_in : in STD_LOGIC_VECTOR (0 to 31);
         data_out : out STD_LOGIC_VECTOR (0 to 31));
end RAM_30x32;

architecture Behavioral of RAM_30x32 is

    type RAM_type is array (0 to 29) of std_logic_vector(0 to 31);
    signal RAM: RAM_type := (0 to 7   => "00001111000000000000000000000000",
                             8 to 15  => "00000000000011110000000000000000",
                             16 to 23 => "00000000000000000000111100000000",
                             24 to 29 => "00000000000000000000000000001111");

begin
    -- async reading
    data_out <= RAM(to_integer(addr_out));

    -- synch writing
    SYNC_PROC: process (clk)
    begin
        if (clk'event and clk = '1') then
            if we='1' then
                RAM(to_integer(addr_in)) <= data_in;
            end if;
        end if;
    end process;

end Behavioral;
