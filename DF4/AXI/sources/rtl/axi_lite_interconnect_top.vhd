library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_lite_interconnect is
  generic (
    S_COUNT    : positive := 2;
    M_COUNT    : positive := 2;
    ADDR_WIDTH : positive := 32;
    DATA_WIDTH : positive := 32;

    S_BRESP_WIDTH  : positive := S_COUNT*2;
    M_BRESP_WIDTH  : positive := M_COUNT*2;
    S_PROT_WIDTH   : positive := S_COUNT*3;
    M_PROT_WIDTH   : positive := M_COUNT*3;
    S_WSTRB_WIDTH  : positive := S_COUNT*(DATA_WIDTH/8);
    M_WSTRB_WIDTH  : positive := M_COUNT*(DATA_WIDTH/8);

    GRANTED_INDEX_INVALID : integer := -1;

    M_BASE_ADDR : std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0) :=
      x"40001000" & x"40000000";

    M_ADDR_MASK : std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0) :=
      x"FFFFF000" & x"FFFFF000"
  );
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;

    s_axi_awaddr  : in  std_logic_vector(S_COUNT*ADDR_WIDTH-1 downto 0);
    s_axi_awprot  : in  std_logic_vector(S_PROT_WIDTH-1 downto 0);
    s_axi_awvalid : in  std_logic_vector(S_COUNT-1 downto 0);
    s_axi_awready : out std_logic_vector(S_COUNT-1 downto 0);

    s_axi_wdata   : in  std_logic_vector(S_COUNT*DATA_WIDTH-1 downto 0);
    s_axi_wstrb   : in  std_logic_vector(S_WSTRB_WIDTH-1 downto 0);
    s_axi_wvalid  : in  std_logic_vector(S_COUNT-1 downto 0);
    s_axi_wready  : out std_logic_vector(S_COUNT-1 downto 0);

    s_axi_bresp   : out std_logic_vector(S_BRESP_WIDTH-1 downto 0);
    s_axi_bvalid  : out std_logic_vector(S_COUNT-1 downto 0);
    s_axi_bready  : in  std_logic_vector(S_COUNT-1 downto 0);

    s_axi_araddr  : in  std_logic_vector(S_COUNT*ADDR_WIDTH-1 downto 0);
    s_axi_arprot  : in  std_logic_vector(S_PROT_WIDTH-1 downto 0);
    s_axi_arvalid : in  std_logic_vector(S_COUNT-1 downto 0);
    s_axi_arready : out std_logic_vector(S_COUNT-1 downto 0);

    s_axi_rdata   : out std_logic_vector(S_COUNT*DATA_WIDTH-1 downto 0);
    s_axi_rresp   : out std_logic_vector(S_BRESP_WIDTH-1 downto 0);
    s_axi_rvalid  : out std_logic_vector(S_COUNT-1 downto 0);
    s_axi_rready  : in  std_logic_vector(S_COUNT-1 downto 0);

    m_axi_awaddr  : out std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0);
    m_axi_awprot  : out std_logic_vector(M_PROT_WIDTH-1 downto 0);
    m_axi_awvalid : out std_logic_vector(M_COUNT-1 downto 0);
    m_axi_awready : in  std_logic_vector(M_COUNT-1 downto 0);

    m_axi_wdata   : out std_logic_vector(M_COUNT*DATA_WIDTH-1 downto 0);
    m_axi_wstrb   : out std_logic_vector(M_WSTRB_WIDTH-1 downto 0);
    m_axi_wvalid  : out std_logic_vector(M_COUNT-1 downto 0);
    m_axi_wready  : in  std_logic_vector(M_COUNT-1 downto 0);

    m_axi_bresp   : in  std_logic_vector(M_BRESP_WIDTH-1 downto 0);
    m_axi_bvalid  : in  std_logic_vector(M_COUNT-1 downto 0);
    m_axi_bready  : out std_logic_vector(M_COUNT-1 downto 0);

    m_axi_araddr  : out std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0);
    m_axi_arprot  : out std_logic_vector(M_PROT_WIDTH-1 downto 0);
    m_axi_arvalid : out std_logic_vector(M_COUNT-1 downto 0);
    m_axi_arready : in  std_logic_vector(M_COUNT-1 downto 0);

    m_axi_rdata   : in  std_logic_vector(M_COUNT*DATA_WIDTH-1 downto 0);
    m_axi_rresp   : in  std_logic_vector(M_BRESP_WIDTH-1 downto 0);
    m_axi_rvalid  : in  std_logic_vector(M_COUNT-1 downto 0);
    m_axi_rready  : out std_logic_vector(M_COUNT-1 downto 0)
  );
