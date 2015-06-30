 ALTER PROCEDURE DBA_Gen_TicketVirtualHR
	@CustID INT,
	@BetType INT,
	-- VSRaceInfo.EventID = bettrans.matchid
	@Orid INT, -- VSOutright.Orid = bettrans.oddsid
	@StatusID TINYINT,		
	@Type TINYINT = 0, -- 0: bettrans, 14: bettrans14
	@ErrMsg NVARCHAR(500) OUTPUT
AS
BEGIN	
	DECLARE @recommend INT, @mrecommend INT, @srecommend INT, @UserName NVARCHAR(50), @EventID INT, @WinOdds SMALLMONEY, @PlaceOdds SMALLMONEY
	DECLARE @NewTransID BIGINT, @OldTransID BIGINT
	DECLARE @WinlossDate SMALLDATETIME, @Transdate DATETIME
	SELECT @WinlossDate = convert(varchar(10),getdate(),101)	
	
	SELECT @recommend = recommend, @mrecommend = mrecommend, @srecommend = srecommend, @UserName = username
	FROM custInfo c with (NOLOCK)
	where CustID = @CustID
	
	IF @Type = 0
	BEGIN
		SELECT @Transdate = getdate()
		SELECT @EventID = EventID, @WinOdds = WinOdds, @PlaceOdds = PlaceOdds FROM VSOutright WHERE Orid = @Orid
		
		IF @BetType = 1231
		BEGIN
			INSERT INTO bettrans (custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, RecommDate)
			SELECT top 1 @CustID, @Transdate, @Orid, @WinOdds, hdp2, @WinOdds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, @WinlossDate, betfrom, betcheck, checktime, oddsspread, actualrate, @EventID, @recommend, @mrecommend, ruben, betid, statuswinlost, modds, @BetType, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, @srecommend, @Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, RecommDate
			FROM bettrans WITH (NOLOCK)
			WHERE (bettype IN (31,32) or bettype IN (1231,1232)) and statusID = @StatusID
			IF @@Rowcount = 0
				Select 'No data'
		END	
		
		IF @BetType = 1232
		BEGIN
			INSERT INTO bettrans (custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, RecommDate)
			SELECT top 1 @CustID, @Transdate, @Orid, hdp1, @PlaceOdds, @PlaceOdds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, @WinlossDate, betfrom, betcheck, checktime, oddsspread, actualrate, @EventID, @recommend, @mrecommend, ruben, betid, statuswinlost, modds, @BetType, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, @srecommend, @Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, RecommDate
			FROM bettrans WITH (NOLOCK)
			WHERE (bettype IN (31,32) or bettype IN (1231,1232)) and statusID = @StatusID
			IF @@Rowcount = 0
				Select 'No data'
		END	
		
		IF @BetType = 1233
		BEGIN			
			
			SELECT top 1 @OldTransID = transid
			FROM bettrans WITH (NOLOCK)
			WHERE (bettype = 33 or bettype = 1233) and statusID = @StatusID
			
			INSERT INTO bettrans (custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, RecommDate)
			SELECT @CustID, @Transdate, @Orid, @WinOdds, @PlaceOdds, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, @OldTransID + 1000000000000, comstatus, @WinlossDate, betfrom, betcheck, checktime, oddsspread, actualrate, @EventID, @recommend, @mrecommend, ruben, betid, statuswinlost, modds, @BetType, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, @srecommend, @Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, RecommDate
			FROM bettrans WITH (NOLOCK)
			WHERE transid = @OldTransID
			
			IF @@Rowcount = 0
				Select 'No data'
			SELECT @NewTransID = scope_identity()
			
			INSERT INTO bettransm (custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, finalodds, isfinish, statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, statusID)
			SELECT @CustID, @Transdate, @Orid, 
				case when bettype = 31 or bettype = 1231 then @WinOdds else hdp1 end, 
				case when bettype = 32 or bettype = 1232 then @PlaceOdds else hdp2 end,
			odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, @OldTransID + 1000000000000, comstatus, @WinlossDate, betfrom, betcheck, checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, @EventID, matchdate, finalodds, isfinish, statuswinlost, ruben, bettype + 1200, spositiontaking, swinlost, sdiscount, scomm, statusID
			FROM bettransm bm WITH (NOLOCK)			
			WHERE bm.refno = @OldTransID and (bettype in (31, 32)OR bettype IN (1231, 1232))
		END
	END
	ELSE
	BEGIN
		SELECT @EventID = EventID, @WinOdds = WinOdds, @PlaceOdds = PlaceOdds, @Transdate = KickoffTime FROM VSOutright14 WHERE Orid = @Orid
		
		IF @BetType = 1231
		BEGIN
			INSERT INTO bettrans14 (custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2)
			SELECT top 1 @CustID, transdate, @Orid, @WinOdds, hdp2, @WinOdds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, @WinlossDate, betfrom, betcheck, checktime, oddsspread, actualrate, @EventID, @recommend, @mrecommend, ruben, betid, statuswinlost, modds, @BetType, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, @srecommend, @Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2
			FROM bettrans14 WITH (NOLOCK)
			WHERE (bettype IN (31,32) or bettype IN (1231,1232)) and statusID = @StatusID
			IF @@Rowcount = 0
				Select 'No data'
		END	
		
		IF @BetType = 1232
		BEGIN
			INSERT INTO bettrans14 (custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2)
			SELECT top 1 @CustID, transdate, @Orid, hdp1, @PlaceOdds, @PlaceOdds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, @WinlossDate, betfrom, betcheck, checktime, oddsspread, actualrate, @EventID, @recommend, @mrecommend, ruben, betid, statuswinlost, modds, @BetType, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, @srecommend, @Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2
			FROM bettrans14 WITH (NOLOCK)
			WHERE (bettype IN (31,32) or bettype IN (1231,1232)) and statusID = @StatusID
			IF @@Rowcount = 0
				Select 'No data'
		END	
		
		IF @BetType = 1233
		BEGIN			
			
			SELECT top 1 @OldTransID = transid
			FROM bettrans14 WITH (NOLOCK)
			WHERE (bettype = 33 or bettype = 1233) and statusID = @StatusID
			
			INSERT INTO bettrans14 (custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2)
			SELECT @CustID, transdate, @Orid, @WinOdds, @PlaceOdds, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, @OldTransID + 1000000000000, comstatus, @WinlossDate, betfrom, betcheck, checktime, oddsspread, actualrate, @EventID, @recommend, @mrecommend, ruben, betid, statuswinlost, modds, @BetType, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, @srecommend, @Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2
			FROM bettrans14 WITH (NOLOCK)
			WHERE transid = @OldTransID
			
			IF @@Rowcount = 0
				Select 'No data'
			SELECT @NewTransID = scope_identity()
			
			INSERT INTO bettransm14 (custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, matchid, matchdate, finalodds, isfinish, statuswinlost, ruben, bettype, spositiontaking, swinlost, sdiscount, scomm, statusID)
			SELECT @CustID, transdate, @Orid, 
			case when bettype = 31 or bettype = 1231 then @WinOdds else hdp1 end, 
			case when bettype = 32 or bettype = 1232 then @PlaceOdds else hdp2 end,
			odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator, @OldTransID + 1000000000000, comstatus, @WinlossDate, betfrom, betcheck, checktime, oddsspread, apositiontaking, mpositiontaking, tpositiontaking, awinlost, mwinlost, playerdiscount, discount, adiscount, playercomm, comm, acomm, actualrate, @EventID, matchdate, finalodds, isfinish, statuswinlost, ruben, bettype + 1200, spositiontaking, swinlost, sdiscount, scomm, statusID
			FROM bettransm14 bm WITH (NOLOCK)			
			WHERE bm.refno = @OldTransID and (bettype in (31, 32)OR bettype IN (1231, 1232))
		END
	END
END
	
/*
DECLARE @ErrMsg NVARCHAR(500)
EXEC DBA_Gen_TicketVirtualHR @CustID = 1537042, @BetType = 1231, @Orid = 40561, @StatusID = 113, @ErrMsg = @ErrMsg
SELECT @ErrMsg
*/

	