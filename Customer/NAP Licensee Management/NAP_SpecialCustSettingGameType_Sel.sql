
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_SpecialCustSettingGameType_Sel    Script Date: 10/28/2014 9:45:19 AM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSettingGameType_Sel    Script Date: 10/23/2014 12:48:25 PM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSettingGameType_Sel    Script Date: 10/23/2014 8:38:07 AM ******/
CREATE PROCEDURE NAP_SpecialCustSettingGameType_Sel
AS
/*
	Created: Dom
		Date: 2014-09-03
		Task: Get gametypename of Keno
		DB: DBTXN/CustDB
		
		Revisions:
*/
BEGIN
	SELECT GameTypeID, GameTypeName FROM [bodb02].[dbo].[GameType] WITH(NOLOCK)
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialCustSettingGameType_Sel] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[NAP_SpecialCustSettingGameType_Sel] TO [bodbLicenseeNet]
GO 
