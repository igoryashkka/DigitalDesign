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

  constant H_ACTIVE : integer := 640;
  constant H_FP     : integer := 16;
  constant H_SYNC   : integer := 96;
  constant H_BP     : integer := 48;
  constant H_TOTAL  : integer := 800;

  constant V_ACTIVE : integer := 480;
  constant V_FP     : integer := 10;
  constant V_SYNC   : integer := 2;
  constant V_BP     : integer := 33;
  constant V_TOTAL  : integer := 525;

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
        if h_cnt = H_TOTAL-1 then
          h_cnt <= (others=>'0');

          if v_cnt = V_TOTAL-1 then
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


end architecture;
