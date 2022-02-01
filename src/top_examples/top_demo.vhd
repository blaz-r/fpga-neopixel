library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_demo is
    Port (
        CLK100MHZ : in STD_LOGIC;
        JA1 : out STD_LOGIC;
        rst : in STD_LOGIC;
        start_rgb : in STD_LOGIC;
        start_rgbw : in STD_LOGIC;
        start_anim: in STD_LOGIC);
end top_demo;

architecture Behavioral of top_demo is
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

    component RAM_60x24 is
        Port ( clk : in STD_LOGIC;
             we : in STD_LOGIC;
             addr_in : in unsigned (5 downto 0);
             addr_out : in unsigned (5 downto 0);
             data_in : in STD_LOGIC_VECTOR (0 to 23);
             data_out : out STD_LOGIC_VECTOR (0 to 23));
    end component;

    component counter is
        Generic ( width : integer := 8);
        Port ( clk : in STD_LOGIC;
             reset : in STD_LOGIC;
             count : out unsigned (width-1 downto 0));
    end component;

    signal we_inter : std_logic;

    signal rgbw_pixel_from_ram: std_logic_vector(0 to 31) := "00000000000000000000000000001111";
    signal rgbw_next_px_num_inter : unsigned(5 downto 0);
    signal rgbw_ram_addr_in_inter : unsigned(5 downto 0);
    signal rgbw_ram_data_in_inter: std_logic_vector(0 to 31);

    signal rgb_pixel_from_ram: std_logic_vector(0 to 23) := "000000000000000000001111";
    signal rgb_next_px_num_inter : unsigned(5 downto 0);
    signal rgb_ram_addr_in_inter : unsigned(5 downto 0);
    signal rgb_ram_data_in_inter: std_logic_vector(0 to 23);

    signal anim_next_px_num_inter : unsigned(5 downto 0);
    signal anim_shift_count_inter : unsigned(31 downto 0);
    signal anim_reset_inter: std_logic;
    -- moving rainbow animation
    type animation_type is array (0 to 59) of std_logic_vector(0 to 23);
    signal anim: animation_type := (0 => "000000001111111100000000",
                                                       1 => "000001101111111100000000",
                                                       2 => "000010111111111100000000",
                                                       3 => "000100011111111100000000",
                                                       4 => "000101101111111100000000",
                                                       5 => "000111001111111100000000",
                                                       6 => "001000011111111100000000",
                                                       7 => "001001111111111100000000",
                                                       8 => "001011001111111100000000",
                                                       9 => "001100101111111100000000",
                                                       10 => "001100101111111100000000",
                                                       11 => "001110001111111100000000",
                                                       12 => "001111011111111100000000",
                                                       13 => "010000111111111100000000",
                                                       14 => "010010001111111100000000",
                                                       15 => "010011101111111100000000",
                                                       16 => "010100111111111100000000",
                                                       17 => "010110011111111100000000",
                                                       18 => "010111101111111100000000",
                                                       19 => "011001001111111100000000",
                                                       20 => "011001001111111100000000",
                                                       21 => "011101011110001100000000",
                                                       22 => "100001101100011000000000",
                                                       23 => "100110001010101000000000",
                                                       24 => "101010011000111000000000",
                                                       25 => "101110100111000100000000",
                                                       26 => "110010110101010100000000",
                                                       27 => "110111010011100100000000",
                                                       28 => "111011100001110000000000",
                                                       29 => "111111110000000000000000",
                                                       30 => "111111110000000000000000",
                                                       31 => "111000110000000000011100",
                                                       32 => "110001100000000000111001",
                                                       33 => "101010100000000001010101",
                                                       34 => "100011100000000001110001",
                                                       35 => "011100010000000010001110",
                                                       36 => "010101010000000010101010",
                                                       37 => "001110010000000011000110",
                                                       38 => "000111000000000011100011",
                                                       39 => "000000000000000011111111",
                                                       40 => "000000000000000011111111",
                                                       41 => "000000000000101111101101",
                                                       42 => "000000000001011011011010",
                                                       43 => "000000000010000111001000",
                                                       44 => "000000000010110010110110",
                                                       45 => "000000000011100010100011",
                                                       46 => "000000000100001110010001",
                                                       47 => "000000000100111001111111",
                                                       48 => "000000000101100101101100",
                                                       49 => "000000000110010001011010",
                                                       50 => "000000000110010001011010",
                                                       51 => "000000000110111101011011",
                                                       52 => "000000000111101001011100",
                                                       53 => "000000001000010101011101",
                                                       54 => "000000001001000001011110",
                                                       55 => "000000001001110001100000",
                                                       56 => "000000001010011101100001",
                                                       57 => "000000001011001001100010",
                                                       58 => "000000001011110101100011",
                                                       59 => "000000001100100001100100");

    signal rgb_signal_out_inter: std_logic;
    signal rgbw_signal_out_inter: std_logic;
    signal anim_signal_out_inter: std_logic;
    
    signal start_rgb_sync : STD_LOGIC;
    signal start_rgbw_sync : STD_LOGIC;
    signal start_anim_sync : STD_LOGIC;
    signal rst_sync : STD_LOGIC;
