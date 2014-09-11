
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_SaveBet_GetJob    Script Date: 9/10/2014 3:22:01 PM ******/

CREATE PROCEDURE [dbo].[NAP_SaveBet_GetJob]
	@MatchID INT = 0
AS

/*
	Created by: Dom
	Date:2014-04-29
	Task: Get Job for Windows service
	DB: DBACC.BODB_ACC
	
	Revisions:
		
*/

BEGIN
	IF @matchid =0
		SELECT JobID,s.LiveIndicator,s.Bettype,s.TypeName,ml.MatchID,s.JobType,ml.EventDate FROM ServiceJob s WITH(NOLOCK)
		INNER JOIN (
			SELECT TOP 1 * FROM MatchList ml WITH(NOLOCK) WHERE JobGenerated = 1 AND JobFinished = 0 ORDER BY EventDate ASC
		) ml ON ml.MatchID = s.MatchID
	ELSE
			SELECT JobID,s.LiveIndicator,s.Bettype,s.TypeName,ml.MatchID,s.JobType,ml.EventDate FROM ServiceJob s WITH(NOLOCK)
		INNER JOIN (
			SELECT TOP 1 * FROM MatchList ml WITH(NOLOCK) WHERE ml.MatchID = @MatchID
		) ml ON ml.MatchID = s.MatchID


	/*
	SELECT JobID,s.LiveIndicator,s.Bettype,s.TypeName,ml.MatchID,s.JobType,ml.EventDate FROM ServiceJob s WITH(NOLOCK)
	INNER JOIN (
		SELECT  * FROM MatchList ml WITH(NOLOCK) WHERE JobGenerated = 1 AND JobFinished = 0 and ml.MatchID=8786329
	) ml ON ml.MatchID = s.MatchID*/
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[NAP_SaveBet_GetJob] TO [bodbAdminNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SaveBet_GetJob] TO [vnteam]
GO 
