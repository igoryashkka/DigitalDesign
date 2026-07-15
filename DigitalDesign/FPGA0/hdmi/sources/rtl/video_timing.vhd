library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity video_timing is
  generic(
    -- 0: 640x480@60, 1: 1920x1080@60
    G_TIMING_SEL : integer := 1
  );
  port(
    clk     : in  std_logic; 
    rst     : in  std_logic;

    hsync   : out std_logic;
    vsync   : out std_logic;
    de      : out std_logic; 
    x       : out unsigned(11 downto 0);
    y       : out unsigned(11 downto 0)
  );
end entity;

architecture rtl of video_timing is

  function sel_int(sel, val_640, val_1080 : integer) return integer is
  begin
    if sel = 0 then
      return val_640;
    else
      return val_1080;
    end if;
  end function;

  function sel_sl(sel : integer; val_640, val_1080 : std_logic) return std_logic is
  begin
    if sel = 0 then
      return val_640;
    else
      return val_1080;
    end if;
  end function;

  constant H_ACTIVE_PIXELS : integer := sel_int(G_TIMING_SEL, 640, 1920);
  constant H_FRONT_PORCH   : integer := sel_int(G_TIMING_SEL, 16, 88);
  constant H_SYNC_PULSE    : integer := sel_int(G_TIMING_SEL, 96, 44);
  constant H_BACK_PORCH    : integer := sel_int(G_TIMING_SEL, 48, 148);
  constant H_TOTAL_PIXELS  : integer := sel_int(G_TIMING_SEL, 800, 2200);

  constant V_ACTIVE_LINES : integer := sel_int(G_TIMING_SEL, 480, 1080);
  constant V_FRONT_PORCH  : integer := sel_int(G_TIMING_SEL, 10, 4);
  constant V_SYNC_PULSE   : integer := sel_int(G_TIMING_SEL, 2, 5);
  constant V_BACK_PORCH   : integer := sel_int(G_TIMING_SEL, 33, 36);
  constant V_TOTAL_LINES  : integer := sel_int(G_TIMING_SEL, 525, 1125);

  constant H_SYNC_ACTIVE : std_logic := sel_sl(G_TIMING_SEL, '0', '1');
  constant V_SYNC_ACTIVE : std_logic := sel_sl(G_TIMING_SEL, '0', '1');

  signal h_cnt : unsigned(11 downto 0) := (others=>'0');
  signal v_cnt : unsigned(11 downto 0) := (others=>'0');

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
   --- here can be diffrence from another realisation of tim_gen, also idk if 25mhz is ok, maybe 25.175 is needed
  hsync <= H_SYNC_ACTIVE when (h_cnt >= H_ACTIVE_PIXELS + H_FRONT_PORCH and
                               h_cnt <  H_ACTIVE_PIXELS + H_FRONT_PORCH + H_SYNC_PULSE)
           else not H_SYNC_ACTIVE;

  vsync <= V_SYNC_ACTIVE when (v_cnt >= V_ACTIVE_LINES + V_FRONT_PORCH and
                               v_cnt <  V_ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_PULSE)
           else not V_SYNC_ACTIVE;

  de <= '1' when (h_cnt < H_ACTIVE_PIXELS and v_cnt < V_ACTIVE_LINES) else '0';

  x <= h_cnt;
  y <= v_cnt;

end architecture;
