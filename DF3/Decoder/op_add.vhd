library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity op_add is
  port(a,b : in  std_logic_vector(7 downto 0);
       y   : out std_logic_vector(15 downto 0);
       carry, overflow, negative, zero : out std_logic);
end entity;

architecture rtl of op_add is
  signal ua,ub : unsigned(7 downto 0);
  signal s9    : unsigned(8 downto 0);
begin
  ua <= unsigned(a); ub <= unsigned(b);
  s9 <= ('0' & ua) + ('0' & ub);
  y  <= (15 downto 9 => '0') & std_logic_vector(s9);  
  carry    <= s9(8);
  overflow <= (a(7) xor b(7)) xor std_logic(s9(8) xor s9(7)) when '0'='0' else '0'; 
  negative <= y(7);  -- sign of low byte
  zero     <= '1' when y = (others=>'0') else '0';
end architecture;
