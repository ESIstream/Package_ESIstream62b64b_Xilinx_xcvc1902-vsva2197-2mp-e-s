library work;
use work.esistream6264_pkg.all;

library IEEE;
use IEEE.STD_LOGIC_1164.all;


entity rx_lane_decoding is
  generic (
    COMMA : std_logic_vector(63 downto 0));
  port (
    clk        : in  std_logic;
    clk_acq    : in  std_logic;  -- acquisition clock, output buffer read port clock, should be same frequency and no phase drift with receive clock (default: clk_acq should take rx_clk).
    frame_in   : in  std_logic_vector(DESER_WIDTH-1 downto 0);
    sync       : in  std_logic;
    rst_esi    : in  std_logic;
    prbs_ena   : in  std_logic;
    read_fifo  : in  std_logic;  -- active high output buffer read data enable input
    frame_out  : out std_logic_vector(DESER_WIDTH-1 downto 0);
    lane_ready : out std_logic   -- active high lane ready output, indicates the lane is synchronized (alignement and prbs initialization done)
    );
end rx_lane_decoding;

architecture Structural of rx_lane_decoding is

  signal aligned_data       : std_logic_vector(DESER_WIDTH-1 downto 0)                := (others => '0');
  signal aligned_data_rdy   : std_logic                                               := '0';
  signal scrambled_data     : std_logic_vector(DESER_WIDTH-1 downto 0)                := (others => '0');
  signal scrambled_data_rdy : std_logic                                               := '0';
  signal prbs               : std_logic_vector(DESER_WIDTH-DESER_WIDTH/32-1 downto 0) := (others => '0');
  signal descrambled_data   : std_logic_vector(DESER_WIDTH-1 downto 0)                := (others => '0');
  signal rst_buffer         : std_logic                                               := '0';
  signal empty              : std_logic                                               := '0';
begin

  rx_frame_alignment1 : entity work.rx_frame_alignment
    generic map(
      COMMA => COMMA)
    port map(
      clk              => clk,
      din              => frame_in,
      sync             => sync,
      rst              => rst_esi,
      aligned_data     => aligned_data,
      aligned_data_rdy => aligned_data_rdy
      );

  rx_lfsr_init1 : entity work.rx_lfsr_init
    port map (
      clk      => clk,
      din      => aligned_data,
      din_rdy  => aligned_data_rdy,
      prbs_ena => prbs_ena,
      dout     => scrambled_data,
      dout_rdy => scrambled_data_rdy,
      prbs     => prbs
      );


  rx_decoder1 : entity work.rx_decoder
    port map (
      clk      => clk,
      din      => scrambled_data,
      din_rdy  => scrambled_data_rdy,
      prbs     => prbs,
      data_out => descrambled_data
      );

  rst_buffer <= sync or rst_esi;
  rx_xpm_output_buffer_1 : entity work.rx_xpm_output_buffer
    generic map (
      DATA_WIDTH => DESER_WIDTH)
    port map (
      rst        => rst_buffer,
      wr_clk     => clk,
      rd_clk     => clk_acq,
      din        => descrambled_data,
      wr_en      => scrambled_data_rdy,
      rd_en      => read_fifo,
      empty      => empty,
      dout       => frame_out,
      dout_valid => open);
  lane_ready <= not empty;
  --
end Structural;
