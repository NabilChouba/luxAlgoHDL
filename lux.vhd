----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:56:52 04/16/2009 
-- Design Name: 
-- Module Name:    lux - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity lux is
    Port ( clk   : in  STD_LOGIC;
           rst   : in  STD_LOGIC;
			  start : in  STD_LOGIC;
			  start_rst : in  STD_LOGIC;
			  done  : out STD_LOGIC;
           Mt    : in  STD_LOGIC_VECTOR (31 downto 0);
			  Cout  : out  STD_LOGIC_VECTOR (31 downto 0)
			  );
end lux;


architecture RTL of lux is
component  Rijndael_mults is
    Port ( --clk : in  STD_LOGIC;
           --rst : in  STD_LOGIC;
           ain : in  STD_LOGIC_VECTOR (7 downto 0);
           bin : in  STD_LOGIC_VECTOR (7 downto 0);
           pout : out  STD_LOGIC_VECTOR (7 downto 0));
end component;

-- /* Matrices for MixColumns */
type T_MC_row is array (0  to 3) of STD_LOGIC_VECTOR (7 downto 0) ;
type T_MC is array (0  to 3) of T_MC_row;
constant MC : T_MC :=((x"02", x"03", x"01", x"01"),
						    (x"01", x"02", x"03", x"01"),
						    (x"01", x"01", x"02", x"03"),
						    (x"03", x"01", x"01", x"02"));


type T_SBOX is array (0  to 255) of STD_LOGIC_VECTOR (7 downto 0);
constant LUC_SBOX : T_SBOX := (
x"63", x"7c", x"77", x"7b", x"f2", x"6b", x"6f", x"c5", x"30", x"01", x"67", x"2b", x"fe", x"d7", x"ab", x"76", 
x"ca", x"82", x"c9", x"7d", x"fa", x"59", x"47", x"f0", x"ad", x"d4", x"a2", x"af", x"9c", x"a4", x"72", x"c0",
x"b7", x"fd", x"93", x"26", x"36", x"3f", x"f7", x"cc", x"34", x"a5", x"e5", x"f1", x"71", x"d8", x"31", x"15",
x"04", x"c7", x"23", x"c3", x"18", x"96", x"05", x"9a", x"07", x"12", x"80", x"e2", x"eb", x"27", x"b2", x"75",
x"09", x"83", x"2c", x"1a", x"1b", x"6e", x"5a", x"a0", x"52", x"3b", x"d6", x"b3", x"29", x"e3", x"2f", x"84",
x"53", x"d1", x"00", x"ed", x"20", x"fc", x"b1", x"5b", x"6a", x"cb", x"be", x"39", x"4a", x"4c", x"58", x"cf",
x"d0", x"ef", x"aa", x"fb", x"43", x"4d", x"33", x"85", x"45", x"f9", x"02", x"7f", x"50", x"3c", x"9f", x"a8",
x"51", x"a3", x"40", x"8f", x"92", x"9d", x"38", x"f5", x"bc", x"b6", x"da", x"21", x"10", x"ff", x"f3", x"d2",
x"cd", x"0c", x"13", x"ec", x"5f", x"97", x"44", x"17", x"c4", x"a7", x"7e", x"3d", x"64", x"5d", x"19", x"73",
x"60", x"81", x"4f", x"dc", x"22", x"2a", x"90", x"88", x"46", x"ee", x"b8", x"14", x"de", x"5e", x"0b", x"db",
x"e0", x"32", x"3a", x"0a", x"49", x"06", x"24", x"5c", x"c2", x"d3", x"ac", x"62", x"91", x"95", x"e4", x"79",
x"e7", x"c8", x"37", x"6d", x"8d", x"d5", x"4e", x"a9", x"6c", x"56", x"f4", x"ea", x"65", x"7a", x"ae", x"08",
x"ba", x"78", x"25", x"2e", x"1c", x"a6", x"b4", x"c6", x"e8", x"dd", x"74", x"1f", x"4b", x"bd", x"8b", x"8a",
x"70", x"3e", x"b5", x"66", x"48", x"03", x"f6", x"0e", x"61", x"35", x"57", x"b9", x"86", x"c1", x"1d", x"9e",
x"e1", x"f8", x"98", x"11", x"69", x"d9", x"8e", x"94", x"9b", x"1e", x"87", x"e9", x"ce", x"55", x"28", x"df",
x"8c", x"a1", x"89", x"0d", x"bf", x"e6", x"42", x"68", x"41", x"99", x"2d", x"0f", x"b0", x"54", x"bb", x"16");

