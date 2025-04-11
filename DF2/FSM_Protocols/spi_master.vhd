LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY SPI_MASTER IS
    GENERIC (N : INTEGER := 8);
    PORT (
        CLK_i        : IN  STD_LOGIC;
        Reset_i      : IN  STD_LOGIC;
        Start_i      : IN  STD_LOGIC;
        MSIO_i       : IN  STD_LOGIC;
        InputData_i  : IN  STD_LOGIC_VECTOR(N-1 DOWNTO 0);
        Mosi_o       : OUT STD_LOGIC;
        Done_o       : OUT STD_LOGIC;
        SCK_o        : OUT STD_LOGIC
    );
END SPI_MASTER;

ARCHITECTURE BEHAVIORAL OF SPI_MASTER IS
    TYPE StateType IS (IDLE, TRANSMIT, COMPLETE);
    SIGNAL State         : StateType := IDLE;
    SIGNAL ShiftReg_TX   : STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL ShiftReg_RX   : STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL BitCount      : INTEGER RANGE 0 TO N := 0;
    SIGNAL SCK_Reg       : STD_LOGIC := '0';
BEGIN

    PROCESS(CLK_i, Reset_i)
    BEGIN
        IF Reset_i = '1' THEN
            State        <= IDLE;
            ShiftReg_TX  <= (OTHERS => '0');
            ShiftReg_RX  <= (OTHERS => '0');
            BitCount     <= 0;
            SCK_Reg      <= '0';
            Done_o       <= '0';

        ELSIF RISING_EDGE(CLK_i) THEN
            CASE State IS
                WHEN IDLE =>
                    SCK_Reg     <= '0';
                    Done_o      <= '0';
                    IF Start_i = '1' THEN
                        ShiftReg_TX <= InputData_i;
                        BitCount    <= 0;
                        State       <= TRANSMIT;
                    END IF;

                WHEN TRANSMIT =>
                    IF SCK_Reg = '0' THEN
                        ShiftReg_RX <= ShiftReg_RX(N-2 DOWNTO 0) & MSIO_i;
                        ShiftReg_TX <= ShiftReg_TX(N-2 DOWNTO 0) & '0';
                        BitCount <= BitCount + 1;
                        SCK_Reg <= '1';
                        IF BitCount = N - 1 THEN
                            State <= COMPLETE;
                        ELSE 
                            State <= TRANSMIT;
                        END IF;
                    ELSE
                        SCK_Reg <= '0';
                    END IF;

                WHEN COMPLETE =>
                    Done_o <= '1';
                    State  <= IDLE;
            END CASE;
        END IF;
    END PROCESS;

    Mosi_o <= ShiftReg_TX(N-1);
    SCK_o  <= SCK_Reg;

END BEHAVIORAL;
