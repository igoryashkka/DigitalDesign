library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY pgs_logic IS
    PORT ( A_i    : IN  STD_LOGIC;
           B_i    : IN  STD_LOGIC;
           Cin_i  : IN  STD_LOGIC;
           Sum_o  : OUT STD_LOGIC;
           P_o    : OUT STD_LOGIC;
           G_o    : OUT STD_LOGIC);
END pgs_logic;

ARCHITECTURE Behavioral OF pgs_logic IS
BEGIN
    P_o   <= (A_i XOR B_i); 
    G_o   <= (A_i AND B_i); 
    Sum_o <= (A_i XOR B_i XOR Cin_i);
END Behavioral;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lookahd is
    GENERIC ( N : INTEGER := 16 ); 
    Port (
        A_i     : IN  STD_LOGIC_VECTOR(N-1 DOWNTO 0);
        B_i     : IN  STD_LOGIC_VECTOR(N-1 DOWNTO 0);
        S_o     : OUT  STD_LOGIC_VECTOR(N-1 DOWNTO 0);
        Cin_i   : IN  STD_LOGIC; 
        Cout_o  : OUT STD_LOGIC
    );
end lookahd;

ARCHITECTURE Behavioral OF lookahd IS

SIGNAL p    : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
SIGNAL g    : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
SIGNAL c    : STD_LOGIC_VECTOR(N-1 DOWNTO 0);

COMPONENT pgs_logic IS
   PORT (  A_i    : IN  STD_LOGIC;
           B_i    : IN  STD_LOGIC;
           Cin_i  : IN  STD_LOGIC;
           Sum_o  : OUT STD_LOGIC;
           P_o    : OUT STD_LOGIC;
           G_o    : OUT STD_LOGIC);
END COMPONENT;

BEGIN 

    c(0) <= Cin_i;

    gen_propagation_logic: FOR i IN 1 TO N-1 GENERATE
       c(i) <= (g(i-1) OR (p(i-1) AND c(i-1)));
    END GENERATE gen_propagation_logic;

    gen_pgs_logic: FOR i IN 0 TO N-1 GENERATE
        pgs_logic_inst: pgs_logic PORT MAP(A_i(i), B_i(i), c(i), S_o(i), p(i), g(i));
    END GENERATE gen_pgs_logic;

    Cout_o <= c(N-1);

END;