type T_Bmem is array (15 downto 0) of STD_LOGIC_VECTOR (31 downto 0);
type T_Cmem is array (7  downto 0) of STD_LOGIC_VECTOR (31 downto 0);

signal Cmem_reg,Cmem_next : T_Cmem;
signal Bmem_reg,Bmem_next : T_Bmem;

-- FSM States
   type state_type is (idle,init_soft_rst,add_message,Feedfw_buffer_to_core,MixColumns,function_F,AddConstant,Add_core_to_buffer,ShiftRows,SubBytes,waitti);
  -- FSM registers
  signal state_reg : state_type;
  signal state_next: state_type;

  signal col_swap_reg,col_swap_next,col_swap_sig : STD_LOGIC_VECTOR (31 downto 0);
  
  signal sub_index_col : STD_LOGIC_VECTOR (31 downto 0);
  signal sub_index_row : STD_LOGIC_VECTOR (7 downto 0);
  
  signal mixcol ,mixcol0 ,mixcol1 ,mixcol2 ,mixcol3 : STD_LOGIC_VECTOR (7 downto 0);
  signal mix_matrix0,mix_matrix1,mix_matrix2,mix_matrix3: STD_LOGIC_VECTOR (7 downto 0);
  signal count_reg,count_next : unsigned (4 downto 0);
  signal inc_count : STD_LOGIC;
  signal rst_count : STD_LOGIC;
  
begin

