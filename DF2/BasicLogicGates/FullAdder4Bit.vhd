library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 1-Bit Full Adder Entity Declaration
entity FullAdder1Bit is
    Port (
        A      : in  STD_LOGIC;  
        B      : in  STD_LOGIC;  
        Cin    : in  STD_LOGIC;  
        Sum    : out STD_LOGIC;  
        Cout   : out STD_LOGIC   
    );
end FullAdder1Bit;

architecture Behavioral of FullAdder1Bit is
begin
    Sum  <= A XOR B XOR Cin;
    Cout <= (A AND B) OR (B AND Cin) OR (Cin AND A);
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- 4-Bit Full Adder Entity Declaration
entity FullAdder4Bit is
    Port (
        A      : in  STD_LOGIC_VECTOR(3 downto 0);  
        B      : in  STD_LOGIC_VECTOR(3 downto 0);  
        Cin    : in  STD_LOGIC;                     
        Sum    : out STD_LOGIC_VECTOR(3 downto 0);  
        Cout   : out STD_LOGIC                     
    );
end FullAdder4Bit;

-- 4-Bit Full Adder Implementation
architecture Behavioral of FullAdder4Bit is
    
    signal Carry : STD_LOGIC_VECTOR(4 downto 0);
begin
   
    Carry(0) <= Cin;

    FA0: entity work.FullAdder1Bit
        Port map (
            A => A(0),
            B => B(0),
            Cin => Carry(0),
            Sum => Sum(0),
            Cout => Carry(1)
        );

    FA1: entity work.FullAdder1Bit
        Port map (
            A => A(1),
            B => B(1),
            Cin => Carry(1),
            Sum => Sum(1),
            Cout => Carry(2)
        );

    FA2: entity work.FullAdder1Bit
        Port map (
            A => A(2),
            B => B(2),
            Cin => Carry(2),
            Sum => Sum(2),
            Cout => Carry(3)
        );

    FA3: entity work.FullAdder1Bit
        Port map (
            A => A(3),
            B => B(3),
            Cin => Carry(3),
            Sum => Sum(3),
            Cout => Carry(4)
        );

    Cout <= Carry(4);
end Behavioral;
