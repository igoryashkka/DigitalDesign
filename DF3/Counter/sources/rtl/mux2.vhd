library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux2 is
  generic(
    N_BITS : positive := 8
  );
  port(
    sel : in  std_logic;                                  -- 0->a, 1->b
    a   : in  std_logic_vector(N_BITS-1 downto 0);
    b   : in  std_logic_vector(N_BITS-1 downto 0);
    y   : out std_logic_vector(N_BITS-1 downto 0)
  );
end entity;

architecture rtl of mux2 is
begin
  y <= b when sel = '1' else a;
end architecture;
