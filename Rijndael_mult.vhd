----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:33:09 04/17/2009 
-- Design Name: 
-- Module Name:    Rijndael_mult - RTL 
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


entity Rijndael_step_mult is
    Port ( ain : in  STD_LOGIC_VECTOR (7 downto 0);
           bin : in  STD_LOGIC_VECTOR (7 downto 0);
           pin : in  STD_LOGIC_VECTOR (7 downto 0);
			  aout : out  STD_LOGIC_VECTOR (7 downto 0);
           bout : out  STD_LOGIC_VECTOR (7 downto 0);
           pout : out  STD_LOGIC_VECTOR (7 downto 0));
end Rijndael_step_mult;

architecture RTL of Rijndael_step_mult is
signal a_shift :   STD_LOGIC_VECTOR (7 downto 0);
signal b_shift :   STD_LOGIC_VECTOR (7 downto 0);
			  
begin

a_shift <= ain(6 downto 0) & '0';
b_shift <= '0' & bin(7 downto 1) ;

bout <= b_shift;

pout <= pin xor ain when bin(0) = '1' else
     pin;

aout <= a_shift xor x"1b" when ain(7) = '1' else
     a_shift;


end RTL;

