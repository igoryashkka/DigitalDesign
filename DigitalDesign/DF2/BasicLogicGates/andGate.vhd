library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity andGate is
    Port (
        in1 : in  std_logic;
        in2 : in  std_logic;
        result : out std_logic
    );
end andGate;

architecture Behavioral of andGate is
begin
    result <= in1 and in2;
end Behavioral;
