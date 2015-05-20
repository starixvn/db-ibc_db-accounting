
ALTER PROCEDURE [dbo].[Admin_3rdCalculate_s151_Tote]
	@programID varchar(10), --settle programid
	@raceNumber tinyint, -- settle race no 
	@EventDate smalldatetime
AS
	
	DECLARE @Horse TABLE (orid int, placing tinyint, WinOdds smallmoney, PlaceOdds smallmoney, IsSCR bit)
	DECLARE @IsPlaceRefund bit

	INSERT INTO @Horse (orid, placing, WinOdds, PlaceOdds, IsSCR)
	SELECT orid, placing, IsNull(Odds, 0), IsNull(PlaceOdds, 0), IsSCR
	FROM dbo.outright with (nolock)
	WHERE 
		ProgramID = @programID 
		AND groupmatch = CAST(@raceNumber as varchar(20))
		AND eventdate = @EventDate
		AND oddsstatus = 'closed'

	-- 20090215 : fixed the PlaceOdds which below 1.0 (Joe)
	UPDATE @Horse SET PlaceOdds = 1.0 WHERE PlaceOdds <> 0 AND PlaceOdds < 1.0
	UPDATE @Horse SET WinOdds   = 1.0 WHERE WinOdds   <> 0 AND WinOdds   < 1.0

	-- 20090219 : if Place become refund, due to not enough runner or whatever reason
	-- right now, we consider by no PlaceOdds (all zero)
	IF EXISTS(SELECT * FROM @Horse WHERE PlaceOdds > 0)
		SET @IsPlaceRefund = 0
	ELSE
		BEGIN
			SET @IsPlaceRefund = 1
			UPDATE @Horse SET PlaceOdds = 1.0
		END

	DECLARE @modds smallmoney, @odds smallmoney,
			@EffectStake money, @EffectOdds smallmoney

	-- ===============================

	UPDATE dbo.bettransm WITH (UPDLOCK, ROWLOCK)
	SET
		@odds = odds = CASE bettype
			WHEN 31 THEN h.WinOdds
			WHEN 32 THEN h.PlaceOdds
			ELSE 0
			--WHEN 33 THEN (h.WinOdds + h.PlaceOdds) / 2
				/* case
				when h.placing = 1      then (h.WinOdds + h.PlaceOdds) / 2 -- win both Win & Place
				when h.placing IN (2,3) then h.PlaceOdds/2 -- win only Place
				else 0 -- full lose
				end */
			END,
		@modds = CASE
			WHEN h.IsSCR =  1 THEN 0 -- draw (cancel)
			WHEN bettype = 31 AND @odds > 0 /*h.placing = 1*/ THEN 1 -- Win : Horse come 1st place
			WHEN bettype = 32 AND @odds > 0 /*h.placing IN (1,2,3)*/ THEN 1 -- Place : Horse come within 3rd place
			--WHEN bettype = 33 AND @odds > 0 /*h.placing IN (1,2,3)*/ THEN 1 -- Each Way : Horse come within 3rd place
			ELSE -1 -- Other Case : lose
			END,

		-- Value uses for calculate Agent Winlost & Commission
		@EffectStake = CASE
			WHEN bettype = 32 AND @IsPlaceRefund = 1 THEN 0
			--WHEN bettype = 33 AND @IsPlaceRefund = 1 THEN actual_stake / 2
			ELSE stake
			END,
		@EffectOdds = CASE
			WHEN @IsPlaceRefund = 1 AND bettype = 33 THEN h.WinOdds
			ELSE @odds
			END,

		-- Ticket result details
		hdp1 = CASE bettype WHEN 32 THEN 0 ELSE h.WinOdds   END, -- 'Place' bettype not have WinOdds value
		hdp2 = CASE bettype WHEN 31 THEN 0 ELSE h.PlaceOdds END, -- 'Win'   bettype not have PlaceOdds value
		livehomescore = CASE -- Win result : 2 = Win / 4 = Lose
			WHEN bettype = 31 AND h.placing =  1 THEN 2
			WHEN bettype = 31 AND h.placing <> 1 THEN 4
			ELSE 0 END,
		liveawayscore = CASE -- Place result : 0 = Refund
			WHEN @IsPlaceRefund = 1 THEN 0
			WHEN bettype = 32 AND h.PlaceOdds > 0 THEN 2
			WHEN bettype = 32 AND h.PlaceOdds = 0 THEN 4
			ELSE 0 END, 

	[status] = CASE
		WHEN bettype = 32 AND @IsPlaceRefund = 1 THEN N'Refund'
		WHEN @modds = 0 THEN N'VOID' -- only case to be draw :: IsSCR = 1
		--WHEN @odds  < 1 THEN N'LOSE'
		WHEN @modds > 0 THEN N'WON'
		WHEN @modds < 0 THEN N'LOSE'
		END,

	WinLost = CASE
		WHEN @modds >  0.25	THEN stake * @odds
		WHEN @modds =  0	THEN stake
		WHEN @modds < -0.25	THEN 0
		--WHEN @modds =  0.25	THEN actual_stake + stake * (@odds - 1) * 0.5
		--WHEN @modds = -0.25	THEN actual_stake * 0.5
		END,

	aWinLost = CASE
		WHEN @modds >  0.25	THEN @EffectStake * (@EffectOdds - 1) * -apositiontaking
		WHEN @modds =  0	THEN 0
		WHEN @modds < -0.25	THEN @EffectStake * apositiontaking
		--WHEN @modds =  0.25	THEN stake * (@odds - 1) * -apositiontaking * 0.5
		--WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
		END,
	mWinLost = CASE
		WHEN @modds >  0.25 	THEN @EffectStake * (@EffectOdds - 1) * -mpositiontaking
		WHEN @modds =  0    	THEN 0
		WHEN @modds < -0.25 	THEN @EffectStake * mpositiontaking
		--WHEN @modds =  0.25 	THEN stake * (@odds - 1) * -mpositiontaking * 0.5
		--WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
		END,
	sWinLost = CASE
		WHEN @modds >  0.25 	THEN @EffectStake * (@EffectOdds - 1) * -spositiontaking
		WHEN @modds =  0    	THEN 0
		WHEN @modds < -0.25 	THEN @EffectStake * spositiontaking
		--WHEN @modds =  0.25 	THEN stake * (@odds - 1) * -spositiontaking * 0.5
		--WHEN @modds = -0.25 	THEN actual_stake * spositiontaking * 0.5
		END,

	PlayerComm = CASE
		WHEN @modds >  0.25 	THEN playerdiscount * @EffectStake
		WHEN @modds =  0    	THEN 0
		WHEN @modds < -0.25 	THEN playerdiscount * @EffectStake
		--WHEN @modds =  0.25 	THEN playerdiscount * stake * 0.5
		--WHEN @modds = -0.25 	THEN playerdiscount * stake * 0.5
		END,
	Comm = CASE
		WHEN @modds >  0.25 	THEN discount * @EffectStake * (1-apositiontaking)
		WHEN @modds =  0    	THEN 0
		WHEN @modds < -0.25 	THEN discount * @EffectStake * (1-apositiontaking)
		--WHEN @modds =  0.25 	THEN discount * stake * (1-apositiontaking) * 0.5
		--WHEN @modds = -0.25 	THEN discount * stake * (1-apositiontaking) * 0.5
		END,
	aComm = CASE
		WHEN @modds >  0.25 	THEN adiscount * @EffectStake * (1-(mpositiontaking+apositiontaking))
		WHEN @modds =  0    	THEN 0
		WHEN @modds < -0.25 	THEN adiscount * @EffectStake * (1-(mpositiontaking+apositiontaking))
		--WHEN @modds =  0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
		--WHEN @modds = -0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
		END,
	sComm = CASE
		WHEN @modds >  0.25 	THEN sdiscount * @EffectStake * (1-(spositiontaking+mpositiontaking+apositiontaking))
		WHEN @modds =  0    	THEN 0
		WHEN @modds < -0.25 	THEN sdiscount * @EffectStake * (1-(spositiontaking+mpositiontaking+apositiontaking))
		--WHEN @modds =  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
		--WHEN @modds = -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
		END,

	ruben=1

	FROM @Horse h 
	WHERE
		bettransm.matchid = h.orid
		AND	bettransm.bettype IN (31, 32)
		AND bettransm.[status] NOT IN (N'VOID', N'REJECT')

	-- ===============================
	DECLARE @sumWL TABLE (	refnobm			bigint, 
							matchidbm		int, 
							commbm			money, 
							acommbm			money, 
							scommbm			money,
							awinlostbm		money,
							mwinlostbm		money,
							swinlostbm		money
						)

	INSERT INTO @sumWL ( refnobm, matchidbm, commbm, acommbm, scommbm, awinlostbm, mwinlostbm, swinlostbm)
	SELECT	refno, matchid, isnull(SUM(comm),0), isnull(SUM(acomm),0), isnull(SUM(scomm),0), isnull(SUM(awinlost),0), isnull(SUM(mwinlost),0),isnull(SUM(swinlost),0)
	FROM	bettransm  WITH (NOLOCK)
	WHERE	matchid IN (SELECT orid FROM @Horse)
			AND bettransm.bettype IN (31, 32)
			AND bettransm.[status] NOT IN (N'VOID', N'REJECT')
			AND ruben = 1
	GROUP BY refno, matchid 

	-- ===============================
	UPDATE dbo.bettrans with (UPDLOCK, ROWLOCK)
	SET
		@odds = odds = CASE bettype
			WHEN 31 THEN h.WinOdds
			WHEN 32 THEN h.PlaceOdds
			WHEN 33 THEN (h.WinOdds + h.PlaceOdds) / 2
				/* case
				when h.placing = 1      then (h.WinOdds + h.PlaceOdds) / 2 -- win both Win & Place
				when h.placing IN (2,3) then h.PlaceOdds/2 -- win only Place
				else 0 -- full lose
				end */
			END,
		@modds = modds = CASE
			WHEN h.IsSCR =  1 THEN 0 -- draw (cancel)
			WHEN bettype = 31 AND @odds > 0 /*h.placing = 1*/ THEN 1 -- Win : Horse come 1st place
			WHEN bettype = 32 AND @odds > 0 /*h.placing IN (1,2,3)*/ THEN 1 -- Place : Horse come within 3rd place
			WHEN bettype = 33 AND @odds > 0 /*h.placing IN (1,2,3)*/ THEN 1 -- Each Way : Horse come within 3rd place
			ELSE -1 -- Other Case : lose
			END,

		-- Value uses for calculate Agent Winlost & Commission
		@EffectStake = CASE
			WHEN bettype = 32 AND @IsPlaceRefund = 1 THEN 0
			WHEN bettype = 33 AND @IsPlaceRefund = 1 THEN actual_stake / 2
			ELSE actual_stake
			END,
		@EffectOdds = CASE
			WHEN @IsPlaceRefund = 1 AND bettype = 33 THEN h.WinOdds
			ELSE @odds
			END,

		-- Ticket result details
		hdp1 = CASE bettype WHEN 32 THEN 0 ELSE h.WinOdds   END, -- 'Place' bettype not have WinOdds value
		hdp2 = CASE bettype WHEN 31 THEN 0 ELSE h.PlaceOdds END, -- 'Win'   bettype not have PlaceOdds value
		livehomescore = CASE -- Win result : 2 = Win / 4 = Lose
			WHEN bettype IN (31, 33) AND h.placing =  1 THEN 2
			WHEN bettype IN (31, 33) AND h.placing <> 1 THEN 4
			ELSE 0 END,
		liveawayscore = CASE -- Place result : 0 = Refund
			WHEN @IsPlaceRefund = 1 THEN 0
			WHEN bettype IN (32, 33) AND h.PlaceOdds > 0 THEN 2
			WHEN bettype IN (32, 33) AND h.PlaceOdds = 0 THEN 4
			ELSE 0 END, 

	[status] = CASE
		WHEN bettype = 32 AND @IsPlaceRefund = 1 THEN N'Refund'
		WHEN @modds = 0 THEN N'VOID' -- only case to be draw :: IsSCR = 1
		--WHEN @odds  < 1 THEN N'LOSE'
		WHEN @modds > 0 THEN N'WON'
		WHEN @modds < 0 THEN N'LOSE'
		END,

	WinLost = CASE
		WHEN @modds >  0.25	THEN actual_stake * @odds
		WHEN @modds =  0	THEN actual_stake
		WHEN @modds < -0.25	THEN 0
		--WHEN @modds =  0.25	THEN actual_stake + stake * (@odds - 1) * 0.5
		--WHEN @modds = -0.25	THEN actual_stake * 0.5
		END,

	aWinLost = CASE
		WHEN @modds >  0.25	THEN (CASE WHEN bettype = 33 THEN s.awinlostbm ELSE @EffectStake * (@EffectOdds - 1) * -apositiontaking END)
		WHEN @modds =  0	THEN 0
		WHEN @modds < -0.25	THEN (CASE WHEN bettype = 33 THEN s.awinlostbm ELSE @EffectStake * apositiontaking END)
		--WHEN @modds =  0.25	THEN stake * (@odds - 1) * -apositiontaking * 0.5
		--WHEN @modds = -0.25	THEN actual_stake * apositiontaking * 0.5
		END,
	mWinLost = CASE
		WHEN @modds >  0.25 	THEN (CASE WHEN bettype = 33 THEN s.mwinlostbm ELSE @EffectStake * (@EffectOdds - 1) * -mpositiontaking END)
		WHEN @modds =  0    	THEN 0
		WHEN @modds < -0.25 	THEN (CASE WHEN bettype = 33 THEN s.mwinlostbm ELSE @EffectStake * mpositiontaking END)
		--WHEN @modds =  0.25 	THEN stake * (@odds - 1) * -mpositiontaking * 0.5
		--WHEN @modds = -0.25 	THEN actual_stake * mpositiontaking * 0.5
		END,
	sWinLost = CASE
		WHEN @modds >  0.25 	THEN (CASE WHEN bettype = 33 THEN s.swinlostbm ELSE @EffectStake * (@EffectOdds - 1) * -spositiontaking END)
		WHEN @modds =  0    	THEN 0
		WHEN @modds < -0.25 	THEN (CASE WHEN bettype = 33 THEN s.swinlostbm ELSE @EffectStake * spositiontaking END)
		--WHEN @modds =  0.25 	THEN stake * (@odds - 1) * -spositiontaking * 0.5
		--WHEN @modds = -0.25 	THEN actual_stake * spositiontaking * 0.5
		END,

	PlayerComm = CASE
		WHEN @modds >  0.25 	THEN playerdiscount * @EffectStake
		WHEN @modds =  0    	THEN 0
		WHEN @modds < -0.25 	THEN playerdiscount * @EffectStake
		--WHEN @modds =  0.25 	THEN playerdiscount * stake * 0.5
		--WHEN @modds = -0.25 	THEN playerdiscount * stake * 0.5
		END,
	Comm = CASE
		WHEN @modds >  0.25 	THEN (CASE WHEN bettype = 33 THEN s.commbm ELSE discount * @EffectStake * (1-apositiontaking) END)
		WHEN @modds =  0    	THEN 0
		WHEN @modds < -0.25 	THEN (CASE WHEN bettype = 33 THEN s.commbm ELSE discount * @EffectStake * (1-apositiontaking)END)
		--WHEN @modds =  0.25 	THEN discount * stake * (1-apositiontaking) * 0.5
		--WHEN @modds = -0.25 	THEN discount * stake * (1-apositiontaking) * 0.5
		END,
	aComm = CASE
		WHEN @modds >  0.25 	THEN (CASE WHEN bettype = 33 THEN s.acommbm ELSE adiscount * @EffectStake * (1-(mpositiontaking+apositiontaking))END)
		WHEN @modds =  0    	THEN 0
		WHEN @modds < -0.25 	THEN (CASE WHEN bettype = 33 THEN s.acommbm ELSE adiscount * @EffectStake * (1-(mpositiontaking+apositiontaking))END)
		--WHEN @modds =  0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
		--WHEN @modds = -0.25 	THEN adiscount * stake * (1-(mpositiontaking+apositiontaking)) * 0.5
		END,
	sComm = CASE
		WHEN @modds >  0.25 	THEN (CASE WHEN bettype = 33 THEN s.scommbm ELSE sdiscount * @EffectStake * (1-(spositiontaking+mpositiontaking+apositiontaking))END)
		WHEN @modds =  0    	THEN 0
		WHEN @modds < -0.25 	THEN (CASE WHEN bettype = 33 THEN s.scommbm ELSE sdiscount * @EffectStake * (1-(spositiontaking+mpositiontaking+apositiontaking))END)
		--WHEN @modds =  0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
		--WHEN @modds = -0.25 	THEN sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking)) * 0.5
		END,

	ruben=1

	FROM	bettrans 
			INNER JOIN @Horse h ON bettrans.matchid = h.orid
			LEFT JOIN @sumWL s ON bettrans.transid = s.refnobm 
	WHERE	bettrans.bettype IN (31, 32, 33)
			AND bettrans.[status] NOT IN (N'VOID', N'REJECT')

GO
GRANT VIEW DEFINITION ON [dbo].[Admin_3rdCalculate_s151] TO [vnteam]