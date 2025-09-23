library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity op_mul is
  port(
    a,b : in  std_logic_vector(7 downto 0);
    y   : out std_logic_vector(15 downto 0);
    carry, overflow, negative, zero : out std_logic
  );
end entity;

architecture rtl of op_mul is
  signal ua, ub  : unsigned(7 downto 0);
  signal p_u     : unsigned(15 downto 0);

  signal sa, sb  : signed(7 downto 0);
  signal p_s     : signed(15 downto 0);

  signal y_i     : std_logic_vector(15 downto 0);
  signal low8    : std_logic_vector(7 downto 0);
begin

  ua <= unsigned(a);
  ub <= unsigned(b);

  sa <= signed(a);
  sb <= signed(b);

  p_u <= ua * ub;
  p_s <= sa * sb;

  y_i <= std_logic_vector(p_u);
  y   <= y_i;


  low8     <= y_i(7 downto 0);

  carry <= '1' when p_u(15 downto 8) /= to_unsigned(0, 8) else '0';

  overflow <= '1' when std_logic_vector(p_s(15 downto 8)) /= (low8(7) & low8(7) & low8(7) & low8(7) &
                                                              low8(7) & low8(7) & low8(7) & low8(7))
             else '0';

  negative <= low8(7);

  zero     <= '1' when unsigned(low8) = 0 else '0';

end architecture;
