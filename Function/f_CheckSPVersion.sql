USE [bodb02]
GO
/****** Object:  UserDefinedFunction [dbo].[f_CheckSPVersion]    Script Date: 04/01/2016 02:51:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  User Defined Function dbo.f_CheckSPVersion    Script Date: 3/24/2016 12:49:31 PM ******/
/****** Object:  User Defined Function dbo.f_CheckSPVersion    Script Date: 3/23/2016 2:46:17 PM ******/
ALTER FUNCTION [dbo].[f_CheckSPVersion]
(
	@PROCID INT
)
RETURNS BIT
AS
BEGIN
	IF	OBJECT_NAME(@PROCID) LIKE '%_xtest%'
		OR OBJECT_NAME(@PROCID) LIKE '%_xpre%'
		OR OBJECT_NAME(@PROCID) LIKE '%_UAT1%'
		OR OBJECT_NAME(@PROCID) LIKE '%_UAT2%'
		OR OBJECT_NAME(@PROCID) LIKE '%_UAT3%'
		OR OBJECT_NAME(@PROCID) LIKE '%_UAT4%'
		RETURN 1
	RETURN 0
END

GO
GRANT VIEW DEFINITION ON [dbo].[f_CheckSPVersion] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[f_CheckSPVersion] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[f_CheckSPVersion] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[f_CheckSPVersion] TO [vnteam] AS [dbo]