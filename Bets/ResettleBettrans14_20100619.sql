DECLARE    @matchid INT, @fth SMALLINT, @fta SMALLINT, @winlostdate smalldatetime

SELECT @MatchID = 792877, @fth = 77, @fta = 77, @winlostdate = eventdate   
FROM dbo.match14 (nolock) WHERE matchid = 792877

UPDATE dbo.match14 WITH (rowlock, updlock)
SET finalhomescore = @fth, finalawayscore = @fta
WHERE matchid = @matchid

EXEC dbo.Acc_ExecRep_09
    @matchid = @matchid,
    @bettype = 20,
    @fth = @fta, --GOLF: SPECIAL CALCULATE
    @fta = @fth,
    @winlostdate = @winlostdate

GO    

 USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_ExecRep_09]    Script Date: 06/19/2010 07:06:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_ExecRep_09]
    @matchid INT,
    @bettype TINYINT,
    @fth SMALLMONEY,
    @fta SMALLMONEY,
    @winlostdate SMALLDATETIME
AS
    DECLARE @modds SMALLMONEY, @RemoteCount INT

IF @@SERVERNAME not in ('DB04', 'DB042')
	AND exists (SELECT 1 FROM dbo.sysobjects WHERE name = 'bettrans14')
BEGIN
   
    UPDATE dbo.bettrans14 WITH (ROWLOCK, UPDLOCK)
    SET @modds = modds = CASE betteam
        WHEN N'h' THEN (hdp2-hdp1) + (@fth - livehomescore) - (@fta - liveawayscore)
        WHEN N'a' THEN (hdp1-hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
        END,

    WinLost = CASE
        WHEN @modds >  0.25    THEN actual_stake + stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6) THEN odds-1 ELSE odds END) END)
        WHEN @modds =  0.25    THEN actual_stake + stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6) THEN odds-1 ELSE odds END) END) * 0.5
        WHEN @modds =  0    THEN actual_stake
        WHEN @modds = -0.25    THEN actual_stake * 0.5
        WHEN @modds < -0.25    THEN 0
        END,

    aWinLost = CASE
        WHEN @modds >  0.25    THEN stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6) THEN odds-1 ELSE odds END) END) * -apositiontaking
        WHEN @modds =  0.25    THEN stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6) THEN odds-1 ELSE odds END) END) * -apositiontaking * 0.5
        WHEN @modds =  0    THEN 0
        WHEN @modds = -0.25    THEN actual_stake * apositiontaking * 0.5
        WHEN @modds < -0.25    THEN actual_stake * apositiontaking
        END,
    mWinLost = CASE
        WHEN @modds >  0.25     THEN stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6) THEN odds-1 ELSE odds END) END) * -mpositiontaking
        WHEN @modds =  0.25     THEN stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6) THEN odds-1 ELSE odds END) END) * -mpositiontaking * 0.5
        WHEN @modds =  0        THEN 0
        WHEN @modds = -0.25     THEN actual_stake * mpositiontaking * 0.5
        WHEN @modds < -0.25     THEN actual_stake * mpositiontaking
        END,
    sWinLost = CASE
        WHEN @modds >  0.25     THEN stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6) THEN odds-1 ELSE odds END) END) * -spositiontaking
        WHEN @modds =  0.25     THEN stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6) THEN odds-1 ELSE odds END) END) * -spositiontaking * 0.5
        WHEN @modds =  0        THEN 0
        WHEN @modds = -0.25     THEN actual_stake * spositiontaking * 0.5
        WHEN @modds < -0.25     THEN actual_stake * spositiontaking
        END,

    PlayerComm = CASE
        WHEN @modds >  0.25     THEN playerdiscount * stake
        WHEN @modds =  0.25     THEN playerdiscount * stake * 0.5
        WHEN @modds =  0        THEN 0
        WHEN @modds = -0.25     THEN playerdiscount * stake * 0.5
        WHEN @modds < -0.25     THEN playerdiscount * stake
        END,
    Comm = CASE
        WHEN @modds >  0.25     THEN discount * stake * (1-apositiontaking)
        WHEN @modds =  0.25     THEN discount * stake * (1-apositiontaking) * 0.5
        WHEN @modds =  0        THEN 0
        WHEN @modds = -0.25     THEN discount * stake * (1-apositiontaking) * 0.5
        WHEN @modds < -0.25     THEN discount * stake * (1-apositiontaking)
        END,
    aComm = CASE
        WHEN @modds >  0.25     THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
        WHEN @modds =  0.25     THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
        WHEN @modds =  0        THEN 0
        WHEN @modds = -0.25     THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
        WHEN @modds < -0.25     THEN adiscount * stake * (1-(mpositiontaking+apositiontaking))
        END,
    sComm = CASE
        WHEN @modds >  0.25     THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
        WHEN @modds =  0.25     THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
        WHEN @modds =  0        THEN 0
        WHEN @modds = -0.25     THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
        WHEN @modds < -0.25     THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
        END,

    Status = CASE
        WHEN @modds > 0 THEN N'WON'
        WHEN @modds = 0 THEN N'DRAW'
        WHEN @modds < 0 THEN N'LOSE'
        END,
    StatusID = CASE
        WHEN @modds > 0 THEN 112 --WON
        WHEN @modds = 0 THEN 111 --DRAW
        WHEN @modds < 0 THEN 113 --LOSE
        END,
    ruben=1

    WHERE
		winlostdate = @winlostdate AND
        matchid=@matchid AND
        bettype=@bettype AND       
        statusID NOT IN (101,102)

END

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExecRep_09] TO [vnteam]
