 USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Admin_PreCalculate_s161_Live]    Script Date: 12/9/2013 12:28:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Admin_PreCalculate_s161_Live] @matchid INT
	,@DrawSeq TINYINT
	,@Number TINYINT
AS
/*
	Created by:[Viet]
	Date:[20131208]
	Task: Settlement 
	Original SP: Admin_Calculate_s161_Live
	DB: DBTXN/BODB02
	
	Revisions:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @IgnoreList VARCHAR(200)
	SET @IgnoreList = 'DB04,DB042,DB043,DB044'

	DECLARE @modds SMALLMONEY, @winningOdds SMALLMONEY, @commWinRate SMALLMONEY, @commLostRate SMALLMONEY
	DECLARE @_xml XML, @_sXML VARCHAR(MAX)

	DECLARE @subtable TABLE(transid BIGINT, winlost MONEY, awinlost MONEY, mwinlost MONEY, swinlost MONEY,
		playercomm MONEY, comm MONEY, acomm MONEY, scomm MONEY, statusid TINYINT, modds SMALLMONEY)

	SELECT transid, actual_stake, stake, odds, comstatus, modds, betteam, hdp1, hdp2, livehomescore, liveawayscore,
		apositiontaking, mpositiontaking, spositiontaking, playerdiscount,discount, adiscount, sdiscount,
		WinLost, aWinLost, mWinLost, sWinLost, PlayerComm, comm, acomm, scomm, StatusID, bettype, betid
	INTO #TempData				
	FROM dbo.bettrans WITH(ROWLOCK)	
	WHERE matchid = @matchid 
		AND bettype IN (85, 86, 87, 89, 90) 
		AND liveindicator = 1 
		AND statusID NOT IN (101, 102) -- VOID, REJECT
		AND livehomescore + liveawayscore + CASE WHEN bettype = 87 THEN 2 ELSE 1 END = @DrawSeq
	

	IF @@ROWCOUNT = 0 RETURN
		
	UPDATE #TempData
	SET @modds = modds = CASE
			WHEN bettype = 85 AND betteam = N'h' AND @Number >= 38   THEN 1
			WHEN bettype = 85 AND betteam = N'a' AND @Number <= 37   THEN 1
			WHEN bettype = 86 AND betteam = N'h' AND @Number %2 = 1  THEN 1
			WHEN bettype = 86 AND betteam = N'a' AND @Number %2 = 0  THEN 1
			WHEN bettype = 87 AND betteam = N'h' AND @Number > betid THEN 1
			WHEN bettype = 87 AND betteam = N'a' AND @Number < betid THEN 1
			WHEN bettype = 89 AND betteam = N'1:1' AND @Number >= 38 AND @Number %2 = 1 THEN 1 -- OVER / ODD
			WHEN bettype = 89 AND betteam = N'1:2' AND @Number >= 38 AND @Number %2 = 0 THEN 1 -- OVER / EVEN
			WHEN bettype = 89 AND betteam = N'2:1' AND @Number <= 37 AND @Number %2 = 1 THEN 1 -- UNDER / ODD
			WHEN bettype = 89 AND betteam = N'2:2' AND @Number <= 37 AND @Number %2 = 0 THEN 1 -- UNDER / EVEN
			WHEN bettype = 90 AND HDP1 = 1 AND CEILING(@Number/5.0) = betteam THEN 1 
			WHEN bettype = 90 AND HDP1 = 2 AND CEILING(@Number/15.0) = betteam THEN 1 
			WHEN bettype = 90 AND HDP1 = 3 AND CEILING(@Number/25.0) = betteam THEN 1 
			WHEN bettype = 90 AND HDP1 = 4 AND @Number % 5 = CASE betteam WHEN 5 THEN 0 ELSE betteam END THEN 1 
			ELSE -1 -- lose
			END
		,@winningOdds = CASE 
			WHEN odds<0 THEN 1 
			ELSE CASE WHEN bettype IN (89,90) THEN odds-1 ELSE odds END
			END
		,WinLost = CASE
			WHEN @modds = 1		THEN actual_stake + stake * @winningOdds
			WHEN @modds = -1	THEN 0
			END
		,aWinLost = CASE
			WHEN @modds = 1		THEN stake * @winningOdds * -apositiontaking
			WHEN @modds = -1	THEN actual_stake * apositiontaking
			END
		,mWinLost = CASE
			WHEN @modds = 1 	THEN stake * @winningOdds * -mpositiontaking
			WHEN @modds = -1 	THEN actual_stake * mpositiontaking
			END
		,sWinLost = CASE
			WHEN @modds = 1 	THEN stake * @winningOdds * -spositiontaking
			WHEN @modds = -1 	THEN actual_stake * spositiontaking
			END
		,PlayerComm = CASE
			WHEN @modds = 1 	THEN playerdiscount * stake
			WHEN @modds = -1 	THEN playerdiscount * stake
			END
		,Comm = CASE
			WHEN @modds = 1  	THEN discount * stake * (1-apositiontaking)
			WHEN @modds = -1  	THEN discount * stake * (1-apositiontaking)
			END
		,aComm = CASE
			WHEN @modds = 1 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
			WHEN @modds = -1 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
			END
		,sComm = CASE
			WHEN @modds = 1  	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
			WHEN @modds = -1 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
			END
		,StatusID = CASE
			WHEN @modds = 1 THEN 112 --WON
			WHEN @modds = 0 THEN 111 --DRAW
			WHEN @modds = -1 THEN 113 --LOSE
			END	

	WHILE (1 = 1)
	BEGIN
		DELETE @subtable

		DELETE TOP (20) #TempData
		OUTPUT deleted.transid, deleted.winlost, deleted.awinlost, deleted.mwinlost, deleted.swinlost, 	
			deleted.playercomm, deleted.comm, deleted.acomm, deleted.scomm, deleted.statusid, deleted.modds	
		INTO @subtable(transid, winlost, awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm, statusid, modds)	

		IF @@ROWCOUNT = 0 BREAK

		SET @_xml = (
				SELECT transid '@q'
					,NULLIF(winlost, 0) '@a'
					,NULLIF(awinlost, 0) '@z'
					,NULLIF(mwinlost, 0) '@w'
					,NULLIF(swinlost, 0) '@s'
					,NULLIF(playercomm, 0) '@x'
					,NULLIF(comm, 0) '@e'
					,NULLIF(acomm, 0) '@d'
					,NULLIF(scomm, 0) '@c'
					,statusid '@r'
					,NULLIF(modds, 0) '@f'
				FROM @subtable
				FOR XML PATH('r'), ROOT('root'), TYPE
				)

		SELECT @_sXML = CONVERT(VARCHAR(max), @_xml)

		EXEC dbo.Bet_ExecRep_05 @IgnoreList = @IgnoreList
			,@updatetype = 1 --calculate mode
			,@_sXML = @_sXML		
	END

	DROP TABLE #TempData
END

