USE [bodb02]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_NotConfigCurrencySel]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[NAP_WinLimit_NotConfigCurrencySel]
GO

USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_NotConfigCurrencySel]    Script Date: 07/07/2015 16:11:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_NotConfigCurrencySel]
	@ProductID TINYINT
AS
	/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608 - Implement function to control Player's Win Limit on specific Product
		
		DB: DBTXN/bodb02
		
		Revisions:
		
		Parameters Explanation:	
			@ProductID		: Game ID.
	*/
BEGIN
	SET NOCOUNT ON;
	SELECT	exchangeid
			,Code + ' (' + currency + ')' as ExchangeName
	FROM	dbo.exchange WITH (NOLOCK)
	WHERE	currency NOT IN('UUS', 'H', 'C')
			AND exchangeid NOT IN
			(
				SELECT ExchangeID 
				FROM dbo.WinLimit_GlobalSetting WITH (NOLOCK) 
				WHERE ProductID = @ProductID
			)
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_NotConfigCurrencySel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_NotConfigCurrencySel] TO [accteam]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_NotConfigCurrencySel] TO [vnteam]
GO