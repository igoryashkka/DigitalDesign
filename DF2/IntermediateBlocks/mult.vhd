LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY FullAdder IS
    PORT (
        A_i    : IN  STD_LOGIC;
        B_i    : IN  STD_LOGIC;
        Cin_i  : IN  STD_LOGIC;
        Sum_o  : OUT STD_LOGIC;
        Cout_o : OUT STD_LOGIC
    );
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
ENTITY mult IS
    PORT (
        A_i : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        B_i : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        P_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END mult;

ARCHITECTURE Behavioral OF mult IS

    TYPE partial_products_array IS ARRAY (3 DOWNTO 0) OF STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL partial_products : partial_products_array;
    SIGNAL sum   : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');
    SIGNAL carry : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');

    COMPONENT FullAdder IS
        PORT (
            A_i    : IN  STD_LOGIC;
            B_i    : IN  STD_LOGIC;
            Cin_i  : IN  STD_LOGIC;
            Sum_o  : OUT STD_LOGIC;
            Cout_o : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN
   
    GEN_PARTIAL_PRODUCTS: FOR i IN 0 TO 3 GENERATE
        GEN_BITS: FOR j IN 0 TO 3 GENERATE
            partial_products(i)(j) <= A_i(j) AND B_i(i);
        END GENERATE;
    END GENERATE;

    P_o(0) <= partial_products(0)(0);
    

    ADD_1_1: FullAdder PORT MAP(partial_products(0)(1), partial_products(1)(0), '0', P_o(1), carry(0));
    ADD_1_2: FullAdder PORT MAP(partial_products(0)(2), partial_products(1)(1), carry(0), sum(0), carry(1));
    ADD_1_3: FullAdder PORT MAP(partial_products(0)(3), partial_products(1)(2), carry(1), sum(1), carry(2));
    ADD_1_4: FullAdder PORT MAP('0', partial_products(1)(3), carry(2), sum(2), carry(3));

    ADD_2_1: FullAdder PORT MAP(sum(0), partial_products(2)(0), '0', P_o(2), carry(4));
    ADD_2_2: FullAdder PORT MAP(sum(1), partial_products(2)(1), carry(4), sum(3), carry(5));
    ADD_2_3: FullAdder PORT MAP(sum(2), partial_products(2)(2), carry(5), sum(4), carry(6));
    ADD_2_4: FullAdder PORT MAP(carry(3), partial_products(2)(3), carry(6), sum(5), carry(7));

    ADD_3_1: FullAdder PORT MAP(sum(3), partial_products(3)(0), '0', P_o(3), carry(8));
    ADD_3_2: FullAdder PORT MAP(sum(4), partial_products(3)(1), carry(8), P_o(4), carry(9));
    ADD_3_3: FullAdder PORT MAP(sum(5), partial_products(3)(2), carry(9), P_o(5), carry(10));
    ADD_3_4: FullAdder PORT MAP(carry(7), partial_products(3)(3), carry(10), P_o(6), carry(11));

  
    P_o(7) <= carry(11);

END Behavioral;
