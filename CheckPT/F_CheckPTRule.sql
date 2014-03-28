ALTER FUNCTION [dbo].[F_CheckPTRule] 
	(	
		@RuleId SMALLINT 
	)
RETURNS NVARCHAR(100)
AS

/*
Created: 20140325@Sophia
Task: Monthly check PT setting for credit customers - sportsbook setting
DB:   DBAGE.bodb02
Revisions:

Param's Explanation:  
	
*/

BEGIN
	DECLARE @RuleName NVARCHAR(100)
	
	SELECT @RuleName = CASE @RuleId WHEN 1 THEN 'S1 < 0 OR M1 < 0 OR A1 < 0'  
									WHEN 2 THEN 'S4 > 0.9 OR M4 > 0.9 OR A4 > 0.9'

									WHEN 3 THEN 'S4 < M4' 
									WHEN 4 THEN 'S4 < A4'
									WHEN 5 THEN 'S4 < N4'
									WHEN 6 THEN 'S4 < US3' 
									WHEN 7 THEN 'S4 < US1'									
									WHEN 8 THEN 'S4 < S3 + M3'	 
									WHEN 9 THEN 'S4 < S1 + M1 + A1'																			
									WHEN 10 THEN 'N4 > S1 + M1 + A1'


									WHEN 11 THEN 'M4 < A4'	
									WHEN 12 THEN 'M4 < M3' 	
									WHEN 13 THEN 'M4 < N3'																
									WHEN 14 THEN 'M4 < UM2'
									WHEN 15 THEN 'M4 < UM1'
									WHEN 16 THEN 'M4 < M1 + A1'							
									

									WHEN 17 THEN 'M3 < N3'
									WHEN 18 THEN 'M3 < M2 + A2'
									WHEN 19 THEN 'M3 < M1 + A1'																		
									WHEN 20 THEN 'N3 > M1 + A1'								
									
									WHEN 21 THEN 'A4 < A2'
									WHEN 22 THEN 'A4 < A1'

									WHEN 23 THEN 'N2 > A2'
									WHEN 24 THEN 'N2 > A1'							 
																		 
						END 
	RETURN @RuleName
END 


 

