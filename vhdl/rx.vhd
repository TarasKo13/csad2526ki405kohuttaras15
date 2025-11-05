-- Rx module for SPI Master (MSB first)
-- This module samples the MISO line on SCLK rising edges (Mode 0: CPOL=0, CPHA=0)
-- and accumulates the received bits into a byte. It is driven by edge pulses
-- from the SCLK generator (rising/falling pulses). The module produces a
-- `data_out` when the full byte has been received and asserts `done`.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx is
  port (
    clk       : in  std_logic; -- system clock
    rst       : in  std_logic; -- synchronous reset (active high)
    start     : in  std_logic; -- pulse to begin receive (one clk)
    sclk_rise : in  std_logic; -- pulse when SCLK rises (one sys clk cycle)
    sclk_fall : in  std_logic; -- pulse when SCLK falls (one sys clk cycle)
    miso      : in  std_logic; -- Master In, Slave Out physical line
    data_out  : out std_logic_vector(7 downto 0); -- received byte (MSB first)
    busy      : out std_logic; -- high while receiving
    done      : out std_logic  -- pulse when transfer completes (one sys clk)
  );
end entity rx;

architecture rtl of rx is
  signal buf       : std_logic_vector(7 downto 0) := (others => '0');
  signal bit_idx   : integer range 0 to 7 := 7; -- index for MSB-first placement
  signal active    : std_logic := '0';
begin

  busy <= active;
  data_out <= buf;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        buf     <= (others => '0');
        bit_idx <= 7;
        active  <= '0';
        done    <= '0';
      else
        done <= '0';
        if start = '1' and active = '0' then
          buf <= (others => '0');
          bit_idx <= 7;
          active <= '1';
        else
          if active = '1' then
            -- Sample MISO on SCLK rising edge and place into buffer at bit_idx
            if sclk_rise = '1' then
              buf(bit_idx) <= miso;
              if bit_idx = 0 then
                active <= '0';
                done <= '1';
              else
                bit_idx <= bit_idx - 1;
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

end architecture rtl;
