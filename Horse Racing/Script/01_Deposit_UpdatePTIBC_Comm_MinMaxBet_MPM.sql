 /*
	Horse Racing Update PT & Commission & Min/Max Bet and Max Per Match 
	House: 50% 
	Agent: 0 % 
	Comm: 4% 
*/

DECLARE	@SRecommend INT, @MRecommend INT, @Recommend INT
		, @comm SMALLMONEY
		, @MinBet MONEY
		, @MaxBet MONEY
		, @MaxPerMatch MONEY 

SELECT	@SRecommend = 3287311
		, @MRecommend = 3287333
		, @Recommend = 3287348
		, @comm = 0.04 
		, @MinBet = 10
		, @MaxBet = 3999
		, @MaxPerMatch = 10000

--1. Update House PT 

UPDATE CustSuper WITH (UPDLOCK,ROWLOCK)
SET	autoibcpositiontaking_tote = 0.5
	,autoibcpositiontaking_fixed = 0.5
WHERE CustID = @SRecommend

--2. Update Commission for all lines 
--2.1 Super Level 

UPDATE	CustSetting3rd WITH (UPDLOCK,ROWLOCK)
SET		sdiscount = @comm
		, minbet = @MinBet
		, maxbet = @MaxBet 
WHERE	custid= @SRecommend
		AND bettype IN (31,32,41,42)
		AND Sporttype = 151

--2.2 Master Level


UPDATE	CustSetting3rd WITH (UPDLOCK,ROWLOCK)
SET		sdiscount = @comm
		, adiscount = @comm  
		, minbet = @MinBet
		, maxbet = @MaxBet 
WHERE	custid= @MRecommend
		AND bettype IN (31,32,41,42)
		AND Sporttype = 151

--2.3 Agent Level 

UPDATE	CustSetting3rd WITH (UPDLOCK,ROWLOCK)
SET		sdiscount = @comm
		, adiscount = @comm  
		, discount	= @comm 
		, minbet = @MinBet
		, maxbet = @MaxBet 
WHERE	custid= @Recommend
		AND bettype IN (31,32,41,42)
		AND Sporttype = 151

--2.4 Member Level 


UPDATE	CustSetting3rd WITH (UPDLOCK,ROWLOCK)
SET		sdiscount = @comm
		, adiscount = @comm  
		, discount	= @comm 
		, minbet = @MinBet
		, maxbet = @MaxBet 
WHERE	bettype IN (31,32,41,42)
		AND Sporttype = 151
		AND custID IN (
			SELECT CustID FROM Custinfo WITH (NOLOCK) WHERE RoleID = 1 AND Srecommend = @SRecommend 
		)

--3. Update MaxPerMatch 

UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
SET		MaxPerMatch151 = @MaxPerMatch
		, MaxPerMatch151_OT = @MaxPerMatch	
WHERE	Srecommend = @SRecommend 

