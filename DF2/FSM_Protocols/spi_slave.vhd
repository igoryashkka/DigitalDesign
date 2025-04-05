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
    SIGNAL ShiftReg_RX  : STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL ShiftReg_TX  : STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '1');
    SIGNAL BitCount     : INTEGER RANGE 0 TO N := 0;
    SIGNAL Received_r   : STD_LOGIC := '0';
    SIGNAL received_r1  : STD_LOGIC := '0';
    SIGNAL received_r2  : STD_LOGIC := '0';
BEGIN

    PROCESS(SCK_i, Reset_i)
    BEGIN
        IF Reset_i = '1' THEN
            ShiftReg_RX <= (OTHERS => '0');
            ShiftReg_TX <= (OTHERS => '1');
            BitCount    <= 0;
            OutputData_o <= (OTHERS => '0');
            Received_r  <= '0';
            ShiftReg_TX <= "10101010"; 
        ELSIF FALLING_EDGE(SCK_i) THEN
            ShiftReg_RX <= ShiftReg_RX(N-2 DOWNTO 0) & MOSI_i;
            ShiftReg_TX <= ShiftReg_TX(N-2 DOWNTO 0) & '0';
            BitCount    <= BitCount + 1;
            IF BitCount = N-1 THEN
                OutputData_o <= ShiftReg_RX(N-2 DOWNTO 0) & MOSI_i;
                Received_r   <= '1';
                BitCount     <= 0;
            ELSE
                Received_r <= '0';
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
    MISO_o <= ShiftReg_TX(N-1);

END BEHAVIORAL;