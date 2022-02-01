-- simple counter module

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter is
    Generic ( width : integer := 8); 
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           count : out unsigned (width-1 downto 0));
end counter;

architecture Behavioral of counter is

signal counter : unsigned (width-1 downto 0);


begin

process (clk)
begin
   if (clk'event and clk = '1') then
      if reset = '1' then
         counter <= (others => '0');
      else
         counter <= counter + 1;
      end if;
   end if;
end process;

count <= counter;

end Behavioral;
