library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_spi is
end tb_spi;

architecture Behavioral of tb_spi is

    constant N : integer := 8;

    -- Component declaration for SPI Master
    component spi_master
        generic (N : integer := 8);
        port (
            clk_c       : in  std_logic;
            reset_r     : in  std_logic;
            start_i     : in  std_logic;
            miso_i      : in  std_logic;
            inputData_i : in  std_logic_vector(N-1 downto 0);
            mosi_o      : out std_logic;
            done_o      : out std_logic;
            sck         : out std_logic;
            cs          : out std_logic
        );
    end component;

    -- Component declaration for SPI Slave
    component spi_slave
        generic (N : integer := 8);
        port (
            clk_c        : in  std_logic;
            reset_r      : in  std_logic;
            sck          : in  std_logic;
            cs           : in  std_logic;
            mosi_i       : in  std_logic;
            miso_o       : out std_logic;
            outputData_o : out std_logic_vector(N-1 downto 0);
            received_o   : out std_logic
        );
    end component;

    -- signals for SPI Master
    signal clk_c        : std_logic := '0';
    signal reset_r      : std_logic := '0';
    signal start_i      : std_logic := '0';
    signal miso_i       : std_logic;
    signal inputData_i  : std_logic_vector(N-1 downto 0) := "10101010";
    signal mosi_o       : std_logic;
    signal done_o       : std_logic;
    signal sck          : std_logic;
    signal cs           : std_logic;

    -- signals for SPI Slave
    signal outputData_o : std_logic_vector(N-1 downto 0);
    signal received_o   : std_logic;

    -- clock generation
    constant clk_period : time := 10 ns;

begin

    -- instantiate SPI master
    UUT_Master: spi_master
        generic map(N => N)
        port map(
            clk_c       => clk_c,
            reset_r     => reset_r,
            start_i     => start_i,
            miso_i      => miso_i,
            inputData_i => inputData_i,
            mosi_o      => mosi_o,
            done_o      => done_o,
            sck         => sck,
            cs          => cs
        );

    -- instantiate SPI slave
    UUT_Slave: spi_slave
        generic map(N => N)
        port map(
            clk_c        => clk_c,
            reset_r      => reset_r,
            sck          => sck,
            cs           => cs,
            mosi_i       => mosi_o,
            miso_o       => miso_i,
            outputData_o => outputData_o,
            received_o   => received_o
        );

    -- Clock process
    clk_process: process
    begin
        while True loop
            clk_c <= '0';
            wait for clk_period / 2;
            clk_c <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Reset sequence
        reset_r <= '1';
        wait for 20 ns;
        reset_r <= '0';
        wait for 20 ns;

        -- Start transmission
        start_i <= '1';
        wait for clk_period;
        start_i <= '0';

        -- Wait until transmission is done
        wait until done_o = '1';

        -- Check received data at slave
        wait for 20 ns;

        --assert outputData_o = inputData_i
        --report "SPI Transfer failed: Data mismatch" severity error;

        --assert received_o = '1'
        --report "SPI Transfer failed: Slave didn't indicate reception" severity error;

        wait for 50 ns;

        -- Finish simulation
        --assert false
        --report "Simulation ended successfully" severity failure;
    end process;

end Behavioral;
