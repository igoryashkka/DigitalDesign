library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux4to1 is
    Port (
        a   : in  STD_LOGIC;  
        b   : in  STD_LOGIC; 
        c   : in  STD_LOGIC;  
        d   : in  STD_LOGIC;  
        sel : in  STD_LOGIC_VECTOR(1 downto 0); 
        y   : out STD_LOGIC   
    );
end mux4to1;


architecture Behavioral of mux4to1 is
begin
    process(a, b, c, d, sel)
    begin
        case sel is
            when "00" => y <= a;  
            when "01" => y <= b;  
            when "10" => y <= c;  
            when "11" => y <= d; 
            when others => y <= '0';  
        end case;
    end process;
end Behavioral;
