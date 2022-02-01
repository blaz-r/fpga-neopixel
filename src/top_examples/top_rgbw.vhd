library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_rgbw is
    Generic(
        px_count_width : integer := 6;
        px_num : integer := 29;
        bits_per_pixel : integer := 32
    );
    Port (
        CLK100MHZ : in STD_LOGIC;
        JA1 : out STD_LOGIC;
        rst : in STD_LOGIC;
        start : in STD_LOGIC);
end top_rgbw;

architecture Behavioral of top_rgbw is
    component neopixel_controller is
        Generic(
            px_count_width : integer := 6;
            px_num : integer := 29;
            bits_per_pixel : integer := 32;
            one_high_time : integer := 60;
            zero_high_time : integer := 30
        );
        Port (
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            start : in STD_LOGIC;
            pixel : in STD_LOGIC_VECTOR (0 to bits_per_pixel-1);
            next_px_num : out unsigned(px_count_width-1 downto 0);
            signal_out: out std_logic);
    end component;

    component RAM_30x32 is
        Port (
            clk : in STD_LOGIC;
            we : in STD_LOGIC;
            addr_in : in unsigned (5 downto 0);
            addr_out : in unsigned (5 downto 0);
            data_in : in STD_LOGIC_VECTOR (0 to 31);
            data_out : out STD_LOGIC_VECTOR (0 to 31));
    end component;

    signal pixel_from_ram: std_logic_vector(0 to bits_per_pixel-1) := "00000000000000000000000000001111";
    signal we_inter : std_logic;
    signal next_px_num_inter : unsigned(5 downto 0);

    signal ram_addr_in_inter : unsigned(5 downto 0);
    signal ram_data_in_inter: std_logic_vector(0 to bits_per_pixel-1);

begin

    neopixels: neopixel_controller
        generic map(
            px_count_width => px_count_width,
            px_num => px_num,
            bits_per_pixel => bits_per_pixel,
            one_high_time => 60,
            zero_high_time => 30)
        port map (
            clk => CLK100MHZ,
            rst => rst,
            start => start,
            pixel => pixel_from_ram,
            next_px_num => next_px_num_inter,
            signal_out => JA1
        );

    ram: RAM_30x32
        port map (
            clk => CLK100MHZ,
            we => we_inter,
            addr_out => next_px_num_inter,
            data_out => pixel_from_ram,
            addr_in => ram_addr_in_inter,
            data_in => ram_data_in_inter
        );

end Behavioral;
