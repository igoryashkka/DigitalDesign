library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity op_add is
  port(
    a,b : in  std_logic_vector(7 downto 0);
    y   : out std_logic_vector(15 downto 0);
    carry, overflow, negative, zero : out std_logic
  );
end entity;

architecture rtl of op_add is
  signal ua, ub  : unsigned(7 downto 0);
  signal s9      : unsigned(8 downto 0);           
  signal y_i     : std_logic_vector(15 downto 0);
  signal low8    : std_logic_vector(7 downto 0);
begin

  ua <= unsigned(a);
  ub <= unsigned(b);


  s9   <= ('0' & ua) + ('0' & ub);


  y_i  <= (15 downto 9 => '0') & std_logic_vector(s9);
  y    <= y_i;


  low8     <= y_i(7 downto 0);
  carry    <= s9(8);  
  overflow <= (a(7) and b(7) and (not low8(7))) or ((not a(7)) and (not b(7)) and low8(7));
  negative <= low8(7);                                
  zero     <= '1' when unsigned(low8) = 0 else '0';   
end architecture;