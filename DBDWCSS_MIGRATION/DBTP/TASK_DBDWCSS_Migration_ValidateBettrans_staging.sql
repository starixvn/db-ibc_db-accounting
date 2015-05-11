ALTER PROCEDURE [dbo].[TASK_DBDWCSS_Migration_ValidateBettrans_staging]
AS
/*   
 Task : validate data at bettrans_staging before moving
 DB: DBTP.TPDB 
 Revisions:   
  - 20121010@viet: create SP   
*/ 
SET NOCOUNT ON	
	
declare @t as bigint, @maxtstamp binary(8)
select @maxtstamp = max(tstamp) from dbo.bettrans_staging with(nolock)
SET @t = CAST(@maxtstamp as bigint)

declare @temp as table(winlostdate smalldatetime, transCNT int)
INSERT INTO @temp(winlostdate, transCNT)
select winlostdate, COUNT(1)
from dbo.bettrans_staging with(nolock)
where bettype = 19999
group by winlostdate	

IF @@ROWCOUNT > 0
BEGIN
	---- over 10k tickets of the same day, they're movingbet -> IGNORE
	DELETE dbo.bettrans_staging
	WHERE bettype = 19999
		and winlostdate in (select winlostdate from @temp where transCNT > 10000)
	------------------------------------------
		
	DELETE FROM @temp where transCNT > 10000
	IF exists (select top 1 1 from @temp) --there are tickets which got modified recently on bettrans14, need to copy again
	BEGIN		
		declare @tempCustomer as table(custid int, winlostdate smalldatetime)
		
		DELETE dbo.bettrans_staging
		OUTPUT deleted.custid, deleted.winlostdate INTO @tempCustomer
		WHERE bettype = 19999
			
		SET IDENTITY_INSERT staging_bettrans ON			
		INSERT INTO dbo.staging_bettrans (
			recommid, LCSid, transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, 
			apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, 
			refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, 
			modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, 
			virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, dangerous, recommdate
		)
		SELECT recommid, LCSid, transid, b.custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, 
			apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, 
			refno, comstatus, b.winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, 
			modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, 
			virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, dangerous, recommdate		
		FROM dbo.bettrans14 b with(rowlock)
			INNER JOIN @tempCustomer c on b.winlostdate = c.winlostdate and b.custid = c.custid		 		
		SET IDENTITY_INSERT staging_bettrans OFF			
	END
END

IF @@ERROR = 0 EXEC DBDWCSS.bodb_staging.dbo.StagingUpdTimestamp @tablename = 'bettrans', @tstamp = @t
		
SET NOCOUNT OFF
