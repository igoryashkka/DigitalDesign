LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY tb_mult IS
END tb_mult;

ARCHITECTURE Behavioral OF tb_mult IS

    COMPONENT mult
        PORT ( A_i  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
               B_i  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
               P_o  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)); 
    END COMPONENT;

    SIGNAL A_i : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL B_i : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL P_o : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

    DUT: mult PORT MAP(
        A_i => A_i,
        B_i => B_i,
        P_o => P_o
    );

    PROCESS
    BEGIN

        A_i <= "0011";  -- 3
        B_i <= "0010";  -- 2
        WAIT FOR 20 ns;
        A_i <= "0111";  -- 7
        B_i <= "0101";  -- 5
        WAIT FOR 20 ns;
        A_i <= "1011";  -- 11
        B_i <= "1101";  -- 13
        WAIT FOR 20 ns;
        A_i <= "1111";  -- 15
        B_i <= "1111";  -- 15
        WAIT FOR 20 ns;

        WAIT;
    END PROCESS;

END Behavioral;
