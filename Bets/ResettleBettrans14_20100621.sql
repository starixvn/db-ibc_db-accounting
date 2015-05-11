DECLARE @matchid INT,
    @fth SMALLINT,
    @fta SMALLINT,   
    @hth SMALLINT,
    @hta SMALLINT,
    @ACTION VARCHAR(10),
    @actionid TINYINT,
    @START DATETIME,
    @stop DATETIME,
    @LogData NVARCHAR(300),
    @creator INT,
    @winlostdate smalldatetime

SELECT
    @MatchID = 790046,
    @fth = 3,
    @fta = 4,
    @hth = 2,
    @hta = 1,
    @ACTION = 'CAL-FT',
    @creator = 360418,
    @START = CURRENT_TIMESTAMP,
    @winlostdate = eventdate
FROM  dbo.match14 (nolock) WHERE matchid = 790046

UPDATE dbo.match14 WITH (rowlock, updlock)
SET finalhomescore = @fth, finalawayscore = @fta
WHERE matchid = @matchid

EXEC dbo.Acc_ExecRep_09
    @matchid = @matchid,
    @bettype = 1,
    @fth = @fth,
    @fta = @fta,
	@winlostdate = @winlostdate

EXEC dbo.Acc_ExecRep_09
    @matchid = @matchid,
    @bettype = 2,
    @fth = @fth,
    @fta = @fta,
   	@winlostdate = @winlostdate

EXEC dbo.Acc_ExecRep_09
    @matchid = @matchid,
    @bettype = 3,
    @fth = @fth,
    @fta = @fta,
   	@winlostdate = @winlostdate
 
EXEC dbo.Acc_ExecRep_09
    @matchid = @matchid,
    @bettype = 5,
    @fth = @fth,
    @fta = @fta,
   	@winlostdate = @winlostdate

--Write log
SELECT @stop = CURRENT_TIMESTAMP
SELECT @LogData = 'Calculate (CAL-FT) for matchid:' + CAST(@matchid AS NVARCHAR(10))
    + ' score:' + CAST(ISNULL(@fth,0) AS NVARCHAR(10)) + '-' + CAST(ISNULL(@fta,0) AS NVARCHAR(10)) + ' HT:' + CAST(@hth AS NVARCHAR(10)) + '-' + CAST(@hta AS NVARCHAR(10))
    + ' GoalRecord: (Old: ) Remark( ) (' + CAST(DATEDIFF(millisecond, @START, @stop) AS NVARCHAR(50)) + ' ms)'
EXEC dbo.logfile @creator, @LogData

--Write Log Settle
DECLARE @Remark VARCHAR(50)
SELECT @ActionID = CASE @ACTION
        WHEN 'CAL' THEN 100
        WHEN 'CAL-FT' THEN 101
        WHEN 'CAL-HT' THEN 102
        WHEN 'UNDO' THEN 103
    END
SELECT @Remark = 'Duration:' + CAST(DATEDIFF(millisecond, @START, @stop) AS NVARCHAR(50)) + ' ms'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle
    @UserID = @creator,
    @Matchid = @matchid,
    @ActionID = @ActionID,
    @finalhomescore = @fth,
    @finalawayscore = @fta, 
    @hthomescore = @hth,
    @htawayscore = @hta,
    @GoalRecord = '',
    @betstatus = '',
    @Remark = @Remark,
    @IP = ''


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

DECLARE @modds SMALLMONEY,    @oddeven SMALLMONEY, @totalgoal SMALLMONEY,    @whowin SMALLMONEY

SELECT       
    @oddeven    = ((@fth + @fta) % 2),
    @totalgoal = (@fth + @fta),
    @whowin = (@fth - @fta)

IF @@SERVERNAME not in ('DB04', 'DB042')
    AND exists (SELECT 1 FROM dbo.sysobjects WHERE name = 'bettrans14')
