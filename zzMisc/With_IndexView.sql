IF sessionproperty('ARITHABORT') = 0 SET ARITHABORT ON
IF sessionproperty('CONCAT_NULL_YIELDS_NULL') = 0 SET CONCAT_NULL_YIELDS_NULL ON
IF sessionproperty('QUOTED_IDENTIFIER') = 0 SET QUOTED_IDENTIFIER ON
IF sessionproperty('ANSI_NULLS') = 0 SET ANSI_NULLS ON
IF sessionproperty('ANSI_PADDING') = 0 SET ANSI_PADDING ON
IF sessionproperty('ANSI_WARNINGS') = 0 SET ANSI_WARNINGS ON
IF sessionproperty('NUMERIC_ROUNDABORT') = 1 SET NUMERIC_ROUNDABORT OFF

GO
CREATE VIEW Stake_Per_CustidMatchid1 WITH SCHEMABINDING AS 
SELECT bettrans.custid, bettrans.matchid,
	SUM(bettrans.stake) AS Stake,
	count_big(*) as cnt
FROM dbo.bettrans 
WHERE bettrans.ruben = 0 AND bettrans.odds >= -1
GROUP BY bettrans.custid, bettrans.matchid
GO
CREATE VIEW Stake_Per_CustidMatchid2 WITH SCHEMABINDING AS 
SELECT bettrans.custid, bettrans.matchid,
	SUM(bettrans.actual_stake) AS Stake,
	count_big(*) as cnt
FROM dbo.bettrans 
WHERE bettrans.ruben = 0 AND bettrans.odds < -1
GROUP BY bettrans.custid, bettrans.matchid
GO

CREATE UNIQUE CLUSTERED INDEX Stake_Per_CustidMatchid1_UNIQUE ON Stake_Per_CustidMatchid1 (custid, matchid)
CREATE UNIQUE CLUSTERED INDEX Stake_Per_CustidMatchid2_UNIQUE ON Stake_Per_CustidMatchid2 (custid, matchid)

CREATE INDEX IX_Stake_Per_CustidMatchid1 ON Stake_Per_CustidMatchid1 (custid, matchid)
CREATE INDEX IX_Stake_Per_CustidMatchid2 ON Stake_Per_CustidMatchid2 (custid, matchid)
GO

ALTER PROCEDURE [dbo].[Dot_Member_MatchCheck]
	@custid int, @stake money, @maxpermatch money,
	@matchid int, @liveindicator bit,
	@cont tinyint OUTPUT, @res nvarchar(50) OUTPUT,
	@ev_date smalldatetime OUTPUT
AS
	Declare @continue tinyint SET @continue = 1
	Declare @status varchar(50)

	Declare @homeid int, @awayid int, @leagueid int, @eventdate smalldatetime
	SELECT @homeid = homeid, @awayid = awayid, @leagueid = leagueid, @eventdate = eventdate
	FROM dbo.match (nolock)
	WHERE
		matchid = @matchid
		AND eventstatus = 'running'
		AND CASE WHEN @liveindicator = 1 THEN 1
		WHEN @liveindicator = 0 AND DATEADD(second,-10,kickofftime) > CURRENT_TIMESTAMP THEN 1
		ELSE 0 END = 1

	IF @@ROWCOUNT = 0 SELECT @continue = 0, @status = 'match-closed'

IF @continue = 1
BEGIN
	Declare @totalbet1 money, @totalbet2 money
/*
	SELECT @totalbet = IsNull(SUM(CASE WHEN b.odds < -1 THEN ABS(b.odds) ELSE 1 END * b.stake),0)
	FROM 
		dbo.bettrans b (Nolock)
		INNER JOIN match m (Nolock) ON b.matchid = m.matchid
	WHERE
		b.custid = @custid --AND b.winlostdate = @eventdate
		AND m.homeid = @homeid AND m.awayid = @awayid
		AND m.leagueid = @leagueid AND m.eventdate = @eventdate
		AND b.status NOT IN ('VOID', 'REJECT')
*/
	SELECT @totalbet1 = Stake
	FROM dbo.Stake_Per_CustidMatchid1 b INNER JOIN dbo.match m with (nolock)
	ON b.custid = @custid AND m.matchid = b.matchid
	WHERE
		m.homeid = @homeid AND m.awayid = @awayid
		AND m.leagueid = @leagueid AND m.eventdate = @eventdate

	SELECT @totalbet2 = Stake
	FROM dbo.Stake_Per_CustidMatchid2 b INNER JOIN dbo.match m with (nolock)
	ON b.custid = @custid AND m.matchid = b.matchid
	WHERE
		m.homeid = @homeid AND m.awayid = @awayid
		AND m.leagueid = @leagueid AND m.eventdate = @eventdate

	IF IsNull(@totalbet1, 0) + IsNull(@totalbet2, 0) + @stake > @maxpermatch SELECT @continue = 0, @status = 'overmaxpermatch'
END

	SELECT @cont = @continue, @res = @status, @ev_date = @eventdate

GO