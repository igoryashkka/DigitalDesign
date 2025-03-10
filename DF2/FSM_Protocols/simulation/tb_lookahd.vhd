LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY tb_lookahd IS
END tb_lookahd;

ARCHITECTURE behavior OF tb_lookahd IS

    CONSTANT N : INTEGER := 16;
    
    SIGNAL A_i   : STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL B_i   : STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL S_o   : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
    SIGNAL Cin_i : STD_LOGIC := '0';
    SIGNAL Cout_o: STD_LOGIC;

    COMPONENT lookahd
        GENERIC ( N : INTEGER := 16 );
        PORT (
            A_i   : IN  STD_LOGIC_VECTOR(N-1 DOWNTO 0);
            B_i   : IN  STD_LOGIC_VECTOR(N-1 DOWNTO 0);
            S_o   : OUT  STD_LOGIC_VECTOR(N-1 DOWNTO 0);
            Cin_i : IN  STD_LOGIC;
            Cout_o: OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN
    uut: lookahd
        GENERIC MAP (N => N)
        PORT MAP (
            A_i   => A_i,
            B_i   => B_i,
            S_o   => S_o,
            Cin_i => Cin_i,
            Cout_o=> Cout_o
        );
    
    stim_proc: PROCESS
    BEGIN        
        -- Test Case 1: 0 + 0
        A_i <= "0000000000000000";
        B_i <= "0000000000000000";
        Cin_i <= '0';
        WAIT FOR 10 ns;
        
        -- Test Case 2: 1 + 1
        A_i <= "0000000000000001";
        B_i <= "0000000000000001";
        Cin_i <= '0';
        WAIT FOR 10 ns;
        
        -- Test Case 3: 65535 + 4369     
        A_i <= "1010101010101010";
        B_i <= "0101010101010101";
        Cin_i <= '0';
        WAIT FOR 10 ns;
        
        -- Test Case 4: 65535 + 1
        A_i <= "1111111111111111";
        B_i <= "0000000000000001";
        Cin_i <= '1';
        WAIT FOR 10 ns;
        
        WAIT;
    END PROCESS;
END behavior;
