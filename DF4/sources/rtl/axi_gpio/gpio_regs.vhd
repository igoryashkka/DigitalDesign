library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpio_regs is
  generic (
    ADDR_WIDTH : positive := 6;
    DATA_WIDTH : positive := 32;
    N_GPIO     : positive := 8
  );
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;

    -- AXI side
    axi_write_fire : in  std_logic;
    wr_addr        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    wr_data        : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    wr_strb        : in  std_logic_vector((DATA_WIDTH/8)-1 downto 0); -- here 8 - indecate width of byte

    axi_read_fire  : in  std_logic;
    rd_addr        : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    rd_data        : out std_logic_vector(DATA_WIDTH-1 downto 0);

    -- GPIO pins
    gpio_io        : inout std_logic_vector(N_GPIO-1 downto 0);
    gpio_out       : out   std_logic_vector(N_GPIO-1 downto 0) -- out only
  );
end entity;

architecture rtl of gpio_regs is

  constant BYTE_WIDTH : natural := 8;
  constant STRB_WIDTH : natural := DATA_WIDTH / BYTE_WIDTH;
  constant REG_DATA_ADDR : std_logic_vector(ADDR_WIDTH - 1 downto 0) := "000000"; -- 0x00
  constant REG_TRI_ADDR  : std_logic_vector(ADDR_WIDTH - 1 downto 0) := "000100"; -- 0x04

  signal reg_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others=>'0');
  signal reg_tri  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others=>'1');

  signal gpio_in  : std_logic_vector(N_GPIO-1 downto 0);

begin

  gen_gpio : for i in 0 to N_GPIO-1 generate
    gpio_io(i)  <= reg_data(i) when reg_tri(i)='0' else 'Z';
    gpio_in(i)  <= gpio_io(i);
    gpio_out(i) <= reg_data(i);
  end generate;

  -- Write logic 
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n='0' then
        reg_data <= (others=>'0');
        reg_tri  <= (others=>'1'); -- default = input
      else
        if axi_write_fire='1' then
          if wr_addr = REG_DATA_ADDR then
            for i in 0 to STRB_WIDTH-1 loop
              if wr_strb(i) = '1' then
                reg_data((i+1)*BYTE_WIDTH-1 downto i*BYTE_WIDTH)
                  <= wr_data((i+1)*BYTE_WIDTH-1 downto i*BYTE_WIDTH);
              end if;
            end loop;
          end if;
          if wr_addr = REG_TRI_ADDR then
            for i in 0 to STRB_WIDTH-1 loop
              if wr_strb(i) = '1' then
                reg_tri((i+1)*BYTE_WIDTH-1 downto i*BYTE_WIDTH)
                  <= wr_data((i+1)*BYTE_WIDTH-1 downto i*BYTE_WIDTH);
              end if;
            end loop;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Read logic
  process(all)
  begin
    rd_data <= (others=>'0');

    if rd_addr(ADDR_WIDTH-1 downto 0)=REG_DATA_ADDR then
      rd_data(N_GPIO-1 downto 0) <= gpio_in;

    elsif rd_addr(ADDR_WIDTH-1 downto 0)=REG_TRI_ADDR then
      rd_data <= reg_tri;

    else
      rd_data <= (others=>'0');
    end if;
  end process;

end architecture;