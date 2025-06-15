LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY dxi_top IS
    PORT (
        i_clk           : IN  std_logic;
        i_rstn          : IN  std_logic;
        i_dxi_valid     : IN  std_logic;
        i_dxi_data      : IN  std_logic_vector(71 DOWNTO 0);  
        o_dxi_ready     : OUT std_logic;
        i_dxi_out_ready : IN  std_logic;
        o_dxi_out_valid : OUT std_logic;
        o_master_data   : OUT std_logic_vector(7 DOWNTO 0);
        config_select   : IN  std_logic_vector(1 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE rtl OF dxi_top IS

    TYPE pixel_array IS ARRAY(0 TO 8) OF std_logic_vector(7 DOWNTO 0);
    TYPE kernel_array IS ARRAY(0 TO 8) OF INTEGER;

    SIGNAL pixel_result     : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL master_valid     : std_logic := '0';
    SIGNAL o_dxi_ready_reg  : std_logic := '1';

    CONSTANT lap1  : kernel_array := (  0, -1,  0,
                                       -1,  4, -1,
                                        0, -1,  0);
    CONSTANT lap2  : kernel_array := (-1, -1, -1,
                                     -1,  8, -1,
                                     -1, -1, -1);
    CONSTANT gauss : kernel_array := ( 1, 2, 1,
                                       2, 4, 2,
                                       1, 2, 1);
    CONSTANT avg   : kernel_array := ( 1, 1, 1,
                                       1, 1, 1,
                                       1, 1, 1);

    FUNCTION unpack_pixel_bus(data_flat : std_logic_vector(71 DOWNTO 0)) RETURN pixel_array IS
        VARIABLE pixels : pixel_array;
    BEGIN
        FOR i IN 0 TO 8 LOOP
            pixels(i) := data_flat((71 - i*8) DOWNTO (64 - i*8));
        END LOOP;
        RETURN pixels;
    END FUNCTION;

    FUNCTION apply_filter(
        pixels : pixel_array;
        sel    : std_logic_vector(1 DOWNTO 0)
    ) RETURN std_logic_vector IS
        VARIABLE acc    : INTEGER := 0;
        VARIABLE norm   : INTEGER := 1;
        VARIABLE kernel : kernel_array;
        VARIABLE result : INTEGER;
    BEGIN
        CASE sel IS
            WHEN "00" => kernel := lap1;  norm := 1;
            WHEN "01" => kernel := lap2;  norm := 1;
            WHEN "10" => kernel := gauss; norm := 16;
            WHEN OTHERS => kernel := avg; norm := 9;
        END CASE;

        FOR i IN 0 TO 8 LOOP
            acc := acc + kernel(i) * to_integer(unsigned(pixels(i)));
        END LOOP;

        result := acc / norm;
        IF result < 0 THEN
            result := 0;
        ELSIF result > 255 THEN
            result := 255;
        END IF;

        RETURN std_logic_vector(to_unsigned(result, 8));
    END FUNCTION;

BEGIN

PROCESS(i_clk)
    BEGIN
        IF rising_edge(i_clk) THEN
            IF i_rstn = '0' THEN
                pixel_result    <= (OTHERS => '0');
                master_valid    <= '0';
                o_dxi_ready_reg <= '1';
            ELSE
                IF (o_dxi_ready_reg = '1') and (i_dxi_valid = '1') THEN
                    pixel_result    <= apply_filter(unpack_pixel_bus(i_dxi_data), config_select);
                    master_valid    <= '1';
                END IF;    

                IF (i_dxi_out_ready = '0') THEN
                    master_valid    <= '0';
                    o_dxi_ready_reg <= '0';
                END IF;

            END IF;
        END IF;
    END PROCESS;

    o_dxi_ready     <= o_dxi_ready_reg;
    o_dxi_out_valid <= master_valid;
    o_master_data   <= pixel_result;

END ARCHITECTURE;
