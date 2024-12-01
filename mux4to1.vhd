library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--Mux_or--
entity mux is
    Port (
        sel    : in  STD_LOGIC_VECTOR (1 downto 0); 
 --       data0  : in  STD_LOGIC;                     
 --       data1  : in  STD_LOGIC;                     
 --       data2  : in  STD_LOGIC;                     
 --       data3  : in  STD_LOGIC;                     
        result : out STD_LOGIC                      
    );
end mux;

architecture Behavioral of mux is
begin
--MUX_or
	with sel select result <=
		'0' when "00",
		'1' when "10",
		'1' when "01",
		'1' when "11";
		
--mux_test _others	
--		'0' when "000",
--		'1' when "010",
--		'1' when "001",
--		'1' when "011",
--		'1' when "100",
--		'0' when others;


--	MUX_or another syntacs
--    result <= '0' when sel = "00" else
--              '1' when sel = "01" else
--              '1' when sel = "10" else
--              '1' when sel = "11";
end;




--Mux_4to1--
--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--
--entity test is
--    Port (
--        sel    : in  STD_LOGIC_VECTOR (1 downto 0); 
--        data0  : in  STD_LOGIC;                     
--        data1  : in  STD_LOGIC;                     
--        data2  : in  STD_LOGIC;                     
--        data3  : in  STD_LOGIC;                     
--        result : out STD_LOGIC                      
--    );
--end test;
--
--architecture Behavioral of test is
--begin
--    result <= data0 when sel = "00" else
--              data1 when sel = "01" else
--              data2 when sel = "10" else
--              data3; 
--end Behavioral;
--

