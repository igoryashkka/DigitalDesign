library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_gpio is
  generic (
    ADDR_WIDTH : positive := 6;
    DATA_WIDTH : positive := 32;
    N_GPIO     : positive := 8
  );
  port (
    -- AXI4-Lite
    s_axi_aclk    : in  std_logic;
    s_axi_aresetn : in  std_logic;

    -- Write Address Channel
    s_axi_awaddr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    s_axi_awvalid : in  std_logic;
    s_axi_awready : out std_logic;

    -- Write Data Channel
    s_axi_wdata   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    s_axi_wstrb   : in  std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    s_axi_wvalid  : in  std_logic;
    s_axi_wready  : out std_logic;

    -- Write Response Channel
    s_axi_bresp   : out std_logic_vector(1 downto 0);
    s_axi_bvalid  : out std_logic;
    s_axi_bready  : in  std_logic;

    -- Read Address Channel
    s_axi_araddr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    s_axi_arvalid : in  std_logic;
    s_axi_arready : out std_logic;

    -- Read Data Channel
    s_axi_rdata   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    s_axi_rresp   : out std_logic_vector(1 downto 0);
    s_axi_rvalid  : out std_logic;
    s_axi_rready  : in  std_logic;

    -- GPIO pins
    gpio_io       : inout std_logic_vector(N_GPIO-1 downto 0)
  );
end entity;

architecture rtl of top_gpio is

  signal axi_write_fire_s : std_logic;
  signal wr_addr_s        : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal wr_data_s        : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal wr_strb_s        : std_logic_vector((DATA_WIDTH/8)-1 downto 0);

  signal axi_read_fire_s  : std_logic;
  signal rd_addr_s        : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal rd_data_s        : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

  ---------------------------------------------------------------------------
  -- AXI slave 

  u_axi_gpio : entity work.axi_gpio
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      DATA_WIDTH => DATA_WIDTH
    )
    port map (
      s_axi_aclk    => s_axi_aclk,
      s_axi_aresetn => s_axi_aresetn,

      s_axi_awaddr  => s_axi_awaddr,
      s_axi_awvalid => s_axi_awvalid,
      s_axi_awready => s_axi_awready,

      s_axi_wdata   => s_axi_wdata,
      s_axi_wstrb   => s_axi_wstrb,
      s_axi_wvalid  => s_axi_wvalid,
      s_axi_wready  => s_axi_wready,

      s_axi_bresp   => s_axi_bresp,
      s_axi_bvalid  => s_axi_bvalid,
      s_axi_bready  => s_axi_bready,

      s_axi_araddr  => s_axi_araddr,
      s_axi_arvalid => s_axi_arvalid,
      s_axi_arready => s_axi_arready,

      s_axi_rdata   => s_axi_rdata,
      s_axi_rresp   => s_axi_rresp,
      s_axi_rvalid  => s_axi_rvalid,
      s_axi_rready  => s_axi_rready,

      axi_write_fire => axi_write_fire_s,
      wr_addr        => wr_addr_s,
      wr_data        => wr_data_s,
      wr_strb        => wr_strb_s,

      axi_read_fire  => axi_read_fire_s,
      rd_addr        => rd_addr_s,
      rd_data        => rd_data_s
    );

  ---------------------------------------------------------------------------
  -- GPIO reg file
 
  u_gpio_regs : entity work.gpio_regs
    generic map (
      ADDR_WIDTH => ADDR_WIDTH,
      DATA_WIDTH => DATA_WIDTH,
      N_GPIO     => N_GPIO
    )
    port map (
      clk           => s_axi_aclk,
      rst_n         => s_axi_aresetn,

      axi_write_fire => axi_write_fire_s,
      wr_addr        => wr_addr_s,
      wr_data        => wr_data_s,
      wr_strb        => wr_strb_s,

      axi_read_fire  => axi_read_fire_s,
      rd_addr        => rd_addr_s,
      rd_data        => rd_data_s,

      gpio_io        => gpio_io
    );

end architecture;
