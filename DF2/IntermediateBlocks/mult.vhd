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

    SIGNAL sum   : STD_LOGIC_VECTOR(6 DOWNTO 0) := (OTHERS => '0');
    SIGNAL carry : STD_LOGIC_VECTOR(6 DOWNTO 0) := (OTHERS => '0');

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


    GEN_FULLADDERS: FOR i IN 1 TO 6 GENERATE
        FullAdder_inst: FullAdder
        PORT MAP(
            A_i    => partial_products(i MOD 4)(i / 4),
            B_i    => sum(i-1),
            Cin_i  => carry(i-1),
            Sum_o  => sum(i),
            Cout_o => carry(i)
        );
    END GENERATE;

 
    P_o(1 DOWNTO  6) <= sum(1 DOWNTO  6);
    P_o(7)      <= carry(6);

END Behavioral;