BEGIN
    -- bettype 1 : Handicap
    IF @bettype = 1
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
            --[status] NOT IN (N'VOID', N'REJECT')
            statusID NOT IN (101,102)

    END
    -- bettype 2 : Odd/Even
    IF @bettype = 2
    BEGIN
        UPDATE bettrans14 WITH (ROWLOCK, UPDLOCK)
        SET @modds = modds = CASE
            WHEN betteam = 'h' AND @oddeven = 1 THEN 1
            WHEN betteam = 'a' AND @oddeven = 0 THEN 1
            ELSE -1
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
            WHEN @modds > 0 THEN 'WON'
            WHEN @modds = 0 THEN 'DRAW'
            WHEN @modds < 0 THEN 'LOSE'
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
            --status NOT IN ('VOID', 'REJECT')
            statusID NOT IN (101,102)
    END
    -- bettype 3 : Over/Under
    IF @bettype = 3
    BEGIN
        UPDATE dbo.bettrans14 WITH (ROWLOCK, UPDLOCK)
        SET @modds = modds = CASE betteam
            WHEN N'h' THEN @totalgoal-hdp1
            WHEN N'a' THEN hdp1-@totalgoal
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
            --status NOT IN (N'VOID', N'REJECT')
            statusID NOT IN (101,102)
    END
    -- bettype 5 : 1x2
    IF @bettype = 5
    BEGIN
        UPDATE bettrans14 WITH (ROWLOCK, UPDLOCK)
        SET @modds = modds = CASE
            WHEN betteam = '1' AND @whowin > 0 THEN 1
            WHEN betteam = '2' AND @whowin < 0 THEN 1
            WHEN betteam = 'X' AND @whowin = 0 THEN 1
            ELSE -1
            END,

        WinLost = CASE
            WHEN @modds >  0.25    THEN actual_stake + stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6,15,16) THEN odds-1 ELSE odds END) END)
            WHEN @modds =  0.25    THEN actual_stake + stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6,15,16) THEN odds-1 ELSE odds END) END) * 0.5
            WHEN @modds =  0    THEN actual_stake
            WHEN @modds = -0.25    THEN actual_stake * 0.5
            WHEN @modds < -0.25    THEN 0
            END,

        aWinLost = CASE
            WHEN @modds >  0.25    THEN stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6,15,16) THEN odds-1 ELSE odds END) END) * -apositiontaking
            WHEN @modds =  0.25    THEN stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6,15,16) THEN odds-1 ELSE odds END) END) * -apositiontaking * 0.5
            WHEN @modds =  0    THEN 0
            WHEN @modds = -0.25    THEN actual_stake * apositiontaking * 0.5
            WHEN @modds < -0.25    THEN actual_stake * apositiontaking
            END,
        mWinLost = CASE
            WHEN @modds >  0.25     THEN stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6,15,16) THEN odds-1 ELSE odds END) END) * -mpositiontaking
            WHEN @modds =  0.25     THEN stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6,15,16) THEN odds-1 ELSE odds END) END) * -mpositiontaking * 0.5
            WHEN @modds =  0        THEN 0
            WHEN @modds = -0.25     THEN actual_stake * mpositiontaking * 0.5
            WHEN @modds < -0.25     THEN actual_stake * mpositiontaking
            END,
        sWinLost = CASE
            WHEN @modds >  0.25     THEN stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6,15,16) THEN odds-1 ELSE odds END) END) * -spositiontaking
            WHEN @modds =  0.25     THEN stake * (CASE WHEN odds<0 THEN 1 ELSE (CASE WHEN bettype in (4,5,6,15,16) THEN odds-1 ELSE odds END) END) * -spositiontaking * 0.5
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
            WHEN @modds > 0 THEN 'WON'
            WHEN @modds = 0 THEN 'DRAW'
            WHEN @modds < 0 THEN 'LOSE'
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
            --status NOT IN ('VOID', 'REJECT')
            statusID NOT IN (101,102)
    END
END

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExecRep_09] TO [vnteam]