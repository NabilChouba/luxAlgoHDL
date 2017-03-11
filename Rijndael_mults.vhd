----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:57:44 04/17/2009 
-- Design Name: 
-- Module Name:    Rijndael_mults - Behavioral 
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

entity Rijndael_mults is
    Port ( --clk : in  STD_LOGIC;
           --rst : in  STD_LOGIC;
           ain : in  STD_LOGIC_VECTOR (7 downto 0);
           bin : in  STD_LOGIC_VECTOR (7 downto 0);
           pout : out  STD_LOGIC_VECTOR (7 downto 0));
end Rijndael_mults;

architecture Behavioral of Rijndael_mults is

component Rijndael_step_mult is
    Port ( ain : in  STD_LOGIC_VECTOR (7 downto 0);
           bin : in  STD_LOGIC_VECTOR (7 downto 0);
           pin : in  STD_LOGIC_VECTOR (7 downto 0);
			  aout : out  STD_LOGIC_VECTOR (7 downto 0);
           bout : out  STD_LOGIC_VECTOR (7 downto 0);
           pout : out  STD_LOGIC_VECTOR (7 downto 0));
end component;


type T_Rjmem is array (8 downto 0) of STD_LOGIC_VECTOR (7 downto 0);

signal p,a,b : T_Rjmem;

begin

  p(0) <= (others=>'0');
  a(0) <= ain;
  b(0) <= bin;
  
  gen_step_mult :
    for i in 0 to 7 generate
       U_RjStep : Rijndael_step_mult port map( ain=> a(i)  ,bin=>b(i)   ,pin=>p(i),
		                                         aout=>a(i+1),bout=>b(i+1),pout=>p(i+1));
  end generate gen_step_mult;

  pout <= p(8);

end Behavioral;