end entity;

architecture rtl of axi_lite_interconnect is
  signal wr_req       : std_logic_vector(S_COUNT-1 downto 0);
  signal rd_req       : std_logic_vector(S_COUNT-1 downto 0);
  signal wr_start_ptr : integer range 0 to S_COUNT-1;
  signal rd_start_ptr : integer range 0 to S_COUNT-1;
  signal wr_granted_index : integer range GRANTED_INDEX_INVALID to S_COUNT-1;
  signal rd_granted_index : integer range GRANTED_INDEX_INVALID to S_COUNT-1;
  signal wr_grant_valid   : std_logic;
  signal rd_grant_valid   : std_logic;
begin
  wr_arb_inst : entity work.axi_rr_arbiter(rtl)
    generic map (
      N => S_COUNT
    )
    port map (
      req       => wr_req,
      start_ptr => wr_start_ptr,
      granted_index => wr_granted_index,
      grant_valid   => wr_grant_valid
    );

  rd_arb_inst : entity work.axi_rr_arbiter(rtl)
    generic map (
      N => S_COUNT
    )
    port map (
      req       => rd_req,
      start_ptr => rd_start_ptr,
      granted_index => rd_granted_index,
      grant_valid   => rd_grant_valid
    );

  write_path_inst : entity work.axi_interconnect_write(rtl)
    generic map (
      S_COUNT    => S_COUNT,
      M_COUNT    => M_COUNT,
      ADDR_WIDTH => ADDR_WIDTH,
      DATA_WIDTH => DATA_WIDTH,
      M_BASE_ADDR => M_BASE_ADDR,
      M_ADDR_MASK => M_ADDR_MASK
    )
    port map (
      clk => clk,
      rst_n => rst_n,

      s_axi_awaddr => s_axi_awaddr,
      s_axi_awprot => s_axi_awprot,
      s_axi_awvalid => s_axi_awvalid,
      s_axi_awready => s_axi_awready,

      s_axi_wdata => s_axi_wdata,
      s_axi_wstrb => s_axi_wstrb,
      s_axi_wvalid => s_axi_wvalid,
      s_axi_wready => s_axi_wready,

      s_axi_bresp => s_axi_bresp,
      s_axi_bvalid => s_axi_bvalid,
      s_axi_bready => s_axi_bready,

      m_axi_awaddr => m_axi_awaddr,
      m_axi_awprot => m_axi_awprot,
      m_axi_awvalid => m_axi_awvalid,
      m_axi_awready => m_axi_awready,

      m_axi_wdata => m_axi_wdata,
      m_axi_wstrb => m_axi_wstrb,
      m_axi_wvalid => m_axi_wvalid,
      m_axi_wready => m_axi_wready,

      m_axi_bresp => m_axi_bresp,
      m_axi_bvalid => m_axi_bvalid,
      m_axi_bready => m_axi_bready,

      wr_arb_req => wr_req,
      wr_arb_start_ptr => wr_start_ptr,
      wr_arb_granted_index => wr_granted_index,
      wr_arb_grant_valid => wr_grant_valid
    );

  read_path_inst : entity work.axi_interconnect_read(rtl)
    generic map (
      S_COUNT    => S_COUNT,
      M_COUNT    => M_COUNT,
      ADDR_WIDTH => ADDR_WIDTH,
      DATA_WIDTH => DATA_WIDTH,
      M_BASE_ADDR => M_BASE_ADDR,
      M_ADDR_MASK => M_ADDR_MASK
    )
    port map (
      clk => clk,
      rst_n => rst_n,

      s_axi_araddr => s_axi_araddr,
      s_axi_arprot => s_axi_arprot,
      s_axi_arvalid => s_axi_arvalid,
      s_axi_arready => s_axi_arready,

      s_axi_rdata => s_axi_rdata,
      s_axi_rresp => s_axi_rresp,
      s_axi_rvalid => s_axi_rvalid,
      s_axi_rready => s_axi_rready,

      m_axi_araddr => m_axi_araddr,
      m_axi_arprot => m_axi_arprot,
      m_axi_arvalid => m_axi_arvalid,
      m_axi_arready => m_axi_arready,

      m_axi_rdata => m_axi_rdata,
      m_axi_rresp => m_axi_rresp,
      m_axi_rvalid => m_axi_rvalid,
      m_axi_rready => m_axi_rready,

      rd_arb_req => rd_req,
      rd_arb_start_ptr => rd_start_ptr,
      rd_arb_granted_index => rd_granted_index,
      rd_arb_grant_valid => rd_grant_valid
    );
end architecture;
