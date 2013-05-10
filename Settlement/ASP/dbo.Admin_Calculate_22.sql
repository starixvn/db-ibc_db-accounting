

ALTER PROCEDURE [dbo].[Admin_Calculate_22]
	@matchid int,
	@bettype smallint,
	@ResultString nvarchar(50),
	@betcount int = 0
AS
IF @betcount = 0 AND @@SERVERNAME NOT LIKE N'DBIOM%' RETURN

/*
Created: 20090203@Joe
Task : Settlement for Next Goal Bettype  

Revisions:
    - 20090204@Thien: Revise and add description
    - 20090310@Daniel: Add Handicap in calculation
 	- 20090423@PhuongDao: Change DB04 to DB042
 	- 20100424@Henry: Update column StatusID of Bettrans (DRAW:111, WON: 112, LOSE: 113)
 	- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
	- 20100625@Phuc: Force SQL engine using cluster index(CIX_recommend_matchid_bettype)(version on DB05/DB052). 
			Note: we deployed separated version for this sp one version on DB05/DB052(using CIX_recommend_matchid_bettype index)
			and original one for other DB. When edit this sp need to edit and re-deploy main version first then version on DB05/DB052.
	- 20110105@Lukas: Re-arrange bettype	
	- 20120426@Lukas: Get from production & exclude DB044
	- 20121018@Johnson: Merge code for checking double comm losing from production

Param's Explanation:
• @ResultString: + get from match.GoalRecord,
                 + uses nvarchar to avoid problem compare with varchar from betteam

*/
IF @@SERVERNAME IN ('DB04', 'DB042', 'DB043', 'DB044') RETURN



	Declare @modds smallmoney, @commWinRate smallmoney, @commLostRate smallmoney
	Declare @hdp smallmoney

	UPDATE dbo.bettrans with (ROWLOCK, UPDLOCK)
	SET 
		@hdp = CASE betteam
		        WHEN N'h' THEN hdp2-hdp1 
		        WHEN N'a' THEN hdp1-hdp2
		        END,
		        
		@modds = modds = CASE SUBSTRING(@ResultString, livehomescore + liveawayscore + 1, 1)
		    WHEN N'' THEN @hdp 
		    WHEN betteam THEN 1 + @hdp
		    ELSE -1 + @hdp
		END,
	
		@commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
		WHEN '0' THEN 1
		WHEN '1' THEN 0 
		ELSE 1 END,
		@commLostRate = CASE comstatus
		WHEN '0' THEN 1
		WHEN '1' THEN 2 
		ELSE 1 END,--'s','m'
		
	WinLost = CASE
		WHEN @modds >  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end)
		WHEN @modds =  0.25	THEN actual_stake + stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * 0.5
		WHEN @modds =  0	THEN actual_stake
		WHEN @modds = -0.25	THEN actual_stake * 0.5
		WHEN @modds < -0.25	THEN 0
		END,

	aWinLost = CASE
		WHEN @modds >  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -apositiontaking
		WHEN @modds =  0.25	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -apositiontaking * 0.5
		WHEN @modds =  0	THEN 0
		WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
		WHEN @modds < -0.25	THEN actual_stake * apositiontaking
		END,
	mWinLost = CASE
		WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -mpositiontaking
		WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -mpositiontaking * 0.5
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
		WHEN @modds < -0.25 	THEN actual_stake * mpositiontaking
		END,
	sWinLost = CASE
		WHEN @modds >  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -spositiontaking
		WHEN @modds =  0.25 	THEN stake * (case when odds<0 then 1 else (case when bettype in (4,5,6) then odds-1 else odds end) end) * -spositiontaking * 0.5
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -0.25 	THEN actual_stake * spositiontaking * 0.5
		WHEN @modds < -0.25 	THEN actual_stake * spositiontaking
		END,

	PlayerComm = CASE
		WHEN @modds >  0.25 	THEN @commWinRate * playerdiscount * stake
		WHEN @modds =  0.25 	THEN @commWinRate * playerdiscount * stake * 0.5
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -0.25 	THEN @commLostRate * playerdiscount * stake * 0.5
		WHEN @modds < -0.25 	THEN @commLostRate * playerdiscount * stake
		END,
	Comm = CASE
		WHEN @modds >  0.25 	THEN @commWinRate * discount * stake * (1-apositiontaking)
		WHEN @modds =  0.25 	THEN @commWinRate * discount * stake * (1-apositiontaking) * 0.5
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -0.25 	THEN @commLostRate * discount * stake * (1-apositiontaking) * 0.5
		WHEN @modds < -0.25 	THEN @commLostRate * discount * stake * (1-apositiontaking)
		END,
	aComm = CASE
		WHEN @modds >  0.25 	THEN @commWinRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))
		WHEN @modds =  0.25 	THEN @commWinRate * adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -0.25 	THEN @commLostRate * adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
		WHEN @modds < -0.25 	THEN @commLostRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))
		END,
	sComm = CASE
		WHEN @modds >  0.25 	THEN @commWinRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
		WHEN @modds =  0.25 	THEN @commWinRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
		WHEN @modds =  0    	THEN 0
		WHEN @modds = -0.25 	THEN @commLostRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
		WHEN @modds < -0.25 	THEN @commLostRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))
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
		matchid=@matchid AND
		bettype=@bettype AND
		--[status] NOT IN (N'VOID', N'REJECT')
		statusID NOT IN (101,102)






GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_22] TO [vnteam]