library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity spi_master is
    generic (N : integer := 8);
    port (
        clk_c                : in  std_logic;
        reset_r              : in  std_logic;
        start_i              : in  std_logic;
        miso_i               : in  std_logic;
        inputData_i          : in  std_logic_vector(N-1 downto 0);
        mosi_o               : out std_logic;
        done_o               : out std_logic;
        outData_o            : out std_logic_vector(N-1 downto 0);
        sck                  : out std_logic
    );
end spi_master;

architecture Behavioral of spi_master is

    signal peripheralEN, writeInputDataFlag, dataSentFlag, lastNumber_o : std_logic;
    signal transientSlaveData : std_logic_vector(N-1 downto 0);
    
    
    type stateType is (preparingData, transmitData, complete);
    signal state, nextState : stateType;
    
    signal bit_count : integer range 0 to N := 0;
    
begin
    
    -- FSM Process
    process(clk_c, reset_r)
    begin
        if reset_r = '1' then
            state <= preparingData;
        elsif rising_edge(clk_c) then
            state <= nextState;
        end if;
    end process;
    
    -- State Logic
    process(state, start_i, lastNumber_o)
    begin
        case state is
            when preparingData =>
                if start_i = '1' then
                    nextState <= transmitData;
                else
                    nextState <= preparingData;
                end if;
            
            when transmitData =>
                if lastNumber_o = '1' then
                    nextState <= complete;
                else
                    nextState <= transmitData;
                end if;
            
            when complete =>
                nextState <= preparingData;
        end case;
    end process;
    
    -- Output Logic
    peripheralEN <= '1' when state = transmitData else '0';
    dataSentFlag <= '1' when state = complete else '0';
    writeInputDataFlag <= '1' when state = preparingData else '0';
    
    -- Shift Register 
    process(clk_c, reset_r)
    begin
        if reset_r = '1' then
            transientSlaveData <= (others => '0');
        elsif rising_edge(clk_c) then
            if writeInputDataFlag = '1' then
                transientSlaveData <= inputData_i;
            elsif peripheralEN = '1' then
                transientSlaveData <= transientSlaveData(N-2 downto 0) & miso_i;
            end if;
        end if;
    end process;
    
    -- Outputs
    mosi_o <= transientSlaveData(N-1);
    done_o <= dataSentFlag;
    outData_o <= transientSlaveData when dataSentFlag = '1' else (others => '0');
    sck <= clk_c when peripheralEN = '1' else '1';
    
    -- Bit Counter 
    process(clk_c, reset_r)
    begin
        if reset_r = '1' then
            bit_count <= 0;
        elsif rising_edge(clk_c) then
            if peripheralEN = '1' then
                bit_count <= bit_count + 1;
            else
                bit_count <= 0;
            end if;
        end if;
    end process;
    
    lastNumber_o <= '1' when bit_count = N-1 else '0';
    
end Behavioral;