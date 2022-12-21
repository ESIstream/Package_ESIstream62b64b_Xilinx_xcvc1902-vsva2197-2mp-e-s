library work;
use work.esistream6264_pkg.all;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;



entity tb_esistream_62b64b_top is
end tb_esistream_62b64b_top;

architecture Behavioral of tb_esistream_62b64b_top is
  --
  constant NB_LANES         : natural                               := 11;
  constant COMMA            : std_logic_vector(63 downto 0)         := x"ACF0FF00FFFF0000";  --x"00FFFF0000FFFF00";
  constant clk125_period    : time                                  := 8 ns;
  constant clk1875_period   : time                                  := 5.333 ns;
  constant clk15625_period  : time                                  := 6.4 ns;
  signal HSDP_SI570_CLK_C_P : std_logic                             := '1';
  signal HSDP_SI570_CLK_C_N : std_logic                             := '0';
  signal sync               : std_logic                             := '0';
  signal rst_esi            : std_logic                             := '0';
  signal rst_sys            : std_logic                             := '0';
  signal refclk_n           : std_logic                             := '0';
  signal refclk_p           : std_logic                             := '1';
  --
  signal txp                : std_logic_vector(NB_LANES-1 downto 0) := (others => '0');
  signal txn                : std_logic_vector(NB_LANES-1 downto 0) := (others => '1');
  --
  signal d_ctrl             : std_logic_vector(1 downto 0)          := "10";
  signal prbs_en            : std_logic                             := '1';
  signal db_en              : std_logic                             := '1';
  signal cb_en              : std_logic                             := '1';
  signal uart_ready_syslock : std_logic                             := '0';
  signal ip_ready           : std_logic                             := '0';
  signal lanes_ready        : std_logic                             := '0';
  signal be_cb_status       : std_logic                             := '0';
--
begin
  --
  esistream_62b64b_top_1 : entity work.esistream_62b64b_top
    generic map(
      GEN_ILA              => false,
      GEN_VERSAL           => false,
      SYSRESET_INIT        => x"00F",
      NB_LANES             => NB_LANES,
      COMMA                => COMMA,
      SYNC_DEBOUNCER_WIDTH => 2)
    port map (
      refclk_n               => refclk_n,
      refclk_p               => refclk_p,
      rxp                    => txp,
      rxn                    => txn,
      txp                    => txp,
      txn                    => txn,
      HSDP_SI570_CLK_C_P     => HSDP_SI570_CLK_C_P,
      HSDP_SI570_CLK_C_N     => HSDP_SI570_CLK_C_N,
      GPIO_LED(0)            => uart_ready_syslock,
      GPIO_LED(1)            => ip_ready,
      GPIO_LED(2)            => lanes_ready,
      GPIO_LED(3)            => be_cb_status,
      GPIO_SW(0)             => prbs_en,
      GPIO_SW(1)             => db_en,
      GPIO_SW(2)             => cb_en,
      GPIO_SW(3)             => d_ctrl(1),
      GPIO_PB(0)             => sync,
      GPIO_PB(1)             => rst_sys,
      UART1_RXD_HDIO_UART_TX => open,
      UART1_TXD_HDIO_UART_RX => '0'
      );



  clk125_process : process
  begin
    HSDP_SI570_CLK_C_P <= '1';
    HSDP_SI570_CLK_C_N <= '0';
    wait for clk15625_period/2;
    HSDP_SI570_CLK_C_P <= '0';
    HSDP_SI570_CLK_C_N <= '1';
    wait for clk15625_period/2;
  end process;

  clk1875_process : process
  begin
    refclk_p <= '1';
    refclk_n <= '0';
    wait for clk1875_period/2;
    refclk_p <= '0';
    refclk_n <= '1';
    wait for clk1875_period/2;
  end process;


  stimulus_process : process
  begin
    wait for 1 us;
    rst_sys <= '1';
    wait for 100 ns;
    rst_sys <= '0';
    wait until rising_edge(ip_ready);  -- 3 us;

    wait for 100 ns;
    sync <= '1';
    wait for 100 ns;
    sync <= '0';

    wait for 3 us;

    wait for 100 ns;
    sync <= '1';
    wait for 100 ns;
    sync <= '0';

    wait for 3 us;
    wait;
  end process;


end behavioral;
