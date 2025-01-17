library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux2to1 is
    Port (
        a   : in  std_logic;
        b   : in  std_logic;
        sel : in  std_logic;
        y   : out std_logic
    );
end mux2to1;

architecture Behavioral of mux2to1 is
begin
    y <= a when sel = '0' else b;
end Behavioral;
