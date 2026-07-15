
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fulladder is
port (
    a, b : in STD_LOGIC_VECTOR(31 downto 0);
    cin  : in STD_LOGIC;  
    s    : out STD_LOGIC_VECTOR(31 downto 0);
    cout : out STD_LOGIC   -- From MSB single cout;
);
end;

architecture synth of fulladder is
signal carry : STD_LOGIC_VECTOR(31 downto 0); 
begin
    
    carry(0) <= cin; 
    gen: for i in 0 to 30 generate
        s(i) <= a(i) xor b(i) xor carry(i);
        carry(i + 1) <= (a(i) and b(i)) or (a(i) and carry(i)) or (b(i) and carry(i));
    end generate;


    cout <= carry(31);
end;


--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--
--entity fulladder is 
--port (a,b , cin : in STD_LOGIC_VECTOR(31 downto 0);
--		s, cout : out STD_LOGIC_VECTOR(31 downto 0));
--end;
--
--architecture synth of fulladder is
--signal p, g : STD_LOGIC_VECTOR(31 downto 0);
--begin
--	p <= a xor b;
--	g <= a and b;
--	s <= p xor cin;
--	cout <= (g or (p and cin));
--
--end;
--
