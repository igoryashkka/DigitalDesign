LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY tb_addsub IS
END tb_addsub;

ARCHITECTURE Behavioral OF tb_addsub IS

    CONSTANT N : INTEGER := 8;
    
    SIGNAL A_i     : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
    SIGNAL B_i     : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
    SIGNAL Sub_i   : STD_LOGIC;
    SIGNAL Diff_o  : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
    SIGNAL Borrow_o: STD_LOGIC;
    
    COMPONENT addsub
        GENERIC ( N : INTEGER := 8 );
        PORT ( A_i     : IN  STD_LOGIC_VECTOR(N-1 DOWNTO 0);
               B_i     : IN  STD_LOGIC_VECTOR(N-1 DOWNTO 0);
               Sub_i   : IN  STD_LOGIC;
               Diff_o  : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0);
               Borrow_o: OUT STD_LOGIC );
    END COMPONENT;

BEGIN

    UUT: addsub GENERIC MAP (N => 8) PORT MAP (
        A_i     => A_i,
        B_i     => B_i,
        Sub_i   => Sub_i,
        Diff_o  => Diff_o,
        Borrow_o => Borrow_o
    );

    PROCESS
    BEGIN
        
        A_i <= "00001010"; -- 10
        B_i <= "00000101"; -- 5
        Sub_i <= '1';
        WAIT FOR 10 ns;

        
        A_i <= "00000101"; -- 5
        B_i <= "00001010"; -- 10
        Sub_i <= '1';
        WAIT FOR 10 ns;

        
        A_i <= "00010100"; -- 20
        B_i <= "00010100"; -- 20
        Sub_i <= '1';
        WAIT FOR 10 ns;

       
        A_i <= "00110010"; -- 50
        B_i <= "00011001"; -- 25
        Sub_i <= '1';
        WAIT FOR 10 ns;

        
        A_i <= "00110010"; -- 50
        B_i <= "00011001"; -- 25
        Sub_i <= '0';
        WAIT FOR 10 ns;
        
        WAIT;
    END PROCESS;

END Behavioral;
