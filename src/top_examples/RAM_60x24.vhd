----------------------------------------------------------------------------------------
--  RAM, 60 rows of 24 bits
--  Each row represents 1 RGB pixel (led) on strip
--  first row represents bits for first pixel, first pixel being the one closest to fpga
--  bits are in GRB order, so from left to right first 8 bits represent green, next 8 red and final 8 represent blue
----------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM_60x24 is
    Port ( clk : in STD_LOGIC;
         we : in STD_LOGIC;
         addr_in : in unsigned (5 downto 0);
         addr_out : in unsigned (5 downto 0);
         data_in : in STD_LOGIC_VECTOR (0 to 23);
         data_out : out STD_LOGIC_VECTOR (0 to 23));
end RAM_60x24;

architecture Behavioral of RAM_60x24 is

    type RAM_type is array (0 to 59) of std_logic_vector(0 to 23);
    signal RAM: RAM_type := (0 to 20  => "000000000000000000001111",
                             21 to 40 => "000011110000000000000000",
                             41 to 59 => "000000000000111100000000");

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
