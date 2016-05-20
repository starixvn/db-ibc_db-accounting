use bodb02
go 

ALTER FUNCTION [dbo].[f_GroupBettype] 
()
RETURNS TABLE
RETURN

/*
	Created: 20141016@Sophia
	Task :	Get grouped bettype for Sporting Solution and BetRadar
	DB:		DBAGE/bodb02, DBEXT/bodb02, DBACC/bodb02
 	Revisions: 
		- 20150414@Sophia: Support BetRadar
		- 20151204@Bobby: Grouped 6 bettypes for PH AIO
		- 20160119@Sophia: PH AIO phase 1.2 [Redmine: #51029]
		- 20160426@Sophia: Change to in line Func-High Availability Step 4 [Redmine: #55746]
*/

  
	-------- Grouped bettype for Sporting Solution
	SELECT 153 AS Bettype, 153 AS GroupTypeId
	UNION ALL 
	SELECT 1308, 153

	UNION ALL 
	SELECT 154, 154
	UNION ALL 
	SELECT 1311, 154

	UNION ALL 
	SELECT 155, 155
	UNION ALL 
	SELECT 1316, 155

	UNION ALL 
	SELECT 156, 156 
	UNION ALL  
	SELECT 1312, 156

	UNION ALL 
	SELECT 1, 1 
	UNION ALL  
	SELECT 1303, 1

	UNION ALL 
	SELECT 2, 2 
	UNION ALL  
	SELECT 1305, 2		 

	UNION ALL 
	SELECT 3, 3 
	UNION ALL  
	SELECT 1306, 3	

	UNION ALL 
	SELECT 20, 20
	UNION ALL  
	SELECT 1301, 20	

	-------- Grouped bettype for BetRadar
	UNION ALL 
	SELECT 157, 2

	UNION ALL  
	SELECT 22, 22	
	UNION ALL  
	SELECT 160, 22	

	UNION ALL  
	SELECT 144, 144	
	UNION ALL  
	SELECT 163, 144	

	UNION ALL  
	SELECT 18, 18	
	UNION ALL  
	SELECT 178, 18	

	UNION ALL  
	SELECT 17, 17	
	UNION ALL  
	SELECT 183, 17	
	
	UNION ALL  
	SELECT 11, 11	
	UNION ALL  
	SELECT 199, 11	
	-------- Grouped 6 bettypes for PH AIO
	--1.Exact Total Goals vs 3rd
		
	UNION ALL  
	SELECT 159, 159	
	UNION ALL  
	SELECT 406, 159

	--2.Exact Home Team Goals & 3rd
			
	UNION ALL  
	SELECT 161, 161	
	UNION ALL  
	SELECT 407, 161
		
	--3.Winning Margin & 3rd
				
	UNION ALL  
	SELECT 171, 171	
	UNION ALL  
	SELECT 408, 171
		
	--4.Exact Away Team Goals & 3rd
	UNION ALL  
	SELECT 162, 162	
	UNION ALL  
	SELECT 409, 162
		
	--5.1H Double Chance & 3rd
	UNION ALL  
	SELECT 151, 151	
	UNION ALL  
	SELECT 410, 151

	
	--6.1H Draw No Bet & 3rd
	UNION ALL  
	SELECT 191, 191	
	UNION ALL  
	SELECT 411, 191 	 

	--7. CorrectScore 
	UNION ALL  
	SELECT 413, 4	
	UNION ALL  
	SELECT 414, 30 



GO 
GRANT SELECT ON [dbo].[f_GroupBettype] TO [bodbDownlineNet]
GO 
GRANT SELECT ON [dbo].[f_GroupBettype] TO [bodbDownlineNetView]
GO 