library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_pattern is
  port(
    clk : in  std_logic;
    rst : in  std_logic;

    de  : in  std_logic;
    x   : in  unsigned(9 downto 0);
    y   : in  unsigned(9 downto 0);

    r   : out std_logic_vector(7 downto 0);
    g   : out std_logic_vector(7 downto 0);
    b   : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of test_pattern is
begin
  process(clk)
    variable bar : integer;
  begin
    if rising_edge(clk) then
      if rst='1' then
        r <= (others=>'0');
        g <= (others=>'0');
        b <= (others=>'0');
      else
        if de='0' then
          r <= (others=>'0');
          g <= (others=>'0');
          b <= (others=>'0');
        else

          bar := to_integer(x) / 80;

          case bar is
            when 0 => r <= x"FF"; g <= x"00"; b <= x"00"; -- red
            when 1 => r <= x"00"; g <= x"FF"; b <= x"00"; -- green
            when 2 => r <= x"00"; g <= x"00"; b <= x"FF"; -- blue
            when 3 => r <= x"FF"; g <= x"FF"; b <= x"00"; -- yellow
            when 4 => r <= x"FF"; g <= x"00"; b <= x"FF"; -- magenta
            when 5 => r <= x"00"; g <= x"FF"; b <= x"FF"; -- cyan
            when 6 => r <= x"FF"; g <= x"FF"; b <= x"FF"; -- white
            when others => r <= x"00"; g <= x"00"; b <= x"00"; -- black
          end case;
        end if;
      end if;
    end if;
  end process;
end architecture;
