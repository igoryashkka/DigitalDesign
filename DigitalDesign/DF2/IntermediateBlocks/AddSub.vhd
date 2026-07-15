LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY FullAdder IS
    PORT ( A_i    : IN  STD_LOGIC;
           B_i    : IN  STD_LOGIC;
           Cin_i  : IN  STD_LOGIC;
           Sum_o  : OUT STD_LOGIC;
           Cout_o : OUT STD_LOGIC);
END FullAdder;

ARCHITECTURE Behavioral OF FullAdder IS
BEGIN
    Sum_o   <= (A_i XOR B_i) XOR Cin_i;
    Cout_o  <= (A_i AND B_i) OR (Cin_i AND (A_i XOR B_i));
END Behavioral;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY addsub IS
    GENERIC ( N : INTEGER := 8 ); 
    PORT ( A_i     : IN  STD_LOGIC_VECTOR(N-1 DOWNTO 0);
           B_i     : IN  STD_LOGIC_VECTOR(N-1 DOWNTO 0);
           Sub_i   : IN  STD_LOGIC; 
           Diff_o  : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0);
           Borrow_o: OUT STD_LOGIC); 
END addsub;

ARCHITECTURE Behavioral OF addsub IS
    SIGNAL Carry_chain  : STD_LOGIC_VECTOR(N DOWNTO 0); 
    SIGNAL temp_diff    : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
    SIGNAL B_complement : STD_LOGIC_VECTOR(N-1 DOWNTO 0);

    COMPONENT FullAdder IS
        PORT ( A_i     : IN  STD_LOGIC;
               B_i     : IN  STD_LOGIC;
               Cin_i   : IN  STD_LOGIC;
               Sum_o   : OUT STD_LOGIC;
               Cout_o  : OUT STD_LOGIC);
    END COMPONENT;

BEGIN
    B_complement <= NOT B_i WHEN Sub_i = '1' ELSE B_i;
    Carry_chain(0) <= Sub_i;

    gen_full_adders : FOR i IN 0 TO N-1 GENERATE
    BEGIN
        FA_inst : FullAdder PORT MAP (
            A_i     => A_i(i),
            B_i     => B_complement(i),
            Cin_i   => Carry_chain(i),
            Sum_o   => temp_diff(i),
            Cout_o  => Carry_chain(i+1) 
        );
    END GENERATE gen_full_adders;

    Diff_o <= temp_diff;
    Borrow_o <= Carry_chain(N); 

END Behavioral;
