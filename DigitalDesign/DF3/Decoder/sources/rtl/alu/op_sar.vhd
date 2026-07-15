library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity op_sar is
  port(
    a : in  std_logic_vector(7 downto 0);
    b : in  std_logic_vector(2 downto 0);
    y   : out std_logic_vector(15 downto 0);
    carry, overflow, negative, zero : out std_logic
  );
end entity;

architecture rtl of op_sar is
  signal sa        : signed(7 downto 0);
  signal sh        : unsigned(2 downto 0);      
  signal low8      : std_logic_vector(7 downto 0);
  signal y_i       : std_logic_vector(15 downto 0);
  signal c_i       : std_logic;                 
  signal n_i       : std_logic;                
  signal z_i       : std_logic;                
begin
  sa <= signed(a);
  sh <= unsigned(b(2 downto 0));

  low8 <= std_logic_vector( sa sra to_integer(sh) );

  with sh select c_i <=
    '0'  when "000",
    a(0) when "001",
    a(1) when "010",
    a(2) when "011",
    a(3) when "100",
    a(4) when "101",
    a(5) when "110",
    a(6) when "111",
    '0'  when others;

  y_i <= (15 downto 8 => '0') & low8;
  y   <= y_i;


  n_i    <= low8(7);
  z_i    <= '1' when unsigned(low8) = 0 else '0';

  carry    <= c_i;
  negative <= n_i;
  zero     <= z_i;
  overflow <= n_i xor c_i;   
end architecture;