cloked_process : process( clk, rst )
  begin
    if( rst='1' ) then
      Cmem_reg  <= (others=>(others=>'0')) ;
		Bmem_reg  <= (others=>(others=>'0')) ;
		state_reg <= idle;
		count_reg <= (others=>'0');
		col_swap_reg <= (others=>'0');
    elsif( clk'event and clk='1' ) then
      Cmem_reg <= Cmem_next;
		Bmem_reg <= Bmem_next;
		state_reg <= state_next;
		count_reg <= count_next;
		col_swap_reg <= col_swap_next;
    end if;
 end process ;
 
 done <= '1' when state_reg = idle else
         '0';
			
  --next state processing
  combinatory_FSM_next : 
process(state_reg,count_reg,start,start_rst)
  begin
    state_next<= state_reg;

    case state_reg is
	 
    when idle =>
	   if start_rst= '1' then
        state_next <= init_soft_rst; 
      elsif start = '1' then
         state_next <= add_message;     
		end if;
		
    -- reset state C and B all value are zero
    when init_soft_rst =>
		state_next <= add_message;
	
    -- Addition of the message block to the buffer and the core	 
    -- B0 <= B0 xor Mt
	 -- C0 <= C0 xor Mt
    when add_message =>
		state_next <= function_F;
		
	 -- Buffer transformation F
	 -- B <= F(B)
	 -- B cyclic rotation of column to the right
    when function_F =>
		state_next <= SubBytes;
		
	 -- Core transformation G 
	 
	 -- C <= SubBytes(C)
	 --
	 -- can be writen :
	 -- for i : 0 to 7
	 --   for j : 0 to 3
	 --     C(i,j) <= SBOX(C(i,j));
	 --
	 -- loop i and loop j are implimented on counter 
	 -- i=counter_reg(4 downto 2) , j=counter_reg(1 downto 0) 
	 -- SBOX is implimented as ROM with 0 to 255

	 when SubBytes =>
	   if count_reg = 31 then
		  state_next <= ShiftRows;
	   end if;
		
    -- C <= ShiftRows(C)
	 -- C cyclic rotation of row to the left
	 when ShiftRows =>
		state_next <= MixColumns;
		
   -- C <= MixColumns(C)
	--
	-- can be writen :
	-- for i : 0 to 7
	-- C column(i)  <= MC row(i)   * C column(i) 
	--
	-- can be writen :
	-- for i : 0 to 7
	--   for j : 0 to 3
	--   C (i)(j)  <= MC (j)(i) * C (i)(j)
	--
	-- "*" : are impliented by design : Rijndael_mults
	-- loop i and loop j are implimented on counter 
	-- i=(4 downto 2) , j=(1 downto 0) 
	when 	MixColumns =>
	  if count_reg = 31 then
	    state_next <= AddConstant;
	  end if;

   -- Add Constantto the core
	-- C(0) <= C(0) xor 641CD02A	
   when AddConstant =>
		state_next <= Add_core_to_buffer;
		
		
	--	Add core to buffer
	-- for i : 0 to 7
   --   b(i+4) <= b(i+4) xor C(i)   	
	when Add_core_to_buffer =>
		state_next <= Feedfw_buffer_to_core;     

   -- Feedforward buffer to the core
   -- C(7) <= C(7) xor B(15) 
	when Feedfw_buffer_to_core =>
	  state_next <= idle;
	     		
	when others =>
 end case;
end process;


combinatory_bmem_next : process( Bmem_reg, state_reg,Cmem_reg,Mt )
  begin
  Bmem_next <= Bmem_reg;
    case state_reg is
	when idle => 
	when init_soft_rst =>
    Bmem_next  <= (others=>(others=>'0')) ;
  when add_message =>
    Bmem_next (0) <= Bmem_reg (0) xor Mt;
  when function_F =>
    Bmem_next (0) <= Bmem_reg (15);
    for i in 0 to 14 loop
	   Bmem_next (i+1) <= Bmem_reg (i);
    end loop;
  when Add_core_to_buffer =>
    for i in 0 to 7 loop
	   Bmem_next (i+4) <= Bmem_reg (i+4) xor Cmem_reg(i);
	 end loop;
  when others =>
 end case;
end process;

combinatory_Cmem_next : process( Cmem_reg, state_reg,Bmem_reg,Mt,count_reg ,sub_index_row,mixcol)
  begin
  Cmem_next <= Cmem_reg;
    case state_reg is
	when idle => 
	when init_soft_rst =>
    Cmem_next  <= (others=>(others=>'0')) ;
  when add_message =>
    Cmem_next (0) <= Cmem_reg (0) xor Mt;
  when ShiftRows =>
   
   -- row 1   
   Cmem_next (7)(15  downto  8) <= Cmem_reg (0)(15  downto  8);
   for i in 0 to 6 loop
	  Cmem_next (i)(15  downto  8) <= Cmem_reg (i+1)(15  downto  8);
	end loop;
	
   -- row 2
   Cmem_next (5)(23  downto  16) <= Cmem_reg (0)(23  downto  16);
   Cmem_next (6)(23  downto  16) <= Cmem_reg (1)(23  downto  16);
   Cmem_next (7)(23  downto  16) <= Cmem_reg (2)(23  downto  16);
   for i in 0 to 4 loop
	  Cmem_next (i)(23  downto  16) <= Cmem_reg (i+3)(23  downto  16);
	end loop;
	
	--row 3
	for i in 0 to 3 loop
	  Cmem_next (i)(31  downto  24) <= Cmem_reg (i+4)(31  downto  24);
	end loop; 
	for i in 4 to 7 loop
	  Cmem_next (i)(31  downto  24) <= Cmem_reg (i-4)(31  downto  24);
	end loop; 	
	
  when SubBytes =>
     case count_reg(1 downto 0) is 
	    when "00" =>
	     Cmem_next (conv_integer(count_reg( 4 downto  2))) (7  downto 0 ) <= LUC_SBOX (conv_integer(sub_index_row) );
	    when "01" =>		
		  Cmem_next (conv_integer(count_reg( 4 downto  2))) (15  downto 8 ) <= LUC_SBOX (conv_integer(sub_index_row) );
	    when "10" =>
		  Cmem_next (conv_integer(count_reg( 4 downto  2))) (23  downto 16 ) <= LUC_SBOX (conv_integer(sub_index_row));
	    when "11" =>
		  Cmem_next (conv_integer(count_reg( 4 downto  2))) (31 downto 24 ) <= LUC_SBOX (conv_integer(sub_index_row));
       when others =>
     end case;
	  
  when MixColumns =>
     case count_reg(1 downto 0) is 
	    when "00" =>
	     Cmem_next (conv_integer(count_reg( 4 downto  2))) (7  downto 0 ) <= mixcol;
	    when "01" =>		
		  Cmem_next (conv_integer(count_reg( 4 downto  2))) (15  downto 8 ) <= mixcol;
	    when "10" =>
		  Cmem_next (conv_integer(count_reg( 4 downto  2))) (23  downto 16 ) <= mixcol;
	    when "11" =>
		  Cmem_next (conv_integer(count_reg( 4 downto  2))) (31 downto 24 ) <= mixcol;
       when others =>
     end case;

  when AddConstant =>	 
	 Cmem_next (0) <= Cmem_reg (0) xor X"641cd02a";
	 
  when Feedfw_buffer_to_core =>
    Cmem_next (7) <= Cmem_reg (7) xor Bmem_reg (15);
	 
  when others =>
 end case;
end process;

  Cout <= Cmem_reg (3);
  
  mix_matrix0 <= MC(conv_integer(count_reg( 1 downto  0)))(0);
  mix_matrix1 <= MC(conv_integer(count_reg( 1 downto  0)))(1);
  mix_matrix2 <= MC(conv_integer(count_reg( 1 downto  0)))(2);
  mix_matrix3 <= MC(conv_integer(count_reg( 1 downto  0)))(3);

  U_Rj_mul0 : Rijndael_mults port map( ain=>  col_swap_sig (7  downto 0 ) ,
                                      bin=>  mix_matrix0,
												  pout=> mixcol0   );
  U_Rj_mul1 : Rijndael_mults port map( ain=> col_swap_sig (15  downto 8 ) ,
                                       bin=> mix_matrix1,
												  pout=> mixcol1  );												  
  U_Rj_mul2 : Rijndael_mults port map( ain=> col_swap_sig (23 downto 16 ) ,
                                      bin=> mix_matrix2,
												  pout=> mixcol2   );
  U_Rj_mul3 : Rijndael_mults port map( ain=> col_swap_sig (31  downto 24) ,
                                      bin=> mix_matrix3,
												  pout=> mixcol3   );
												  
  mixcol <= mixcol3 xor mixcol2 xor mixcol1 xor mixcol0;
    
    sub_index_col <= Cmem_reg (conv_integer(count_reg( 4 downto  2))); 
    
	 col_swap_next <= sub_index_col when count_reg(1 downto 0) = 0 else
	                  col_swap_reg;
	 col_swap_sig  <= sub_index_col when count_reg(1 downto 0) = 0 else 
	                  col_swap_reg;      
	 
	 row_indexGEN : process( count_reg,sub_index_col )
    begin
	 sub_index_row <= (others=>'0');
	  case count_reg(1 downto 0) is 
	    when "00" =>
	     sub_index_row <=  sub_index_col (7   downto 0 );
	    when "01" =>		       
		  sub_index_row <=  sub_index_col (15   downto 8 );
	    when "10" =>
		  sub_index_row <=  sub_index_col (23   downto 16 );
	    when "11" =>
		  sub_index_row <=  sub_index_col (31  downto 24);
       when others =>
     end case;
	end process;
	 
	 
	inc_count<= '1' when state_reg = SubBytes or state_reg = MixColumns else 
	            '0';
	rst_count<= '0' when state_reg = SubBytes or state_reg = MixColumns else 
	            '1';
-- counter col :  0 & 7 3 bit
-- +2 bit row = 5bit (4 downto 0)
-- col "000"  row "00"
					
	COUNTER_GEN : process( inc_count,count_reg,rst_count )
    begin
     count_next <= count_reg;
     if ( rst_count ='1' ) then
	    count_next <= (others=>'0');
	  elsif( inc_count ='1' ) then
       count_next <= count_reg + 1 ;
     end if ;
    end process ;
	 
end RTL;

