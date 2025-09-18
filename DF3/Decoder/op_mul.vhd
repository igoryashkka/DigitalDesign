library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity op_mul is
  port(a,b : in  std_logic_vector(7 downto 0);
       y   : out std_logic_vector(15 downto 0);
       carry, overflow, negative, zero : out std_logic);
end entity;

architecture rtl of op_mul is
  signal ua,ub : unsigned(7 downto 0);
  signal p     : unsigned(15 downto 0);
begin
  ua <= unsigned(a); ub <= unsigned(b);
  p  <= ua * ub;
  y  <= std_logic_vector(p);
  carry    <= '0';
  overflow <= '0';
  negative <= y(15);
  zero     <= '1' when y = (others=>'0') else '0';
end architecture;
