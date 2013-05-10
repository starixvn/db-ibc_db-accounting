DROP VIEW Stake_Per_CustidMatchid1
DROP VIEW Stake_Per_CustidMatchid2
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
	Declare @totalbet money
	SELECT @totalbet = IsNull(SUM(CASE WHEN b.odds < -1 THEN ABS(b.odds) ELSE 1 END * b.stake),0)
	FROM 
		dbo.bettrans b (Nolock)
		INNER JOIN match m (Nolock) ON b.matchid = m.matchid
	WHERE
		b.custid = @custid --AND b.winlostdate = @eventdate
		AND m.homeid = @homeid AND m.awayid = @awayid
		AND m.leagueid = @leagueid AND m.eventdate = @eventdate
		AND b.status NOT IN ('VOID', 'REJECT')

	IF @totalbet + @stake > @maxpermatch SELECT @continue = 0, @status = 'overmaxpermatch'
END

	SELECT @cont = @continue, @res = @status, @ev_date = @eventdate
