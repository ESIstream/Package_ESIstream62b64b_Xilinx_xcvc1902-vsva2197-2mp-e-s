-------------------------------------------------------------------------------
-- This is free and unencumbered software released into the public domain.
--
-- Anyone is free to copy, modify, publish, use, compile, sell, or distribute
-- this software, either in source code form or as a compiled bitstream, for 
-- any purpose, commercial or non-commercial, and by any means.
--
-- In jurisdictions that recognize copyright laws, the author or authors of 
-- this software dedicate any and all copyright interest in the software to 
-- the public domain. We make this dedication for the benefit of the public at
-- large and to the detriment of our heirs and successors. We intend this 
-- dedication to be an overt act of relinquishment in perpetuity of all present
-- and future rights to this software under copyright law.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN 
-- ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- THIS DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES. 
-------------------------------------------------------------------------------
-- Version      Date            Author       Description
-- 1.1          2019            REFLEXCES    FPGA target migration, 64-bit data path
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rx_xpm_output_buffer is
  generic (
    DATA_WIDTH : integer := 64  -- useful data length in an ESIstream frame (16-bit) 
    );
  port (
    rst        : in  std_logic;
    wr_clk     : in  std_logic;
    rd_clk     : in  std_logic;
    din        : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    wr_en      : in  std_logic;
    rd_en      : in  std_logic;
    empty      : out std_logic;
    dout       : out std_logic_vector(DATA_WIDTH-1 downto 0);
    dout_valid : out std_logic
    );
end entity rx_xpm_output_buffer;

architecture rtl of rx_xpm_output_buffer is
  --============================================================================================================================
  -- Function and Procedure declarations
  --============================================================================================================================

  --============================================================================================================================
  -- Constant and Type declarations
  --============================================================================================================================
  constant PAS_LATENCY       : natural range 1 to 32 := 31;  -- Do not write PRBS Alignment Sequence (PAS)
  constant FIFO_READ_LATENCY : natural range 1 to 6  := 1;   -- READ LATENCY of the FIFO output decoded data valid 
  signal wr_rst_busy         : std_logic             := '0';
  signal rd_rst_busy         : std_logic             := '0';
  signal wr_en_d             : std_logic             := '0';
  signal wr_en_i             : std_logic             := '0';
  signal rd_en_i             : std_logic             := '0';
--
--============================================================================================================================
-- Signal declarations
--============================================================================================================================
begin
  --============================================================================================================================
  -- FIFO Read latency
  --============================================================================================================================
  delay_wr_en : entity work.rx_delay
    generic map (
      LATENCY => PAS_LATENCY
      ) port map (
        clk => wr_clk,
        rst => '0',
        d   => wr_en,
        q   => wr_en_d
        );

  delay_decoding_vld : entity work.rx_delay
    generic map (
      LATENCY => FIFO_READ_LATENCY
      ) port map (
        clk => rd_clk,
        rst => '0',
        d   => rd_en,
        q   => dout_valid
        );
  --
  wr_en_i <= wr_en_d and (not wr_rst_busy);
  rd_en_i <= rd_en and (not rd_rst_busy);
  rx_xpm_async_fifo_1 : entity work.rx_xpm_async_fifo
    generic map (
      DATA_WIDTH => DATA_WIDTH,
      FIFO_DEPTH => 512)  --FIFO_DEPTH)
    port map (
      rst         => rst,
      wr_en       => wr_en_i,
      wr_clk      => wr_clk,
      wr_rst_busy => wr_rst_busy,
      rd_en       => rd_en_i,
      rd_clk      => rd_clk,
      rd_rst_busy => rd_rst_busy,
      din         => din,
      dout        => dout,
      full        => open,
      empty       => empty);
--
end architecture rtl;
