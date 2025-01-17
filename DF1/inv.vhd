library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity inv is 
port (a,b : in STD_LOGIC_VECTOR(3 downto 0);
		y1,y2,y3,y4,y5,y : out STD_LOGIC_VECTOR(3 downto 0));
		
end;

architecture synth of inv is
begin
	
	--y1 <= a or b;
	y2 <= a nor b;
	--y3 <= a and b;
	--y4 <= a nand b;
	--y5 <= a xor b;
	y <= not a;
end;

