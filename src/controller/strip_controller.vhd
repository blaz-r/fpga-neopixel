----------------------------------------------------------------------------------------
--  Strip controller
--  FSM that controls when pixels should be transmitted according to protocol
--  
----------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity strip_controller is
    Generic (
        width : integer := 6;                           -- width of pixel count binary number
        px_num : integer := 60);                        -- number of pixels (leds) on strip
    Port (
        clk : in STD_LOGIC;                             -- clock, works with 100MHZ
        start : in STD_LOGIC;                           -- reset linked to switch
        rst : in STD_LOGIC;                             -- start of signal transmission, linked to switch
        px_done : in STD_LOGIC;                         -- signal from pixel controller to notify that pixel transmission is done
        next_px_en : out STD_LOGIC;                     -- signal for pixel controller to notify that next pixel should be transmitted
        next_px_num : out unsigned (width-1 downto 0)); -- index of next pixel to be transmited
end strip_controller;

architecture Behavioral of strip_controller is
    type state_type is (RESET_ST, TRANSMIT_ST, WAIT_ST, LATCH_ST);
    
    -- 100us, 100mhz clk means each tick is 10ns
    constant latch_time : integer := 10000;         -- when pixels on strip are transmitted, we need to wait in order for colors to latch

    signal state , next_state : state_type;
    signal current_px : unsigned(width-1 downto 0);
    signal latch_counter : unsigned(13 downto 0);

begin
    -- state transition logic
    SYNC_PROC: process ( clk )
    begin
        if (clk'event and clk = '1') then
            if rst = '1' then
                state <= RESET_ST;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    -- next state decision logic
    NEXT_STATE_DECODE: process(state, clk, start, current_px)
    begin
        next_state <= state;
        case ( state ) is
            when RESET_ST =>
                -- we start transmitting when we get start signal
                if start = '1' then
                    next_state <= TRANSMIT_ST;
                else
                    next_state <= RESET_ST;
                end if;
            when TRANSMIT_ST =>
                if current_px < px_num then
                    -- if there are still pixels to be transmitted
                    next_state <= WAIT_ST;
                else
                    -- if we are done transmiting, we wait so colors latch
                    next_state <= LATCH_ST;
                end if;
            when WAIT_ST =>
                if px_done = '1' then
                    -- we wait until we get notified that pixel was transmitted
                    next_state <= TRANSMIT_ST;
                else
                    next_state <= WAIT_ST;
                end if;
            when LATCH_ST =>
                -- wait for given period of time for colors to latch
                if latch_counter = latch_time then
                    next_state <= RESET_ST;
                else
                    next_state <= LATCH_ST;
                end if;
            when others => next_state <= RESET_ST;
        end case;
    end process;

    OUTPUT_DECODE : process ( clk )
    begin
        if (clk'event and clk = '1') then
            if state = RESET_ST then
                latch_counter <= (others => '0');
                current_px <= (others => '0');
                next_px_en <= '0';
                next_px_num <= (others => '0');
            else
                next_px_en <= '0';
                if state = TRANSMIT_ST and next_state = WAIT_ST then
                    -- when going from transmitting to waiting we emit signal for one clock period to start pixel transmition
                    next_px_en <= '1';
                    -- we also send index of pixel to be transmited
                    next_px_num <= current_px;
                elsif state = WAIT_ST and next_state = TRANSMIT_ST then
                    -- increase index when current pixel is transmited
                    current_px <= current_px + 1;
                elsif state = LATCH_ST then
                    -- in latch state we just increase counter and wait
                    latch_counter <= latch_counter + 1;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
