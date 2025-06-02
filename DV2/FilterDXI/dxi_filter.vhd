LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY dxi_top IS
    PORT (
        -- General signals
        i_clk           : IN  std_logic;
        i_rstn          : IN  std_logic;

        -- DXI interface signals SLAVE        
        i_dxi_valid     : IN  std_logic;
        i_dxi_data      : IN  std_logic_vector(31 DOWNTO 0);
        o_dxi_ready     : OUT std_logic;

        -- DXI interface signals MASTER
        i_dxi_out_ready : IN  std_logic;
        o_dxi_out_valid : OUT std_logic;
        o_master_data   : OUT std_logic_vector(39 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE rtl OF dxi_top IS

    -- Internal control and data signals
    SIGNAL data_buffer     : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL comb_result     : std_logic_vector(39 DOWNTO 0) := (OTHERS => '0');

    SIGNAL slave_valid     : std_logic := '0';
    SIGNAL comb_start      : std_logic := '0';
    SIGNAL comb_done       : std_logic := '0';
    SIGNAL master_valid    : std_logic := '0';

    SIGNAL o_dxi_ready_reg : std_logic := '0';

BEGIN

    --------------------------------------------------------------------
    -- Stage 1: Slave Receiver
    --------------------------------------------------------------------
    slave_proc : PROCESS(i_clk)
    BEGIN
        IF rising_edge(i_clk) THEN
            IF i_rstn = '0' THEN
                slave_valid     <= '0';
                o_dxi_ready_reg <= '0';
                comb_start      <= '0';
            ELSE
                IF slave_valid = '0' THEN
                    o_dxi_ready_reg <= '1';
                    IF i_dxi_valid = '1' THEN
                        data_buffer     <= i_dxi_data;
                        slave_valid     <= '1';
                        comb_start      <= '1';
                        o_dxi_ready_reg <= '0';
                    END IF;
                ELSE
                    o_dxi_ready_reg <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS;

    o_dxi_ready <= o_dxi_ready_reg;

    --------------------------------------------------------------------
    -- Stage 2: Synchronous Combinational Logic
    --------------------------------------------------------------------
    comb_proc : PROCESS(i_clk)
        VARIABLE v_temp : unsigned(39 DOWNTO 0);
    BEGIN
        IF rising_edge(i_clk) THEN
            IF i_rstn = '0' THEN
                comb_result <= (OTHERS => '0');
                comb_done   <= '0';
                comb_start  <= '0';
            ELSIF comb_start = '1' THEN
                v_temp := (OTHERS => '0');
                v_temp := TO_UNSIGNED(3, 8)  * unsigned(data_buffer(7 DOWNTO 0)) +
                          TO_UNSIGNED(5, 8)  * unsigned(data_buffer(15 DOWNTO 8)) +
                          TO_UNSIGNED(7, 8)  * unsigned(data_buffer(23 DOWNTO 16)) +
                          TO_UNSIGNED(11, 8) * unsigned(data_buffer(31 DOWNTO 24));
                comb_result <= std_logic_vector(v_temp);
                comb_done   <= '1';
                comb_start  <= '0';
            ELSE
                comb_done <= '0';
            END IF;
        END IF;
    END PROCESS;

    --------------------------------------------------------------------
    -- Stage 3: Master Transmitter
    --------------------------------------------------------------------
    master_proc : PROCESS(i_clk)
    BEGIN
        IF rising_edge(i_clk) THEN
            IF i_rstn = '0' THEN
                o_master_data  <= (OTHERS => '0');
                master_valid   <= '0';
                slave_valid    <= '0';
            ELSIF comb_done = '1' THEN
                o_master_data <= comb_result;
                master_valid  <= '1';
            ELSIF master_valid = '1' AND i_dxi_out_ready = '1' THEN
                master_valid  <= '0';
                slave_valid   <= '0';
            END IF;
        END IF;
    END PROCESS;

    o_dxi_out_valid <= master_valid;

END ARCHITECTURE;