begin

    neopixels_rgbw: neopixel_controller
        generic map(
            px_count_width => 6,
            px_num => 29,
            bits_per_pixel => 32,
            one_high_time => 60,
            zero_high_time => 30)
        port map (
            clk => CLK100MHZ,
            rst => rst_sync,
            start => start_rgbw_sync,
            pixel => rgbw_pixel_from_ram,
            next_px_num => rgbw_next_px_num_inter,
            signal_out => rgbw_signal_out_inter
        );

    neopixels_rgb: neopixel_controller
        generic map(
            px_count_width => 6,
            px_num => 60,
            bits_per_pixel => 24,
            one_high_time => 80,
            zero_high_time => 40)
        port map (
            clk => CLK100MHZ,
            rst => rst_sync,
            start => start_rgb_sync,
            pixel => rgb_pixel_from_ram,
            next_px_num => rgb_next_px_num_inter,
            signal_out => rgb_signal_out_inter
        );

    neopixels_animation: neopixel_controller
        generic map(
            px_count_width => 6,
            px_num => 60,
            bits_per_pixel => 24,
            one_high_time => 80,
            zero_high_time => 40)
        port map (
            clk => CLK100MHZ,
            rst => rst_sync,
            start => start_anim_sync,
            pixel => anim(to_integer(anim_next_px_num_inter)),
            next_px_num => anim_next_px_num_inter,
            signal_out => anim_signal_out_inter
        );

    -- every 100ms shift all pixels in animation array, creating moving rainbow animations
    animation: process ( CLK100MHZ )
    begin
        if (CLK100MHZ'event and CLK100MHZ = '1') then
            if anim_next_px_num_inter = 59 and anim_shift_count_inter > 1000000 then
                anim <= anim(1 to 59) & anim(0);
                anim_reset_inter <= '1';
            else
                anim_reset_inter <= rst_sync;
            end if;
        end if;
    end process;
    
    sync_inputs : process ( CLK100MHZ )
    begin
        if (CLK100MHZ'event and CLK100MHZ = '1') then
            start_rgb_sync  <= start_rgb;
            start_rgbw_sync  <= start_rgbw;
            start_anim_sync <= start_anim;
            rst_sync <= rst;
        end if;
    end process;

    ram_rgbw: RAM_30x32
        port map (
            clk => CLK100MHZ,
            we => we_inter,
            addr_out => rgbw_next_px_num_inter,
            data_out => rgbw_pixel_from_ram,
            addr_in => rgbw_ram_addr_in_inter,
            data_in => rgbw_ram_data_in_inter
        );

    ram_rgb: RAM_60x24
        port map (
            clk => CLK100MHZ,
            we => we_inter,
            addr_out => rgb_next_px_num_inter,
            data_out => rgb_pixel_from_ram,
            addr_in => rgb_ram_addr_in_inter,
            data_in => rgb_ram_data_in_inter
        );
        
    sec_counter: counter
        generic map (
            width => 32)
        port map ( 
            clk => CLK100MHZ,
            reset => anim_reset_inter,
            count => anim_shift_count_inter
        );

    JA1 <=  rgbw_signal_out_inter when start_rgbw_sync = '1' else
            rgb_signal_out_inter when start_rgb_sync = '1' else
            anim_signal_out_inter;
end Behavioral;
