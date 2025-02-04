LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY tb_mult IS
END tb_mult;

ARCHITECTURE Behavioral OF tb_mult IS

    COMPONENT mult
        PORT (
            A_i  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
            B_i  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
            P_o  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        ); 
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

        A_i <= "0000"; B_i <= "0000"; WAIT FOR 20 ns;  -- 0 * 0 = 0
        A_i <= "0001"; B_i <= "0001"; WAIT FOR 20 ns;  -- 1 * 1 = 1
        A_i <= "1111"; B_i <= "1111"; WAIT FOR 20 ns;  -- 15 * 15 = 225
        A_i <= "0011"; B_i <= "0010"; WAIT FOR 20 ns;  -- 3 * 2 = 6
        A_i <= "0101"; B_i <= "0011"; WAIT FOR 20 ns;  -- 5 * 3 = 15
        A_i <= "0111"; B_i <= "0101"; WAIT FOR 20 ns;  -- 7 * 5 = 35
        A_i <= "1001"; B_i <= "0110"; WAIT FOR 20 ns;  -- 9 * 6 = 54
        A_i <= "1100"; B_i <= "1001"; WAIT FOR 20 ns;  -- 12 * 9 = 108
        A_i <= "0000"; B_i <= "1010"; WAIT FOR 20 ns;  -- 0 * 10 = 0
        A_i <= "1010"; B_i <= "0000"; WAIT FOR 20 ns;  -- 10 * 0 = 0
        A_i <= "0001"; B_i <= "1100"; WAIT FOR 20 ns;  -- 1 * 12 = 12
        A_i <= "1100"; B_i <= "0001"; WAIT FOR 20 ns;  -- 12 * 1 = 12
        A_i <= "0110"; B_i <= "1111"; WAIT FOR 20 ns;  -- 6 * 15 = 90
        A_i <= "1111"; B_i <= "0110"; WAIT FOR 20 ns;  -- 15 * 6 = 90
        A_i <= "1011"; B_i <= "1011"; WAIT FOR 20 ns;  -- 11 * 11 = 121
        A_i <= "1000"; B_i <= "1000"; WAIT FOR 20 ns;  -- 8 * 8 = 64
        A_i <= "0110"; B_i <= "0110"; WAIT FOR 20 ns;  -- 6 * 6 = 36
        A_i <= "0100"; B_i <= "0011"; WAIT FOR 20 ns;  -- 4 * 3 = 12
        A_i <= "0101"; B_i <= "0100"; WAIT FOR 20 ns;  -- 5 * 4 = 20
        A_i <= "0111"; B_i <= "0110"; WAIT FOR 20 ns;  -- 7 * 6 = 42
        A_i <= "1001"; B_i <= "0101"; WAIT FOR 20 ns;  -- 9 * 5 = 45
        A_i <= "1011"; B_i <= "0111"; WAIT FOR 20 ns;  -- 11 * 7 = 77
        
        WAIT;
    END PROCESS;

END Behavioral;
