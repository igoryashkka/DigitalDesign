library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- SPI Master
entity spi_master is
    generic (N : integer := 10);
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
end spi_master;

architecture Behavioral of spi_master is
    type stateType is (IDLE, TRANSMIT, COMPLETE);
    signal state     : stateType := IDLE;
    signal shift_reg : std_logic_vector(N-1 downto 0);
    signal bit_count : integer range 0 to N := 0;
    signal sck_reg   : std_logic := '1';
    signal cs_reg    : std_logic := '1';
    signal sck_counter : integer range 0 to 1 := 0;  -- For proper clock toggling

begin
    process(clk_c, reset_r)
    begin
        if reset_r = '1' then
            state       <= IDLE;
            shift_reg   <= (others => '0');
            bit_count   <= 0;
            sck_reg     <= '1';
            cs_reg      <= '1';
            sck_counter <= 0;
        elsif rising_edge(clk_c) then
            case state is
                when IDLE =>
                    sck_reg <= '1';
                    cs_reg <= '1';
                    done_o <= '0';
                    if start_i = '1' then
                        shift_reg <= inputData_i;
                        bit_count <= 0;
                        state <= TRANSMIT;
                        cs_reg <= '0'; -- Activate chip select
                    end if;

                when TRANSMIT =>
                    if sck_counter = 0 then
                        sck_reg <= '0';
                        sck_counter <= 1;
                    else
                        shift_reg <= shift_reg(N-2 downto 0) & miso_i;
                        bit_count <= bit_count + 1;
                        sck_reg <= '1';
                        sck_counter <= 0;
                        if bit_count = N - 1 then -- here was N - 1
                            state <= COMPLETE;
                        end if;
                    end if;

                when COMPLETE =>
                    state <= IDLE;
                    cs_reg <= '1';
                    done_o <= '1';
            end case;
        end if;
    end process;

    mosi_o <= shift_reg(N-1);
    sck    <= sck_reg;
    cs     <= cs_reg;
end Behavioral;