
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_Task_SaveBet_GenerateServiceJob    Script Date: 9/10/2014 3:22:01 PM ******/
ALTER PROCEDURE [dbo].[NAP_Task_SaveBet_GenerateServiceJob]
AS

/*
	Created by: Dom
	Date:2014-05-05
	Task: Generating Job for service.
	DB: DB06.BODB_ACC
	
	Revisions:
		-20150529@Jim: add Metric Gaming
*/

BEGIN
	
	DECLARE @movebetdate DATETIME
	SELECT @movebetdate = max(eventdate) 
    FROM  bodb02.dbo.match14 WITH(NOLOCK)
	--SELECT * FROM ServiceJob WHERE MatchID IN(SELECT MatchList.MatchID FROM MatchList WITH(NOLOCK) WHERE EventDate <= @movebetdate )
	DELETE ServiceJob WHERE MatchID IN(SELECT MatchList.MatchID FROM MatchList WITH(NOLOCK) WHERE EventDate <= @movebetdate AND JobFinished=1 AND JobGenerated=1)

	DECLARE @MatchID INT,@ID INT,@Total INT

	CREATE TABLE #Match (ID INT IDENTITY(1,1), MatchID INT)
	INSERT INTO #Match(MatchID)
	SELECT MatchID FROM MatchList WITH (NOLOCK) 
	WHERE JobGenerated = 0

	--update top (10) MatchList set JobGenerated = 0
	IF @@rowcount =0 RETURN;

	SELECT DISTINCT MatchID, Bettype, LiveIndicator
	INTO #MatchBettype
	FROM bodb02.dbo.bettrans WITH(NOLOCK)
	WHERE matchid IN (SELECT MatchID FROM #Match)
		AND bettype NOT IN(SELECT bettype FROM bodb02.dbo.f_VSHorseRacingByBettype())

	SET @ID = 1
	SELECT @ID = 1,@Total = COUNT(*) FROM #Match

	WHILE @ID <= @Total
	BEGIN
		SELECT @MatchID=MatchID FROM #Match WHERE ID = @ID
		IF(NOT EXISTS(SELECT * FROM #MatchBettype WHERE MatchID=@MatchID))
		BEGIN
			DELETE MatchList WITH(ROWLOCK,UPDLOCK) WHERE MatchID = @MatchID
		END
		ELSE
		BEGIN
			INSERT INTO ServiceJob(MatchID,Bettype,LiveIndicator,JobType,TypeName)
			SELECT DISTINCT @MatchID, 0, 0, 'SUM', ''
			FROM #MatchBettype WHERE MatchID = @MatchID
			UNION ALL
			SELECT @MatchID, Bettype, liveindicator, 'TB', typenamee
			FROM #MatchBettype mb INNER JOIN bodb02.dbo.bettype WITH(NOLOCK) ON typeid = mb.bettype
			WHERE MatchID = @MatchID 
				AND (bettype IN (1,3,7,8,20)
					OR bettype BETWEEN 801 AND 808
					)
				AND liveindicator = 0
			UNION ALL
			SELECT @MatchID, Bettype, liveindicator, 'TB', typenamee
			FROM #MatchBettype  mb INNER JOIN bodb02.dbo.bettype WITH(NOLOCK) ON typeid = mb.bettype
			WHERE MatchID = @MatchID 
				AND (bettype IN (1,3,7,8,20)
					OR bettype BETWEEN 801 AND 808
					)
				AND liveindicator = 1
			UNION ALL
			SELECT @MatchID, Bettype, liveindicator, 'BETS', typenamee
			FROM #MatchBettype mb INNER JOIN bodb02.dbo.bettype WITH(NOLOCK) ON typeid = mb.bettype 
			WHERE MatchID = @MatchID 
			UNION ALL
			SELECT DISTINCT @MatchID, 0, 0, 'END',''
			FROM #MatchBettype 
			WHERE MatchID = @MatchID 

			UPDATE MatchList SET JobGenerated = 1 WHERE MatchID = @MatchID
		END
		SET @ID = @ID + 1
	
	END
	
	DROP TABLE #Match
	DROP TABLE #MatchBettype

END 


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
