-- Tx module for SPI Master (MSB first)
-- This module is responsible for driving the MOSI line when the SPI master
-- initiates a transfer. The module expects edge pulses from an SCLK generator
-- (separate entity) so the frequency generation is centralised in the top
-- level SPI master.
--
-- Operation summary:
--  - On assertion of `start`, the module loads `data_in` into an internal
--    register and becomes `busy`.
--  - On each SCLK falling edge pulse, the module drives the `mosi` output
--    with the next bit to transmit (MSB first). On the following SCLK
--    rising edge it advances the bit pointer.
--  - When all bits are transmitted the module asserts `done` and clears
--    `busy`.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx is
  port (
    clk       : in  std_logic; -- system clock
    rst       : in  std_logic; -- synchronous reset (active high)
    start     : in  std_logic; -- pulse to begin transfer (one clk)
    data_in   : in  std_logic_vector(7 downto 0); -- byte to transmit (MSB first)
    sclk_rise : in  std_logic; -- pulse when SCLK rises (one sys clk cycle)
    sclk_fall : in  std_logic; -- pulse when SCLK falls (one sys clk cycle)
    mosi      : out std_logic; -- Master Out, Slave In physical line
    busy      : out std_logic; -- high while transmitting
    done      : out std_logic  -- pulse when transfer completes (one sys clk)
  );
end entity tx;

architecture rtl of tx is
  signal shift_reg : std_logic_vector(7 downto 0);
  signal bit_idx   : integer range 0 to 7 := 0;
  signal active    : std_logic := '0';
  signal mosi_reg  : std_logic := '0';
begin

  -- Output assignments
  mosi <= mosi_reg;
  busy <= active;

  -- Main sequential process: handles start, SCLK edge events and bit pointer
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        shift_reg <= (others => '0');
        bit_idx   <= 0;
        active    <= '0';
        mosi_reg  <= '0';
        done      <= '0';
      else
        done <= '0'; -- default
        -- Start a new transfer (start is a 1-cycle pulse)
        if start = '1' and active = '0' then
          shift_reg <= data_in;
          bit_idx   <= 7; -- MSB first
          active    <= '1';
          -- Pre-drive MOSI so that the slave can sample on the next SCLK rising
          mosi_reg <= data_in(7);
        else
          -- When active, respond to SCLK edge pulses
          if active = '1' then
            -- On SCLK falling edge, ensure MOSI holds the correct bit
            if sclk_fall = '1' then
              -- Drive MOSI with the current bit index
              mosi_reg <= shift_reg(bit_idx);
            end if;

            -- On SCLK rising edge, advance the bit pointer (sampling happens at rise)
            if sclk_rise = '1' then
              if bit_idx = 0 then
                -- Last bit was transmitted/sampled -> complete
                active <= '0';
                done   <= '1';
              else
                bit_idx <= bit_idx - 1;
                -- Pre-drive new MOSI value so slave sees stable data before next rising edge
                mosi_reg <= shift_reg(bit_idx - 1);
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

end architecture rtl;
