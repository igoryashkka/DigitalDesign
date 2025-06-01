LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY dxi_top IS
    PORT (
        -- general signals
        i_clk          : IN  std_logic;
        i_rstn         : IN  std_logic;

        -- DXI interface signals SLAVE        
        i_dxi_valid    : IN  std_logic;
        i_dxi_data     : IN  std_logic_vector(31 DOWNTO 0);
        o_dxi_ready    : OUT std_logic;

        -- DXI interface signals MASTER
        i_dxi_out_ready : IN  std_logic;
        o_dxi_out_valid : OUT std_logic;
        o_master_data  : OUT std_logic_vector(39 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE rtl OF dxi_top IS

    SIGNAL data_reg        : std_logic_vector(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL comb_result     : std_logic_vector(39 DOWNTO 0) := (OTHERS => '0');
    SIGNAL comb_valid      : std_logic := '0';

    SIGNAL o_dxi_ready_reg : std_logic := '0';
    SIGNAL o_master_valid_reg : std_logic := '0';

BEGIN
    --------------------------------------------------------------------
    -- Slave Process: capture data only if ready and valid
    --------------------------------------------------------------------
    slave_process : PROCESS(i_clk)
    BEGIN
        IF rising_edge(i_clk) THEN
            IF i_rstn = '0' THEN
                data_reg       <= (OTHERS => '0');
                comb_valid     <= '0';
                o_dxi_ready_reg <= '0';
            ELSE
                
                IF comb_valid = '0' THEN
                    o_dxi_ready_reg <= '1'; -- case when we tell for TB_Master we are ready
                ELSE
                    o_dxi_ready_reg <= '0';
                END IF;

                -- Capture input data only if valid and we are ready
                IF i_dxi_valid = '1' AND o_dxi_ready_reg = '1' THEN
                    data_reg   <= i_dxi_data;
                    comb_valid <= '1';
                END IF;
            END IF;
        END IF;
    END PROCESS;

    o_dxi_ready <= o_dxi_ready_reg;



    --------------------------------------------------------------------
    -- Combinational Block  - must check some flag if its ready to outs
    --------------------------------------------------------------------
    comb_logic : PROCESS(data_reg)
        VARIABLE v_temp : unsigned(39 DOWNTO 0);
    BEGIN
        v_temp := (OTHERS => '0');
        v_temp := v_temp +
                  (TO_UNSIGNED(3, 8) * unsigned(data_reg(7 DOWNTO 0))) +
                  (TO_UNSIGNED(5, 8) * unsigned(data_reg(15 DOWNTO 8))) +
                  (TO_UNSIGNED(7, 8) * unsigned(data_reg(23 DOWNTO 16))) +
                  (TO_UNSIGNED(11, 8) * unsigned(data_reg(31 DOWNTO 24)));
        comb_result <= std_logic_vector(v_temp);
    END PROCESS;


    --------------------------------------------------------------------
    -- Master Process: transmit result if master is ready
    --------------------------------------------------------------------
    master_process : PROCESS(i_clk)
    BEGIN
        IF rising_edge(i_clk) THEN
            IF i_rstn = '0' THEN
                o_master_data      <= (OTHERS => '0');
                o_master_valid_reg <= '0';
                comb_valid         <= '0';
            ELSIF comb_valid = '1' THEN
                IF i_dxi_out_ready = '1' THEN
                    o_master_data      <= comb_result;
                    o_master_valid_reg <= '1';
                    comb_valid         <= '0'; -- data sent
                ELSE
                    o_master_valid_reg <= '1'; -- hold valid high
                END IF;
            ELSE
                o_master_valid_reg <= '0';
            END IF;
        END IF;
    END PROCESS;

    o_dxi_out_valid <= o_master_valid_reg;

END ARCHITECTURE;
