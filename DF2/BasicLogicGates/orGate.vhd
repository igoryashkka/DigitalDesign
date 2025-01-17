library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity orGate is
    Port (
        in1 : in  std_logic;
        in2 : in  std_logic;
        out : out std_logic
    );
end orGate;

architecture Behavioral of orGate is
begin
    out <= in1 or in2;
end Behavioral;
