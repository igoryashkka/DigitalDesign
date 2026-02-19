library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity video_timing is
  port(
    clk     : in  std_logic; 
    rst     : in  std_logic;

    hsync   : out std_logic;
    vsync   : out std_logic;
    de      : out std_logic; 
    x       : out unsigned(9 downto 0);
    y       : out unsigned(9 downto 0)
  );
end entity;

architecture rtl of video_timing is

  constant H_ACTIVE_PIXELS : integer := 640;
  constant H_FRONT_PORCH   : integer := 16;
  constant H_SYNC_PULSE    : integer := 96;
  constant H_BACK_PORCH    : integer := 48;
  constant H_TOTAL_PIXELS  : integer := 800;

  constant V_ACTIVE_LINES : integer := 480;
  constant V_FRONT_PORCH  : integer := 10;
  constant V_SYNC_PULSE   : integer := 2;
  constant V_BACK_PORCH   : integer := 33;
  constant V_TOTAL_LINES  : integer := 525;

  signal h_cnt : unsigned(9 downto 0) := (others=>'0');
  signal v_cnt : unsigned(9 downto 0) := (others=>'0');

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        h_cnt <= (others=>'0');
        v_cnt <= (others=>'0');
      else
        if h_cnt = H_TOTAL_PIXELS-1 then
          h_cnt <= (others=>'0');

          if v_cnt = V_TOTAL_LINES-1 then
            v_cnt <= (others=>'0');
          else
            v_cnt <= v_cnt + 1;
          end if;

        else
          h_cnt <= h_cnt + 1;
        end if;
      end if;
    end if;
  end process;

  hsync <= '0' when (h_cnt >= H_ACTIVE_PIXELS + H_FRONT_PORCH and
                     h_cnt <  H_ACTIVE_PIXELS + H_FRONT_PORCH + H_SYNC_PULSE) else '1';

  vsync <= '0' when (v_cnt >= V_ACTIVE_LINES + V_FRONT_PORCH and
                     v_cnt <  V_ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_PULSE) else '1';

  de <= '1' when (h_cnt < H_ACTIVE_PIXELS and v_cnt < V_ACTIVE_LINES) else '0';

  x <= h_cnt;
  y <= v_cnt;

end architecture;
