library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_lite_interconnect is
  generic (
    S_COUNT    : positive := 2;   
    M_COUNT    : positive := 2;  
    ADDR_WIDTH : positive := 32;
    DATA_WIDTH : positive := 32;


    M_BASE_ADDR : std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0) :=
      x"40001000" & x"40000000";

    M_ADDR_MASK : std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0) :=
      x"FFFFF000" & x"FFFFF000"
  );
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;

    ----------------------------------------------------------------------------
    s_axil_awaddr  : in  std_logic_vector(S_COUNT*ADDR_WIDTH-1 downto 0);
    s_axil_awvalid : in  std_logic_vector(S_COUNT-1 downto 0);
    s_axil_awready : out std_logic_vector(S_COUNT-1 downto 0);

    s_axil_wdata   : in  std_logic_vector(S_COUNT*DATA_WIDTH-1 downto 0);
    s_axil_wstrb   : in  std_logic_vector(S_COUNT*(DATA_WIDTH/8)-1 downto 0);
    s_axil_wvalid  : in  std_logic_vector(S_COUNT-1 downto 0);
    s_axil_wready  : out std_logic_vector(S_COUNT-1 downto 0);

    s_axil_bresp   : out std_logic_vector(S_COUNT*2-1 downto 0);
    s_axil_bvalid  : out std_logic_vector(S_COUNT-1 downto 0);
    s_axil_bready  : in  std_logic_vector(S_COUNT-1 downto 0);

    s_axil_araddr  : in  std_logic_vector(S_COUNT*ADDR_WIDTH-1 downto 0);
    s_axil_arvalid : in  std_logic_vector(S_COUNT-1 downto 0);
    s_axil_arready : out std_logic_vector(S_COUNT-1 downto 0);

    s_axil_rdata   : out std_logic_vector(S_COUNT*DATA_WIDTH-1 downto 0);
    s_axil_rresp   : out std_logic_vector(S_COUNT*2-1 downto 0);
    s_axil_rvalid  : out std_logic_vector(S_COUNT-1 downto 0);
    s_axil_rready  : in  std_logic_vector(S_COUNT-1 downto 0);

    ----------------------------------------------------------------------------
    m_axil_awaddr  : out std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0);
    m_axil_awvalid : out std_logic_vector(M_COUNT-1 downto 0);
    m_axil_awready : in  std_logic_vector(M_COUNT-1 downto 0);

    m_axil_wdata   : out std_logic_vector(M_COUNT*DATA_WIDTH-1 downto 0);
    m_axil_wstrb   : out std_logic_vector(M_COUNT*(DATA_WIDTH/8)-1 downto 0);
    m_axil_wvalid  : out std_logic_vector(M_COUNT-1 downto 0);
    m_axil_wready  : in  std_logic_vector(M_COUNT-1 downto 0);

    m_axil_bresp   : in  std_logic_vector(M_COUNT*2-1 downto 0);
    m_axil_bvalid  : in  std_logic_vector(M_COUNT-1 downto 0);
    m_axil_bready  : out std_logic_vector(M_COUNT-1 downto 0);

    m_axil_araddr  : out std_logic_vector(M_COUNT*ADDR_WIDTH-1 downto 0);
    m_axil_arvalid : out std_logic_vector(M_COUNT-1 downto 0);
    m_axil_arready : in  std_logic_vector(M_COUNT-1 downto 0);

    m_axil_rdata   : in  std_logic_vector(M_COUNT*DATA_WIDTH-1 downto 0);
    m_axil_rresp   : in  std_logic_vector(M_COUNT*2-1 downto 0);
    m_axil_rvalid  : in  std_logic_vector(M_COUNT-1 downto 0);
    m_axil_rready  : out std_logic_vector(M_COUNT-1 downto 0)
  );
end entity;