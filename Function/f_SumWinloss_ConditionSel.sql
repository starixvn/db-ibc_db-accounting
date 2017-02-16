USE [bodb02]
GO

/****** Object:  UserDefinedFunction [dbo].[f_SumWinloss_ConditionSel]    Script Date: 1/10/2017 10:04:37 AM ******/
DROP FUNCTION [dbo].[f_SumWinloss_ConditionSel]
GO

/****** Object:  UserDefinedFunction [dbo].[f_SumWinloss_ConditionSel]    Script Date: 1/10/2017 10:04:37 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/****** Object:  User Defined Function dbo.f_SumWinloss_ConditionSel    Script Date: 5/12/2016 11:24:09 AM ******/

CREATE FUNCTION [dbo].[f_SumWinloss_ConditionSel]
(
	@ProductID	VARCHAR(500) = ''
) 
/*
	Creator: Paul	
	Date: 20170110
	Task: Get sum_winloss condition
	DB: DBAGE.bodb02
		
	Revisions:
		
	Paramters Explanation:
 		@ProductID: list of products
*/
RETURNS TABLE
RETURN
	SELECT ProductID, SportType, BetType
	FROM (
		VALUES	(1, 0, 0), --Sportsbook
				(6, 251, 71), (6, 208, 0), (6, 209, 0), (6, 210, 0), --RNG Casino
				(2, 151, 0), --Racing
				(3, 161, 0), --Number Game
				(4, 162, 0), --Live Casino
				(5, 180, 0), --Virtual Sports
				(8, 202, 0), --Keno
				(12, 255, 0), --Gold Deluxe
				(15, 204, 0), --Colossus Bets
				(21, 211, 0), --Allbet
				(22, 212, 0), --Macau Games
				(23, 213, 0), --NG2
				(24, 219, 0) --Fishing World
		) d(ProductID, SportType, BetType)
	WHERE ',' + @ProductID + ',' LIKE '%,' + CAST(ProductID as varchar(3)) + ',%'

GO

GRANT SELECT ON [dbo].[f_SumWinloss_ConditionSel] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[f_SumWinloss_ConditionSel] TO [bodbAdminNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[f_SumWinloss_ConditionSel] TO [bodbDownlineNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[f_SumWinloss_ConditionSel] TO [bodbDownlineNetView] AS [dbo]
GO

GRANT SELECT ON [dbo].[f_SumWinloss_ConditionSel] TO [bodbExtAccNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[f_SumWinloss_ConditionSel] TO [bodbLicenseeNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[f_SumWinloss_ConditionSel] TO [bodbRMSNet] AS [dbo]
GO

GRANT SELECT ON [dbo].[f_SumWinloss_ConditionSel] TO [dwrs] AS [dbo]
GO

GRANT SELECT ON [dbo].[f_SumWinloss_ConditionSel] TO [vnteam] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[f_SumWinloss_ConditionSel] TO [vnteam] AS [dbo]
GO


