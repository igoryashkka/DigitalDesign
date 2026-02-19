library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_hdmi is
  port(
    clk     : in  std_logic;  -- 25 MHz
    rst     : in  std_logic;  

    -- timing outputs
    hsync   : out std_logic;
    vsync   : out std_logic;
    de      : out std_logic;

    -- pixel outputs
    r       : out std_logic_vector(7 downto 0);
    g       : out std_logic_vector(7 downto 0);
    b       : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of top_hdmi is

  signal x : unsigned(9 downto 0);
  signal y : unsigned(9 downto 0);

begin

  u_timing : entity work.video_timing
    port map(
      clk   => clk,
      rst   => rst,
      hsync => hsync,
      vsync => vsync,
      de    => de,
      x     => x,
      y     => y
    );

  u_pat : entity work.test_pattern
    port map(
      clk => clk,
      rst => rst,
      de  => de,
      x   => x,
      y   => y,
      r   => r,
      g   => g,
      b   => b
    );

end architecture;
