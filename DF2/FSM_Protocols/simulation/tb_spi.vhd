LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY TB_SPI IS
END TB_SPI;

ARCHITECTURE BEHAVIORAL OF TB_SPI IS

    CONSTANT N : INTEGER := 8;

    COMPONENT SPI_MASTER
        GENERIC (N : INTEGER := 8);
        PORT (
            CLK_i        : IN  STD_LOGIC;
            Reset_i      : IN  STD_LOGIC;
            Start_i      : IN  STD_LOGIC;
            MSIO_i       : IN  STD_LOGIC;
            InputData_i  : IN  STD_LOGIC_VECTOR(N-1 DOWNTO 0);
            Mosi_o       : OUT STD_LOGIC;
            Done_o       : OUT STD_LOGIC;
            SCK_o        : OUT STD_LOGIC;
            CS_o         : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT SPI_SLAVE
        GENERIC (N : INTEGER := 8);
        PORT (
            Reset_i       : IN  STD_LOGIC;
            SCK_i         : IN  STD_LOGIC;
            CS_i          : IN  STD_LOGIC;
            MOSI_i        : IN  STD_LOGIC;
            MISO_o        : OUT STD_LOGIC;
            OutputData_o  : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0);
            Received_o    : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL CLK_i        : STD_LOGIC := '0';
    SIGNAL Reset_i      : STD_LOGIC := '0';
    SIGNAL Start_i      : STD_LOGIC := '0';
    SIGNAL MSIO_i       : STD_LOGIC := '0';
    SIGNAL InputData_i  : STD_LOGIC_VECTOR(N-1 DOWNTO 0) := "10101010";
    SIGNAL Mosi_o       : STD_LOGIC;
    SIGNAL Done_o       : STD_LOGIC;
    SIGNAL SCK_o        : STD_LOGIC;
    SIGNAL CS_o         : STD_LOGIC;

    SIGNAL OutputData_o : STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Received_o   : STD_LOGIC := '0';

    CONSTANT CLK_PERIOD : TIME := 10 NS;

BEGIN

    UUT_Master : SPI_MASTER
        GENERIC MAP (N => N)
        PORT MAP (
            CLK_i        => CLK_i,
            Reset_i      => Reset_i,
            Start_i      => Start_i,
            MSIO_i       => MSIO_i,
            InputData_i  => InputData_i,
            Mosi_o       => Mosi_o,
            Done_o       => Done_o,
            SCK_o        => SCK_o,
            CS_o         => CS_o
        );

    UUT_Slave : SPI_SLAVE
        GENERIC MAP (N => N)
        PORT MAP (
            Reset_i      => Reset_i,
            SCK_i        => SCK_o,
            CS_i         => CS_o,
            MOSI_i       => Mosi_o,
            MISO_o       => MSIO_i,
            OutputData_o => OutputData_o,
            Received_o   => Received_o
        );

    CLK_PROCESS : PROCESS
    BEGIN
        CLK_i <= '0';
        WAIT FOR CLK_PERIOD / 2;
        CLK_i <= '1';
        WAIT FOR CLK_PERIOD / 2;
    END PROCESS;

    STIM_PROC : PROCESS
    BEGIN
        Reset_i <= '1';
        WAIT FOR 20 NS;
        Reset_i <= '0';
        WAIT FOR 20 NS;

        Start_i <= '1';
        WAIT FOR CLK_PERIOD;
        Start_i <= '0';

        WAIT UNTIL Done_o = '1';

        WAIT FOR 50 NS;
        ASSERT OutputData_o = InputData_i
            REPORT "SPI DATA MISMATCH!" SEVERITY ERROR;

        WAIT;
    END PROCESS;

END BEHAVIORAL;
