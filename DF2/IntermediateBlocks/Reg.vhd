LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY Register_4Bit IS
    PORT (
        clk_i    : IN  STD_LOGIC;        
        reset_i  : IN  STD_LOGIC;        
        enable_i : IN  STD_LOGIC;        
        D_i      : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);  
        Q_o      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)   
    );
END Register_4Bit;

ARCHITECTURE Behavioral OF Register_4Bit IS
BEGIN
    PROCESS (clk_i)
    BEGIN
        IF rising_edge(clk_i) THEN
            IF reset_i = '1' THEN
                Q_o <= (OTHERS => '0');
            ELSIF enable_i = '1' THEN
                Q_o <= D_i;
            END IF;
        END IF;
    END PROCESS;

END Behavioral;
