USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_CheckRep]    Script Date: 12/01/2009 23:14:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_CheckRep]
	@maxTransDate datetime OUTPUT,
	@Bias int OUTPUT
AS
/*		
	DB: All servers.bodb02 (DB02, DB03, DB053, DB052, DB054, DB06, DB07)
	
*/
SET NOCOUNT ON

	SELECT TOP 1 @maxTransDate = transdate FROM bodb02.dbo.bettrans with (nolock)
	ORDER BY transid DESC

	SET @Bias = DATEDIFF(millisecond, CURRENT_TIMESTAMP, @maxTransDate)
