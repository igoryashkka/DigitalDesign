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

-- In general everything is cool, just minor comments:
-- 1) Regarding inputs and outputs
-- write them with _i and _o. In that way its much more easier to analyze the code:
-- Example in1_i, in2_i, result_o
-- 2) Not a mistake at all but company coding style: write all VHDL key words with CAPS --> 
-- ARCHITECTURE Behavioral OF andGate IS
-- BEGIN
--     result <= in1 AND in2;
-- END Behavioral;
