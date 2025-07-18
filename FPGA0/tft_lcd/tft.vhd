LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_filter IS
END ENTITY;



ARCHITECTURE sim OF tb_filter IS

--------------------------

 type T_STATE is
      (RESET, START, EXECUTE, FINISH);

 type init_item_t is record
  dc   : std_logic;              -- 1'b0 or 1'b1
  data : std_logic_vector(7 downto 0); -- 8'hXX
end record;


--------------------------


SIGNAL remainingDelayTicks :std_logic_vector(24 DOWNTO 0) := (OTHERS => '0');

constant INIT_SEQ_LEN : integer := 59;
SIGNAL initSeqCounter : integer := 6'b0; -- ????? how use/what better integer  STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');
type init_seq_array_t is array(0 to INIT_SEQ_LEN - 1) of init_item_t;

-- Initialization array
constant INIT_SEQ : init_seq_array_t := (
  -- Turn off Display
  ( '0', x"28" ),
  
  -- Init
  ( '0', x"CF" ), ( '1', x"00" ), ( '1', x"83" ), ( '1', x"30" ),
  ( '0', x"ED" ), ( '1', x"64" ), ( '1', x"03" ), ( '1', x"12" ), ( '1', x"81" ),
  ( '0', x"E8" ), ( '1', x"85" ), ( '1', x"01" ), ( '1', x"79" ),
  ( '0', x"CB" ), ( '1', x"39" ), ( '1', x"2C" ), ( '1', x"00" ), ( '1', x"34" ), ( '1', x"02" ),
  ( '0', x"F7" ), ( '1', x"20" ),
  ( '0', x"EA" ), ( '1', x"00" ), ( '1', x"00" ),
  
  -- Power Control
  ( '0', x"C0" ), ( '1', x"26" ),
  ( '0', x"C1" ), ( '1', x"11" ),
  
  -- VCOM
  ( '0', x"C5" ), ( '1', x"35" ), ( '1', x"3E" ),
  ( '0', x"C7" ), ( '1', x"BE" ),
  
  -- Memory Access Control
  ( '0', x"3A" ), ( '1', x"55" ),
  
  -- Frame Rate
  ( '0', x"B1" ), ( '1', x"00" ), ( '1', x"1B" ),
  
  -- Gamma
  ( '0', x"26" ), ( '1', x"01" ),
  
  -- Brightness
  ( '0', x"51" ), ( '1', x"FF" ),
  
  -- Display
  ( '0', x"B7" ), ( '1', x"07" ),
  ( '0', x"B6" ), ( '1', x"0A" ), ( '1', x"82" ), ( '1', x"27" ), ( '1', x"00" ),
  
  -- Enable Display
  ( '0', x"29" ),
  
  -- Start Memory Write
  ( '0', x"2C" )
);

BEGIN

PROCESS(i_clk)
BEGIN
  IF rising_edge(i_clk) THEN

  spiDataSet <= 1'b0; 
		
		-- always decrement delay ticks
		IF (remainingDelayTicks > 0) THEN
			remainingDelayTicks <= remainingDelayTicks - 1'b1;
    
        ELSIF (spiIdle && !spiDataSet) THEN

        CASE State IS
            WHEN START => 

            WHEN HOLD_RESET => 


            WHEN WAIT_FOR_POWERUP => 


            WHEN SEND_INIT_SEQ => 


            WHEN LOOP_CASE => 
            --      --  spiData <= !frameBufferLowNibble ? {1'b1, framebufferData[15:8]} :{1'b1, framebufferData[7:0]};
			--		spiDataSet <= 1'b1;
			--		frameBufferLowNibble <= !frameBufferLowNibble;

            when others => 


        END CASE;



		END IF;



   END IF;
 END PROCESS;


END ARCHITECTURE;