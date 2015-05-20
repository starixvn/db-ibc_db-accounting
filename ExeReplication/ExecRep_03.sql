ALTER PROCEDURE [dbo].[ExecRep_03]
	@fromdate smalldatetime,
	@todate smalldatetime
AS
/*
	Created:
	Task:
	
	Revisions
		- 20120426@Lukas: Get from production & exclude DB044
	
*/
IF @@SERVERNAME not in ('DB04', 'DB042', 'DB044')
BEGIN

	-- COPY bettrans FOR EACH matchid
	DECLARE @matchs TABLE (matchid int)
	INSERT INTO @matchs (matchid)
		SELECT distinct matchid
		FROM dbo.bettrans with (rowlock)
		WHERE winlostdate between @fromdate and @todate AND bettype < 19999

	DECLARE @matchid int
	DECLARE dataCursor
		CURSOR FAST_FORWARD
		FOR select matchid from @matchs
	OPEN dataCursor

	FETCH NEXT FROM dataCursor INTO @matchid
	WHILE (@@fetch_status <> -1)
	BEGIN
		IF (@@fetch_status <> -2)
		BEGIN

			insert into bettrans14 (
				[transid], [custid], [transdate], [oddsid], [hdp1], [hdp2], [odds], [stake], [status],statusID,
				[winlost], [awinlost], [mwinlost], [playercomm], [comm], [acomm],
				[apositiontaking], [mpositiontaking], [tpositiontaking], [playerdiscount], [discount], [adiscount], 
				[livehomescore], [liveawayscore], [liveindicator], [betteam], [creator], [refno], [comstatus], [winlostdate], 
				[betfrom], [betcheck], [checktime], [oddsspread], [actualrate], [matchid], 
				[recommend], [mrecommend], [ruben], [betid], [statuswinlost], [modds], [bettype], [betdaqid], 
				[actual_stake], [currency], [ip], [transdesc], [sdiscount], [scomm], [spositiontaking], 
				[swinlost], [srecommend], [virtualrate], [Username], [CurrencyName], [oddstype]
			)
			select 
				[transid], [custid], [transdate], [oddsid], [hdp1], [hdp2], [odds], [stake], [status],statusID,
				[winlost], [awinlost], [mwinlost], [playercomm], [comm], [acomm],
				[apositiontaking], [mpositiontaking], [tpositiontaking], [playerdiscount], [discount], [adiscount], 
				[livehomescore], [liveawayscore], [liveindicator], [betteam], [creator], [refno], [comstatus], [winlostdate], 
				[betfrom], [betcheck], [checktime], [oddsspread], [actualrate], [matchid], 
				[recommend], [mrecommend], [ruben], [betid], [statuswinlost], [modds], [bettype], [betdaqid], 
				[actual_stake], [currency], [ip], [transdesc], [sdiscount], [scomm], [spositiontaking], 
				[swinlost], [srecommend], [virtualrate], [Username], [CurrencyName], [oddstype]
			from dbo.bettrans with (nolock)
			where
				matchid = @matchid AND bettype < 19999
				AND winlostdate between @fromdate and @todate
		END

		FETCH NEXT FROM dataCursor INTO @matchid
	END

	CLOSE dataCursor
	DEALLOCATE dataCursor

	-- COPY from bettransm WHOLE at once
	insert into bettransm14 (
		[transid], [custid], [transdate], [oddsid], [hdp1], [hdp2], [odds], [stake], [status],statusID, [winlost], 
		[livehomescore], [liveawayscore], [liveindicator], [betteam], [creator], [refno], [comstatus], [winlostdate], 
		[betfrom], [betcheck], [checktime], [oddsspread], [apositiontaking], [mpositiontaking], [tpositiontaking], 
		[awinlost], [mwinlost], [playerdiscount], [discount], [adiscount], [playercomm], [comm], [acomm], 
		[actualrate], [matchid], [matchdate], [finalodds], [isfinish], [statuswinlost], [ruben], [bettype], 
		[spositiontaking], [swinlost], [sdiscount], [scomm]
	)
	select
		[transid], [custid], [transdate], [oddsid], [hdp1], [hdp2], [odds], [stake], [status],statusID, [winlost], 
		[livehomescore], [liveawayscore], [liveindicator], [betteam], [creator], [refno], [comstatus], [winlostdate], 
		[betfrom], [betcheck], [checktime], [oddsspread], [apositiontaking], [mpositiontaking], [tpositiontaking], 
		[awinlost], [mwinlost], [playerdiscount], [discount], [adiscount], [playercomm], [comm], [acomm], 
		[actualrate], [matchid], [matchdate], [finalodds], [isfinish], [statuswinlost], [ruben], [bettype], 
		[spositiontaking], [swinlost], [sdiscount], [scomm]
	from dbo.bettransm with (nolock)
	where winlostdate between @fromdate and @todate

END


GO
DENY EXECUTE ON [dbo].[ExecRep_03] TO [public]
GO
GRANT VIEW DEFINITION ON [dbo].[ExecRep_03] TO [vnteam]