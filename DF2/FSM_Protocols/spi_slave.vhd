LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY SPI_SLAVE IS
    GENERIC (N : INTEGER := 8);
    PORT (
        clk_i         : IN  STD_LOGIC;
        Reset_i       : IN  STD_LOGIC;
        SCK_i         : IN  STD_LOGIC;
        MOSI_i        : IN  STD_LOGIC;
        MISO_o        : OUT STD_LOGIC;
        OutputData_o  : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0);
        Received_o    : OUT STD_LOGIC
    );
END SPI_SLAVE;

ARCHITECTURE BEHAVIORAL OF SPI_SLAVE IS
    SIGNAL ShiftReg     : STD_LOGIC_VECTOR(N-1 DOWNTO 0);
    SIGNAL BitCount     : INTEGER RANGE 0 TO N := 0;
    SIGNAL Received_r   : STD_LOGIC := '0';
    SIGNAL received_r1  : STD_LOGIC := '0';
    SIGNAL received_r2  : STD_LOGIC := '0';
BEGIN

    
    PROCESS(SCK_i, Reset_i)
    BEGIN
        IF Reset_i = '1' THEN
            ShiftReg     <= (OTHERS => '0');
            BitCount     <= 0;
            Received_r   <= '0';
            OutputData_o <= (OTHERS => '0');
        ELSIF FALLING_EDGE(SCK_i) THEN
            ShiftReg <= ShiftReg(N-2 DOWNTO 0) & MOSI_i;
            BitCount <= BitCount + 1;
            IF BitCount = N-1 THEN
                OutputData_o <= ShiftReg(N-2 DOWNTO 0) & MOSI_i;
                Received_r   <= '1';
            ELSE
                Received_r   <= '0';
            END IF;
        END IF;
    END PROCESS;

    
    PROCESS(clk_i)
    BEGIN
        IF rising_edge(clk_i) THEN
            received_r1 <= Received_r;
            received_r2 <= received_r1;
        END IF;
    END PROCESS;

    
    Received_o <= received_r2;
    MISO_o <= ShiftReg(N-1);

END BEHAVIORAL;  
