-- SPI Master top-level that instantiates Tx and Rx modules and generates SCLK
-- This SPI master implements Mode 0 operation (CPOL = 0, CPHA = 0).
-- The master generates SCLK from the system clock using a programmable
-- clock divider (clk_div). It provides one-clock-cycle pulses on the system
-- clock domain to indicate SCLK rising and falling edges so that Tx and Rx
-- can synchronously operate without generating clocks themselves.
--
-- Ports description (English comments):
--  clk       : system reference clock for control and SCLK generation.
--  rst       : synchronous reset (active high) that resets internal logic.
--  start     : pulse to begin a transfer (loads tx_data and opens SS).
--  clk_div   : 16-bit divisor controlling SCLK frequency. Effective SCLK
--              period ~= 2 * clk_div / f_clk; clk_div must be >= 2.
--  tx_data   : 8-bit data to transmit on MOSI (MSB first).
--  miso      : Master In, Slave Out input line.
--  mosi      : Master Out, Slave In output line (driven by Tx module).
--  sclk      : Serial clock output to slave.
--  ss_n      : Slave Select, active low; asserted low during transfer.
--  rx_data   : 8-bit output containing the last received byte.
--  busy      : indicates a transfer is in progress.
--  done      : pulse when the transfer completes (one system clock)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master is
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    start   : in  std_logic;
    clk_div : in  unsigned(15 downto 0);
    tx_data : in  std_logic_vector(7 downto 0);
    miso    : in  std_logic;
    mosi    : out std_logic;
    sclk    : out std_logic;
    ss_n    : out std_logic;
    rx_data : out std_logic_vector(7 downto 0);
    busy    : out std_logic;
    done    : out std_logic
  );
end entity spi_master;

architecture rtl of spi_master is
  -- SCLK generation signals
  signal counter      : unsigned(15 downto 0) := (others => '0');
  signal sclk_reg     : std_logic := '0'; -- current SCLK level (CPOL = 0)
  signal tick         : std_logic := '0'; -- internal tick when divider elapses
  signal sclk_rise_p  : std_logic := '0'; -- one-cycle pulse on rising edge
  signal sclk_fall_p  : std_logic := '0'; -- one-cycle pulse on falling edge

  -- Tx/Rx control signals
  signal tx_start_sig : std_logic := '0';
  signal rx_start_sig : std_logic := '0';
  signal tx_busy_sig  : std_logic;
  signal rx_busy_sig  : std_logic;
  signal tx_done_sig  : std_logic;
  signal rx_done_sig  : std_logic;
  signal rx_buf       : std_logic_vector(7 downto 0);

begin

  -- Instantiate Tx
  tx_inst : entity work.tx(rtl)
    port map (
      clk       => clk,
      rst       => rst,
      start     => tx_start_sig,
      data_in   => tx_data,
      sclk_rise => sclk_rise_p,
      sclk_fall => sclk_fall_p,
      mosi      => mosi,
      busy      => tx_busy_sig,
      done      => tx_done_sig
    );

  -- Instantiate Rx
  rx_inst : entity work.rx(rtl)
    port map (
      clk       => clk,
      rst       => rst,
      start     => rx_start_sig,
      sclk_rise => sclk_rise_p,
      sclk_fall => sclk_fall_p,
      miso      => miso,
      data_out  => rx_buf,
      busy      => rx_busy_sig,
      done      => rx_done_sig
    );

  rx_data <= rx_buf;

  -- Busy is asserted while either tx or rx is active
  busy <= tx_busy_sig or rx_busy_sig;

  -- Slave select (active low): assert low during the entire transfer
  ss_n <= not (tx_busy_sig or rx_busy_sig);

  -- Combined done is pulse if either module signals completion
  done <= tx_done_sig or rx_done_sig;

  -- SCLK generator: divide system clk by clk_div to produce SCLK toggles.
  -- We create a tick when counter reaches (clk_div / 2) and toggle sclk.
  process(clk)
    variable half : unsigned(15 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        counter <= (others => '0');
        sclk_reg <= '0';
        tick <= '0';
        sclk_rise_p <= '0';
        sclk_fall_p <= '0';
      else
        sclk_rise_p <= '0';
        sclk_fall_p <= '0';
        tick <= '0';
        -- prevent division by zero; require clk_div >= 2
        if clk_div < 2 then
          counter <= (others => '0');
          sclk_reg <= '0';
        else
          half := clk_div / 2;
          if counter >= half - 1 then
            counter <= (others => '0');
            tick <= '1';
            -- determine edge type based on current SCLK level
            if sclk_reg = '0' then
              sclk_reg <= '1';
              sclk_rise_p <= '1';
            else
              sclk_reg <= '0';
              sclk_fall_p <= '1';
            end if;
          else
            counter <= counter + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  sclk <= sclk_reg;

  -- Start control: forward user start pulse to both Tx and Rx modules
  -- so a combined transfer (full duplex) happens; both modules handle
  -- completion internally. We use registers to create one-cycle start pulses
  -- aligned to the system clock domain.
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        tx_start_sig <= '0';
        rx_start_sig <= '0';
      else
        -- start is expected to be a one-cycle pulse from the user
        if start = '1' then
          tx_start_sig <= '1';
          rx_start_sig <= '1';
        else
          tx_start_sig <= '0';
          rx_start_sig <= '0';
        end if;
      end if;
    end if;
  end process;

end architecture rtl;
