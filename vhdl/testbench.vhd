-- Testbench for SPI Master, Tx and Rx
-- This testbench generates a system clock and a synchronous reset,
-- drives the `start` pulse and `tx_data` into the spi_master, and
-- simulates a simple SPI slave that drives MISO in response (MSB first).
--
-- The testbench verifies that the master receives the expected data
-- from the simulated slave by checking `rx_data` after the transfer.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_spi is
end entity tb_spi;

architecture sim of tb_spi is
  -- Clock and reset
  signal clk     : std_logic := '0';
  signal rst     : std_logic := '1';

  -- SPI master interface signals
  signal start   : std_logic := '0';
  signal clk_div : unsigned(15 downto 0) := to_unsigned(4,16); -- small divisor for simulation
  signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
  signal miso    : std_logic := '0';
  signal mosi    : std_logic;
  signal sclk    : std_logic;
  signal ss_n    : std_logic;
  signal rx_data : std_logic_vector(7 downto 0);
  signal busy    : std_logic;
  signal done    : std_logic;

  -- Slave data to send back to master (response)
  constant SLAVE_DATA : std_logic_vector(7 downto 0) := x"5A"; -- example pattern

begin

  -- Instantiate the SPI master (unit under test)
  uut: entity work.spi_master(rtl)
    port map (
      clk     => clk,
      rst     => rst,
      start   => start,
      clk_div => clk_div,
      tx_data => tx_data,
      miso    => miso,
      mosi    => mosi,
      sclk    => sclk,
      ss_n    => ss_n,
      rx_data => rx_data,
      busy    => busy,
      done    => done
    );

  -- Clock generator: 50 MHz equivalent (period = 20 ns) for simulation convenience
  clk_process : process
  begin
    while now < 10 ms loop
      clk <= '0';
      wait for 10 ns;
      clk <= '1';
      wait for 10 ns;
    end loop;
    wait;
  end process clk_process;

  -- Reset sequence: hold reset for a few clock cycles then release
  reset_process : process
  begin
    rst <= '1';
    wait for 100 ns;
    rst <= '0';
    wait for 20 ns;
    wait;
  end process reset_process;

  -- Simple SPI slave behavior: when SS is asserted low, present bits on MISO
  -- MSB-first; change MISO on SCLK falling edge so master samples on rising edge (Mode 0)
  slave_process : process
    variable bit_idx : integer := 7;
    variable data_v  : std_logic_vector(7 downto 0);
  begin
    -- Idle: wait until SS goes low (transfer starts)
    wait until ss_n = '0';
    -- load slave response data
    data_v := SLAVE_DATA;
    bit_idx := 7;
    -- Provide initial MISO stable before first rising edge
    miso <= data_v(bit_idx);
    -- While SS low, update MISO on falling edges
    while ss_n = '0' loop
      wait until falling_edge(sclk);
      if bit_idx > 0 then
        bit_idx := bit_idx - 1;
        miso <= data_v(bit_idx);
      else
        -- last bit has been provided; keep line stable
        miso <= data_v(0);
      end if;
    end loop;
    wait; -- stop after one transaction for this simple TB
  end process slave_process;

  -- Stimulus process: provide tx_data and pulse start, then check rx_data
  stimulus_process : process
  begin
    -- Wait for reset release
    wait until rst = '0';
    wait for 50 ns;

    -- Test 1: single transfer
    tx_data <= x"A5"; -- pattern master sends
    -- generate start pulse (one clock cycle)
    start <= '1';
    wait until rising_edge(clk);
    start <= '0';

    -- Wait for transfer completion (done is pulsed when complete)
    wait until done = '1';
    wait for 20 ns; -- allow rx_data to settle

    -- Check that received data equals SLAVE_DATA
    if rx_data = SLAVE_DATA then
      report "TEST PASSED: rx_data matches SLAVE_DATA" severity note;
    else
      report "TEST FAILED: rx_data /= SLAVE_DATA" severity error;
    end if;

    -- Finish simulation
    wait for 100 ns;
    report "End of simulation" severity note;
    wait;
  end process stimulus_process;

end architecture sim;
