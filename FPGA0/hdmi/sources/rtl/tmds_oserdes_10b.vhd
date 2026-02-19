library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity tmds_oserdes_10b is
  port (
    rst     : in  std_logic;                    -- active-high reset
    pix_clk : in  std_logic;                    -- CLKDIV (pixel clock)
    ser_clk : in  std_logic;                    -- CLK    (5x pixel clock)
    din10   : in  std_logic_vector(9 downto 0); -- parallel 10-bit word
    dout    : out std_logic                     -- serial output
  );
end entity;

architecture rtl of tmds_oserdes_10b is
  signal shift1, shift2 : std_logic;
begin

  -- SLAVE: provides bits [9:8] through cascade
  u_serdes_slave : OSERDESE2
    generic map (
      DATA_RATE_OQ   => "DDR",
      DATA_WIDTH     => 10,
      SERDES_MODE    => "SLAVE",
      TRISTATE_WIDTH => 1
    )
    port map (
      CLK       => ser_clk,
      CLKDIV    => pix_clk,
      RST       => rst,
      OCE       => '1',

      -- Xilinx 10-bit cascade pattern:
      -- SLAVE uses D3/D4 for the two MSBs
      D1        => '0',
      D2        => '0',
      D3        => din10(8),
      D4        => din10(9),
      D5        => '0',
      D6        => '0',
      D7        => '0',
      D8        => '0',

      SHIFTIN1  => '0',
      SHIFTIN2  => '0',
      SHIFTOUT1 => shift1,
      SHIFTOUT2 => shift2,

      OQ        => open,

      -- tristate not used
      T1        => '0',
      T2        => '0',
      T3        => '0',
      T4        => '0',
      TCE       => '0',
      TBYTEIN   => '0',
      TBYTEOUT  => open,
      OFB       => open,
      TFB       => open
    );

  -- MASTER: outputs serial stream, takes [7:0] + cascaded [9:8]
  u_serdes_master : OSERDESE2
    generic map (
      DATA_RATE_OQ   => "DDR",
      DATA_WIDTH     => 10,
      SERDES_MODE    => "MASTER",
      TRISTATE_WIDTH => 1
    )
    port map (
      CLK       => ser_clk,
      CLKDIV    => pix_clk,
      RST       => rst,
      OCE       => '1',

      -- 8 LSBs
      D1        => din10(0),
      D2        => din10(1),
      D3        => din10(2),
      D4        => din10(3),
      D5        => din10(4),
      D6        => din10(5),
      D7        => din10(6),
      D8        => din10(7),

      -- cascade in from SLAVE
      SHIFTIN1  => shift1,
      SHIFTIN2  => shift2,
      SHIFTOUT1 => open,
      SHIFTOUT2 => open,

      OQ        => dout,

      -- tristate not used
      T1        => '0',
      T2        => '0',
      T3        => '0',
      T4        => '0',
      TCE       => '0',
      TBYTEIN   => '0',
      TBYTEOUT  => open,
      OFB       => open,
      TFB       => open
    );

end architecture;
