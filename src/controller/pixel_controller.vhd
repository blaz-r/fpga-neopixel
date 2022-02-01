----------------------------------------------------------------------------------------
--  Pixel controller
--  FSM that controls when bits should be transmitted according to protocol
--  
----------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pixel_controller is
    Generic(
        bits_per_pixel : integer := 24);    -- bits per pixel, rgb->24, rgbw->32
    Port (
        clk : in STD_LOGIC;                 -- clock, works with 100MHZ  
        rst : in STD_LOGIC;                 -- reset linked to switch
        next_px_en : in STD_LOGIC;          -- signal from strip controller to notify that next pixel should be transmitted
        next_bit_en : out STD_LOGIC;        -- signal for signal controller to notify that signal for next bit should be generated
        px_done : out STD_LOGIC);           -- signal for strip controller that pixel was transmitted
end pixel_controller;

architecture Behavioral of pixel_controller is

    type state_type is (RESET_ST, PX_SEND_ST, PX_WAIT_ST);

    -- 1,25 us is 124 cylces + 1 more for state transition -> 125, ie 1,25us, 100mhz clk means each tick is 10ns
    constant px_wait_time: integer := 124;  -- entire signal takes 1,25 us to transmit

    signal state , next_state : state_type;
    signal px_wait_counter : unsigned(7 downto 0) := (others => '0');
    signal current_bit_num : unsigned(5 downto 0) := (others => '0');

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
    NEXT_STATE_DECODE: process(state, clk, next_px_en, current_bit_num, px_wait_counter)
    begin
        next_state <= state;
        case ( state ) is
            when RESET_ST =>
                -- start transmitting when next_px_en signal turns high
                if next_px_en = '1' then
                    next_state <= PX_SEND_ST;
                else
                    next_state <= RESET_ST;
                end if;
            when PX_SEND_ST =>
                if current_bit_num < bits_per_pixel then
                    -- if there are still bits to be transmitted
                    next_state <= PX_WAIT_ST;
                else
                    next_state <= RESET_ST;
                end if;
            when PX_WAIT_ST =>
                if px_wait_counter < px_wait_time then
                    -- wait for 1,25 us according to protocol
                    next_state <= PX_WAIT_ST;
                else
                    next_state <= PX_SEND_ST;
                end if;
            when others => next_state <= RESET_ST;
        end case;
    end process;

    OUTPUT_DECODE : process ( clk )
    begin
        if (clk'event and clk = '1') then
            if state = RESET_ST then
                next_bit_en <= '0';
                px_done <= '0';
                px_wait_counter <= (others => '0');
                current_bit_num <= (others => '0');
            else
                px_done <= '0';
                next_bit_en <= '0';
                if state = PX_SEND_ST and next_state = PX_WAIT_ST then
                    -- on transition emit signal to start generating signal for next bit
                    next_bit_en <= '1';
                    -- reset wait timer
                    px_wait_counter <= (others => '0');
                elsif state = PX_WAIT_ST and next_state = PX_SEND_ST then
                    -- when we are done waiting, increase index of bit
                    current_bit_num <= current_bit_num + 1;
                elsif state = PX_SEND_ST and next_state = RESET_ST then
                    -- when all bits are transmited emit signal to notify strip controller
                    px_done <= '1';
                elsif state = PX_WAIT_ST then
                    -- count up in waiting state
                    px_wait_counter <= px_wait_counter + 1;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
