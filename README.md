# fpga-neopixel
FPGA module for NeoPixel led-strip written in VHDL. Works with ws2812b (RGB) and sk6812 (RGBW).

Made and tested in Xilinx Vivado, with Nexys A7 Artix-7 CSG324 FPGA board with 100 MHz clock but should work on other boards with minor adjustments as well.

![example](https://github.com/blaz-r/fpga-neopixel/blob/main/fpga_neopixel.jpg)

## Usage

To use neopixel controller, create neopxiel_controller component then map ports and adjust generics:

```
component neopixel_controller is
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
end component;
```
Generics:
- px_count_width : width of binary number (n. of bits) to hold count of leds (log2(num))
- px_num : number of pixels (leds) on a strip
- bits_per_pixel : usually 24 for RGB and 32 for RGBW
- one_high_time : clock cycles while out signal is high for bit with value 1
- zero_high_time : clock cycles while out signal is high for bit with value 0

Ports:
- clk : clock, made for 100 MHz, can be adjusted (see below)
- rst : reset of entire logic
- start : signals start of daa transmission
- pixels : bits representing currently transmitted pixel
- next_px_num : index in RAM or array of next pixel to be transmitted
- signal_out : output signal, should be connected to same port as your neopixel strip data cable

Example of some implementations can be found in [top_examples folder](https://github.com/blaz-r/fpga-neopixel/tree/main/src/top_examples).
- top.vhd is a simple implementation of RGB controller
- top_rgbw is implementation for RGBW
- top_demo combines rgb and rgbw with addition of simple animation

## Architecture

Following is a simple diagram showing how modules communicate and how controller communicates with top module:

![diagram](https://github.com/blaz-r/fpga-neopixel/blob/main/diagram.jpg)

Code is also thoroughly commented to help anyone understand how it works.

## Adjusting for different boards

Current project works with 100MHz clock, so time constants such as one_high_time  and zero_high_time are given in clock cycles, which are 10ns in this case.
To adjust for slower or faster clock following constants need to be changed, some through generics, some are just constants in code:
- one_high_time (generic)
- zero_high_time (generic)
- latch_time (strip_controller constant)
- px_wait_time (pixel_controller constant)

If you increase these numbers you might need to adjust bit width of wait and latch timers as well (latch_counter, px_wait_counter).

This could've been done much better, so if anyone wants to contribute by making project easier to adjust to different clock speed, feel free to open a PR :)