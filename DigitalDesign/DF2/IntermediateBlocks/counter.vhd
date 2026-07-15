LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;  

ENTITY counter IS
    PORT (
        clk_i   : IN  STD_LOGIC;       
        reset_i : IN  STD_LOGIC;        
        enable_i: IN  STD_LOGIC;        
        count_o : OUT STD_LOGIC_VECTOR(2 DOWNTO 0) 
    );
END counter ;

ARCHITECTURE Behavioral OF counter IS
    SIGNAL cnt_s : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000"; 
BEGIN
    PROCESS (clk_i)
    BEGIN
        IF rising_edge(clk_i) THEN
            IF reset_i = '1' THEN
                cnt_s <= "000";
            ELSIF enable_i = '1' THEN
                cnt_s <= STD_LOGIC_VECTOR(UNSIGNED(cnt_s) + 1);
            END IF;
        END IF;
    END PROCESS;

    count_o <= cnt_s;

END Behavioral;
