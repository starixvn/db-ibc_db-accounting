 ALTER PROCEDURE [dbo].[DBA_GenTestBetList]
	@CustID		INT,
	@bettype	INT,
	@OddsType	TINYINT = 2, --0: Odds < 0, 1: Odds > 0, 2: All
	@OddsMode	TINYINT	= 1, --1: Dec, 2: HK, 3: Indo, 4: MY, 5: US
	@StatusID	TINYINT = 255, --111: DRAW, 112: WON, 113: LOSE, 101: VOID, 102: REJECT, 103: REFUND, 255: All
	@betteam	VARCHAR(10) = 'All',
	@ErrMsg		NVARCHAR(200) = '' OUTPUT
AS
BEGIN		
	DECLARE @roleID 		INT,
			@srecommend		INT, 
			@mrecommend		INT,
			@recommend		INT,
			@UserName		VARCHAR(100),
			@Currency		INT,
			@CurrencyName	VARCHAR(100), 
			@MoveBetsDay	DATETIME
	DECLARE	@Ticket		TABLE (TransID BIGINT, winlostdate DATETIME, matchid INT)
	--DECLARE	@Match		TABLE (TransID BIGINT, winlostdate DATETIME, matchid INT)
	
	--SELECT @MoveBetsDay = MAX(eventdate) FROM match14 WITH(NOLOCK) 
	SELECT @UserName = username, @Currency = currency, @roleID = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
	FROM custInfo WITH (NOLOCK)
	WHERE CustID = @CustID
	
	SELECT @CurrencyName = currency FROM exchange WITH (NOLOCK) WHERE exchangeid = @Currency	
	
	IF @roleID <> 1
	BEGIN
		SELECT @ErrMsg = 'Customer doesn''t a member'
		RETURN
	END
		
	IF EXISTS (	SELECT 1 
				FROM bettrans b WITH (NOLOCK) 
				WHERE bettype = @bettype
					AND 1 = CASE WHEN @OddsType = 2 THEN 1 
								 WHEN @OddsType = 0 AND odds < 0 THEN 1 
								 WHEN @OddsType = 1 AND odds > 0 THEN 1 ELSE 0 END
					AND statusID = CASE WHEN @StatusID = 255 THEN statusID ELSE @StatusID END								
					AND betteam = CASE WHEN @betteam = 'All' THEN betteam ELSE @betteam END
					AND oddstype = @OddsMode)
	BEGIN
		INSERT INTO bettrans (custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, RecommDate)
		OUTPUT INSERTED.transid, INSERTED.winlostdate, INSERTED.matchid INTO @Ticket (TransID, winlostdate, matchid)
		SELECT TOP 3 @CustID, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, b.livehomescore, b.liveawayscore, liveindicator, betteam, b.creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, b.matchid, @recommend, @mrecommend, b.ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, @Currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, @srecommend, @UserName, @CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2, RecommDate
		FROM bettrans b WITH (NOLOCK) 
		WHERE bettype = @bettype 
			AND 1 = CASE WHEN @OddsType = 2 THEN 1 
						 WHEN @OddsType = 0 AND odds < 0 THEN 1 
						 WHEN @OddsType = 1 AND odds > 0 THEN 1 ELSE 0 END
			AND statusID = CASE WHEN @StatusID = 255 THEN statusID ELSE @StatusID END								
			AND betteam = CASE WHEN @betteam = 'All' THEN betteam ELSE @betteam END
			AND oddstype = @OddsMode
			
		SELECT * FROM bettrans WITH (NOLOCK) WHERE transid IN (SELECT TransID FROM @Ticket)
	END
	ELSE IF EXISTS (SELECT 1 
					FROM bettrans14 b WITH (NOLOCK) 
					WHERE bettype = @bettype
						AND 1 = CASE WHEN @OddsType = 2 THEN 1 
									 WHEN @OddsType = 0 AND odds < 0 THEN 1 
									 WHEN @OddsType = 1 AND odds > 0 THEN 1 ELSE 0 END
						AND statusID = CASE WHEN @StatusID = 255 THEN statusID ELSE @StatusID END								
						AND betteam = CASE WHEN @betteam = 'All' THEN betteam ELSE @betteam END
						AND oddstype = @OddsMode)
	BEGIN
		INSERT INTO bettrans14 (custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, livehomescore, liveawayscore, liveindicator, betteam, creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, matchid, recommend, mrecommend, ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, srecommend, Username, CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2)
		OUTPUT INSERTED.transid, INSERTED.winlostdate, INSERTED.matchid INTO @Ticket (TransID, winlostdate, matchid)
		SELECT TOP 3 @CustID, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, awinlost, mwinlost, playercomm, comm, acomm, apositiontaking, mpositiontaking, tpositiontaking, playerdiscount, discount, adiscount, b.livehomescore, b.liveawayscore, liveindicator, betteam, b.creator, refno, comstatus, winlostdate, betfrom, betcheck, checktime, oddsspread, actualrate, b.matchid, @recommend, @mrecommend, b.ruben, betid, statuswinlost, modds, bettype, betdaqid, actual_stake, @Currency, ip, transdesc, sdiscount, scomm, spositiontaking, swinlost, @srecommend, @UserName, @CurrencyName, virtualrate, oddstype, statusID, currency2, balance, SecAcceptFlag, transid2
		FROM bettrans14 b WITH (NOLOCK) 
		WHERE bettype = @bettype
			AND 1 = CASE WHEN @OddsType = 2 THEN 1 
						 WHEN @OddsType = 0 AND odds < 0 THEN 1 
						 WHEN @OddsType = 1 AND odds > 0 THEN 1 ELSE 0 END
			AND statusID = CASE WHEN @StatusID = 255 THEN statusID ELSE @StatusID END								
			AND betteam = CASE WHEN @betteam = 'All' THEN betteam ELSE @betteam END
			AND oddstype = @OddsMode
			
		SELECT * FROM bettrans14 WITH (NOLOCK) WHERE transid IN (SELECT TransID FROM @Ticket)
	END				
END
