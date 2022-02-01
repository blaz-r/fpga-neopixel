----------------------------------------------------------------------------------------
--  Neopixel controller
--  works with RGB (ws2812b) and RGBW (sk6812) led strips
--  https://cdn.sparkfun.com/datasheets/Components/LED/adafruit-neopixel-uberguide.pdf
----------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity neopixel_controller is
    Generic(
        px_count_width : integer := 6;      -- width of pixel count binary number
        px_num : integer := 60;             -- number of pixels (leds) on strip
        bits_per_pixel : integer := 24;     -- bits per pixel, rgb 24, rgbw 32
        one_high_time : integer := 80;      -- interval of out signal high value for bit with value 1
        zero_high_time : integer := 40);    -- interval of out signal high value for bit with value 0
    Port (
        clk : in STD_LOGIC;                                     -- clock, works with 100MHZ
        rst : in STD_LOGIC;                                     -- reset linked to switch
        start : in STD_LOGIC;                                   -- start of signal transmission, linked to switch
        pixel : in STD_LOGIC_VECTOR (0 to bits_per_pixel-1);    -- current pixel bits
        next_px_num : out unsigned(px_count_width-1 downto 0);  -- index of next pixel, used to retrieve value from RAM
        signal_out: out std_logic);                             -- output signal
end neopixel_controller;

architecture Behavioral of neopixel_controller is
    -- controller for entire strip
    -- governs index of current pixel and when pixel controller should transmit
    component strip_controller is
        Generic (
            width : integer := 6;
            px_num : integer := 60);
        Port (
            clk : in STD_LOGIC;
            start : in STD_LOGIC;
            rst : in STD_LOGIC;
            px_done : in STD_LOGIC;
            next_px_en : out STD_LOGIC;
            next_px_num : out unsigned (width-1 downto 0));
    end component;

    -- controller for individual pixel
    -- governs when next bit should be transmited and when entire pixel is transmitted
    component pixel_controller is
        Generic(
            bits_per_pixel : integer := 24);
        Port (
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            next_px_en : in STD_LOGIC;
            next_bit_en : out STD_LOGIC;
            px_done : out STD_LOGIC);
    end component;

    -- controller for generating pwm signal
    -- generates signal according to current bit value
    component signal_controller is
        Generic(
            bits_per_pixel : integer := 24;
            one_high_time : integer := 80;
            zero_high_time : integer := 40);
        Port (
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            next_bit_en : in STD_LOGIC;
            pixel : in STD_LOGIC_VECTOR (0 to bits_per_pixel-1);
            signal_out : out STD_LOGIC);
    end component;

    signal px_done_inter: std_logic := '0';         -- internal signal for when current pixel is completely transmitted
    signal next_px_en_inter: std_logic := '0';      -- internal signal for when next pixel should be transmitted
    signal next_bit_en_inter: std_logic := '0';     -- internal signal for when signal should be generated for next bit

begin

    strip_control: strip_controller
        generic map (
            width => px_count_width,
            px_num => px_num
        )
        port map (
            clk => clk,
            start => start,
            rst => rst,
            px_done => px_done_inter,
            next_px_en => next_px_en_inter,     -- pixel controller notifies strip controller when it's done
            next_px_num => next_px_num          -- strip controller notifies pixel controller when next pixel should be transmitted
        );

    pixel_control: pixel_controller
        generic map (
            bits_per_pixel => bits_per_pixel
        )
        port map (
            clk => clk,
            rst => rst,
            next_px_en => next_px_en_inter,
            next_bit_en => next_bit_en_inter,   -- pixel controller notifies signal controller when next bit should be transmitted
            px_done => px_done_inter
        );

    signal_gen: signal_controller
        generic map (
            bits_per_pixel => bits_per_pixel,
            one_high_time => one_high_time,
            zero_high_time => zero_high_time
        )
        port map (
            clk => clk,
            rst => rst,
            next_bit_en => next_bit_en_inter,
            pixel => pixel,
            signal_out => signal_out
        );

end Behavioral;
