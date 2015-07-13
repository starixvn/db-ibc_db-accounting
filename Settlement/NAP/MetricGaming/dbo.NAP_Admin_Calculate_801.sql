ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_801]
	@matchid		INT,
	@bettype		INT,
	@bettypeTime	VARCHAR(100)='',
	@Action			VARCHAR(50) ='CAL',
	@ResultID		INT,
	@Result			VARCHAR(4000),
	@isSettleDetermined BIT =0
AS
	/*
		Created: Johnson
		Date: 2015-07-03
		Task: Main sp calculate for Metric Gaming
			NOTE: this sp doesn't need to inclucde execrep coz consistent transid on bettrans
		DB: DBTXN/bodb02
		
		Revisions:
		
		Parameter's Explanation:
			- @Result = <Result>
							<Row GameResult='7' OtherInfo='6:10'></Row>
							<Row GameResult='8' OtherInfo='6:20'></Row>
						</Result>: Every Single Minute
			-@Result = <Result>
							<Row GameResult='15'></Row>									
						</Result>: NONE
			-@Result = <Result>
							<Row GameResult='9' OtherInfo='62'></Row>
						</Result>: Time of Posession
	*/ 
BEGIN
	SET NOCOUNT ON 
	IF @Action = 'CAL'
	BEGIN
		DECLARE @tmpResult TABLE (
			GameResult TINYINT,
			OtherInfo VARCHAR(50)
		)		
		
		CREATE TABLE #tmpTrans (refno BIGINT)
		
		DECLARE @DocHandler INT,
				@GameResult	VARCHAR(100) = '',
				@OtherInfo	VARCHAR(100) = '',
				@StatusID	INT,
				@commWinRate SMALLMONEY,
				@commLostRate SMALLMONEY
		
		-- For read xml     
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @Result		
		
		INSERT INTO @tmpResult 
		SELECT Data.GameResult,
			Data.OtherInfo
		FROM OPENXML (@DocHandler, '/Result/Row',1)
		WITH(
			GameResult INT,
			OtherInfo	VARCHAR(50)
		) as Data
		
		EXEC sp_xml_removedocument @DocHandler
		-- end read xml
		
		IF @bettype IN (801,803,804,806)
		BEGIN
			UPDATE translog WITH(UPDLOCK,ROWLOCK)
			SET @Statusid = statusid = CASE WHEN SUBSTRING(transdesc,11,CHARINDEX(';bettypetime',transdesc)-11) IN (SELECT GameResult FROM @tmpResult) THEN 112
											ELSE 113 END,				
				status = CASE WHEN @StatusID = 112 THEN 'WON' ELSE 'LOSE' END,
				custom3 = @ResultID				
			WHERE GameID = @bettype
				AND EventID = @matchid
				AND SUBSTRING(transdesc,CHARINDEX('bettypetime',transdesc)+12,CHARINDEX(';time',transdesc)-CHARINDEX('bettypetime',transdesc)-12) = @bettypeTime
				AND StatusID NOT IN ('VOID','REJECT')
			OUTPUT INSERTED.translogid
			INTO #tmpTrans
			
			--update existing tickets on bettrans
			UPDATE bettrans WITH(UPDLOCK,ROWLOCK)
			SET @Statusid = statusid = CASE WHEN SUBSTRING(transdesc,11,CHARINDEX(';bettypetime',transdesc)-11) IN (SELECT GameResult FROM @tmpResult) THEN 112
											ELSE 113 END,
				status = CASE WHEN @StatusID = 112 THEN 'WON' ELSE 'LOSE' END,							
				@commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
					WHEN '0' THEN 1
					WHEN '1' THEN 0 
					ELSE 1 END,
				@commLostRate = CASE comstatus
					WHEN '0' THEN 1
					WHEN '1' THEN 2 
					ELSE 1 END,
				WinLost = CASE
					WHEN @Statusid = 112 THEN actual_stake + stake * (case when odds<0 then 1 else odds end)
					WHEN @Statusid =  113 THEN 0 
					END,
				aWinLost = CASE
					WHEN @Statusid = 112 THEN stake * (case when odds<0 then 1 else odds end)* -apositiontaking
					WHEN @Statusid =  113 THEN actual_stake * apositiontaking 
					END,
				mWinLost = CASE	
					WHEN @Statusid = 112 THEN stake * (case when odds<0 then 1 else odds end)* -mpositiontaking
					WHEN @Statusid =  113 THEN actual_stake * mpositiontaking 
					END,
				sWinLost = CASE	
					WHEN @Statusid = 112 THEN stake * (case when odds<0 then 1 else odds end)* -spositiontaking
					WHEN @Statusid =  113 THEN actual_stake * spositiontaking 
					END,
				PlayerComm = CASE
					WHEN @Statusid = 112 	THEN @commWinRate * playerdiscount * stake		
					WHEN @Statusid = 113 	THEN @commLostRate * playerdiscount * stake					
					END,
				Comm = CASE
					WHEN @Statusid = 112 	THEN @commWinRate * discount * stake * (1-apositiontaking)		
					WHEN @Statusid = 113 	THEN @commLostRate * discount * stake * (1-apositiontaking)						
					END,
				aComm = CASE
					WHEN @Statusid = 112 	THEN @commWinRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))		
					WHEN @Statusid = 113 	THEN @commLostRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))						
					END,
				sComm = CASE
					WHEN @Statusid = 112 	THEN @commWinRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))		
					WHEN @Statusid = 113 	THEN @commLostRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))						
					END,
				ruben = 1		
			WHERE matchid = @matchid
				AND bettype = @bettype
				AND refno IN (SELECT refno FROM #tmpTrans)
			
			--insert tickets into bettrans if not exist
			INSERT INTO [dbo].[bettrans]
				   ([custid]
				   ,[transdate]
				   ,[oddsid]
				   ,[hdp1]
				   ,[hdp2]
				   ,[odds]
				   ,[stake]
				   ,[status]
				   ,[winlost]
				   ,[awinlost]
				   ,[mwinlost]
				   ,[playercomm]
				   ,[comm]
				   ,[acomm]
				   ,[apositiontaking]
				   ,[mpositiontaking]
				   ,[tpositiontaking]
				   ,[playerdiscount]
				   ,[discount]
				   ,[adiscount]
				   ,[livehomescore]
				   ,[liveawayscore]
				   ,[liveindicator]
				   ,[betteam]
				   ,[creator]
				   ,[refno]
				   ,[comstatus]
				   ,[winlostdate]
				   ,[betfrom]
				   ,[betcheck]
				   ,[checktime]
				   ,[oddsspread]
				   ,[actualrate]
				   ,[matchid]
				   ,[recommend]
				   ,[mrecommend]
				   ,[ruben]
				   ,[betid]
				   ,[statuswinlost]
				   ,[modds]
				   ,[bettype]				   
				   ,[actual_stake]
				   ,[currency]
				   ,[ip]
				   ,[transdesc]
				   ,[sdiscount]
				   ,[scomm]
				   ,[spositiontaking]
				   ,[swinlost]
				   ,[srecommend]
				   ,[Username]
				   ,[CurrencyName]
				   ,[virtualrate]
				   ,[oddstype]
				   ,[statusID]
				   ,[currency2]
				   ,[balance]
				   ,[SecAcceptFlag]
				   ,[transid2]
				   ,[RecommDate])
			SELECT custid
				,transdate
				,0 as oddsid
				,0 as hdp1
				,0 as hdp2
				,odds
				,stake
				,[status]
			   ,CASE 
					WHEN Statusid = 112 THEN actual_stake + stake * (case when odds<0 then 1 else odds end)
					WHEN Statusid =  113 THEN 0 END [winlost]
			   ,CASE 
					WHEN Statusid = 112 THEN stake * (case when odds<0 then 1 else odds end)* -mpositiontaking
					WHEN Statusid =  113 THEN actual_stake * mpositiontaking 
					END [awinlost]
			   ,CASE 
					WHEN Statusid = 112 THEN stake * (case when odds<0 then 1 else odds end)* -mpositiontaking
					WHEN Statusid =  113 THEN actual_stake * mpositiontaking 
					END [mwinlost]
			   ,CASE 
					WHEN Statusid = 112 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 0 
												ELSE 1 END) * playerdiscount * stake		
					WHEN Statusid = 113 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 2 
												ELSE 1 END) * playerdiscount * stake					
					END [playercomm]
			   ,CASE 
					WHEN Statusid = 112 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 0 
												ELSE 1 END) * discount * stake * (1-apositiontaking)		
					WHEN Statusid = 113 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 2 
												ELSE 1 END) * discount * stake * (1-apositiontaking)						
					END [comm]
			   ,CASE
					WHEN Statusid = 112 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 0 
												ELSE 1 END) * adiscount * stake * (1-(mpositiontaking+apositiontaking))		
					WHEN Statusid = 113 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 2 
												ELSE 1 END) * adiscount * stake * (1-(mpositiontaking+apositiontaking))						
					END[acomm]
			   ,[apositiontaking]
			   ,[mpositiontaking]
			   ,[tpositiontaking]
			   ,[playerdiscount]
			   ,[discount]
			   ,[adiscount]
			   ,0 as [livehomescore]
			   ,0 as [liveawayscore]
			   ,[liveindicator]
			   ,SUBSTRING(transdesc,11,CHARINDEX(';bettypetime',transdesc)-11) [betteam]
			   ,[creator]
			   ,translogid as [refno]
			   ,custom2 as [comstatus]
			   ,[winlostdate]
			   ,[betfrom]
			   ,'0' as [betcheck]
			   ,NULL as [checktime]
			   ,0 as [oddsspread]
			   ,[actualrate]
			   ,EventID as [matchid]
			   ,[recommend]
			   ,[mrecommend]
			   ,1 as [ruben]
			   ,custom3 as [betid]
			   ,NULL as [statuswinlost]
			   ,1 as [modds]
			   ,gameID as [bettype]			   
			   ,[actual_stake]
			   ,[currency]
			   ,[ip]
			   ,[transdesc]
			   ,[sdiscount]
			   ,CASE
					WHEN Statusid = 112 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 0 
												ELSE 1 END) * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))		
					WHEN Statusid = 113 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 2 
												ELSE 1 END) * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))						
					END [scomm]
			   ,[spositiontaking]
			   ,CASE	
					WHEN Statusid = 112 THEN stake * (case when odds<0 then 1 else odds end)* -spositiontaking
					WHEN Statusid =  113 THEN actual_stake * spositiontaking 
					END [swinlost]
			   ,[srecommend]
			   ,[Username]
			   ,[CurrencyName]
			   ,[virtualrate]
			   ,custom1 as [oddstype]
			   ,[statusID]
			   ,NULL as [currency2]
			   ,[balance]
			   ,0 as [SecAcceptFlag]
			   ,0 as [transid2]
			   ,NULL as [RecommDate]
			FROM translog WITH(NOLOCK)
			WHERE translogid IN (SELECT t.refno 
								FROM #tmpTrans t
									LEFT JOIN bettrans b(NOLOCK) ON t.refno = b.refno								
								WHERE matchid = @matchid
									AND bettype = @bettype
									AND b.refno IS NULL
							)
		END
		ELSE IF @bettype = 805
		BEGIN
			UPDATE translog WITH(UPDLOCK,ROWLOCK)
			SET @Statusid = statusid = CASE WHEN SUBSTRING(transdesc,11,CHARINDEX(';bettypetime',transdesc)-11) IN (SELECT GameResult FROM @tmpResult) THEN 112
											WHEN EXISTS(SELECT 1 FROM @tmpResult WHERE GameResult = 14) THEN 111--DRAW
											ELSE 113 END,				
				status = CASE WHEN @StatusID = 112 THEN 'WON' 
								WHEN @StatusID = 113 THEN 'LOSE'
								ELSE 'DRAW' END,
				custom3 = @ResultID				
			WHERE GameID = @bettype
				AND EventID = @matchid
				AND SUBSTRING(transdesc,CHARINDEX('bettypetime',transdesc)+12,CHARINDEX(';time',transdesc)-CHARINDEX('bettypetime',transdesc)-12) = @bettypeTime
				AND StatusID NOT IN ('VOID','REJECT')
			OUTPUT INSERTED.translogid
			INTO #tmpTrans
			
			--update existing tickets on bettrans
			UPDATE bettrans WITH(UPDLOCK,ROWLOCK)
			SET @Statusid = statusid = CASE WHEN SUBSTRING(transdesc,11,CHARINDEX(';bettypetime',transdesc)-11) IN (SELECT GameResult FROM @tmpResult) THEN 112
											WHEN EXISTS(SELECT 1 FROM @tmpResult WHERe GameResult = 14) THEN 111
											ELSE 113 END,
				status = CASE WHEN @StatusID = 112 THEN 'WON' 
							WHEN @sttatusID = 113 ELSE 'LOSE' 
							ELSE 'DRAW' END,							
				@commWinRate = CASE comstatus -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
					WHEN '0' THEN 1
					WHEN '1' THEN 0 
					ELSE 1 END,
				@commLostRate = CASE comstatus
					WHEN '0' THEN 1
					WHEN '1' THEN 2 
					ELSE 1 END,
				WinLost = CASE
					WHEN @Statusid = 112 THEN actual_stake + stake * (case when odds<0 then 1 else odds end)
					WHEN @statusID = 111 THEN actual_stake
					WHEN @Statusid =  113 THEN 0 
					END,
				aWinLost = CASE
					WHEN @Statusid = 112 THEN stake * (case when odds<0 then 1 else odds end)* -apositiontaking
					WHEN @StatusID = 111 THEN 0
					WHEN @Statusid =  113 THEN actual_stake * apositiontaking 
					END,
				mWinLost = CASE	
					WHEN @Statusid = 112 THEN stake * (case when odds<0 then 1 else odds end)* -mpositiontaking
					WHEN @StatusID = 111 THEN 0
					WHEN @Statusid =  113 THEN actual_stake * mpositiontaking 
					END,
				sWinLost = CASE	
					WHEN @Statusid = 112 THEN stake * (case when odds<0 then 1 else odds end)* -spositiontaking
					WHEN @StatusID = 111 THEN 0
					WHEN @Statusid =  113 THEN actual_stake * spositiontaking 
					END,
				PlayerComm = CASE
					WHEN @Statusid = 112 	THEN @commWinRate * playerdiscount * stake		
					WHEN @StatusID = 111	THEN 0
					WHEN @Statusid = 113 	THEN @commLostRate * playerdiscount * stake					
					END,
				Comm = CASE
					WHEN @Statusid = 112 	THEN @commWinRate * discount * stake * (1-apositiontaking)		
					WHEN @StatusID = 111	THEN 0
					WHEN @Statusid = 113 	THEN @commLostRate * discount * stake * (1-apositiontaking)						
					END,
				aComm = CASE
					WHEN @Statusid = 112 	THEN @commWinRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))		
					WHEN @StatusID = 111	THEN 0
					WHEN @Statusid = 113 	THEN @commLostRate * adiscount * stake * (1-(mpositiontaking+apositiontaking))						
					END,
				sComm = CASE
					WHEN @Statusid = 112 	THEN @commWinRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))		
					WHEN @StatusID = 111	THEN 0
					WHEN @Statusid = 113 	THEN @commLostRate * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))						
					END,
				ruben = 1		
			WHERE matchid = @matchid
				AND bettype = @bettype
				AND refno IN (SELECT refno FROM #tmpTrans)
			
			--insert tickets into bettrans if not exist
			INSERT INTO [dbo].[bettrans]
				   ([custid]
				   ,[transdate]
				   ,[oddsid]
				   ,[hdp1]
				   ,[hdp2]
				   ,[odds]
				   ,[stake]
				   ,[status]
				   ,[winlost]
				   ,[awinlost]
				   ,[mwinlost]
				   ,[playercomm]
				   ,[comm]
				   ,[acomm]
				   ,[apositiontaking]
				   ,[mpositiontaking]
				   ,[tpositiontaking]
				   ,[playerdiscount]
				   ,[discount]
				   ,[adiscount]
				   ,[livehomescore]
				   ,[liveawayscore]
				   ,[liveindicator]
				   ,[betteam]
				   ,[creator]
				   ,[refno]
				   ,[comstatus]
				   ,[winlostdate]
				   ,[betfrom]
				   ,[betcheck]
				   ,[checktime]
				   ,[oddsspread]
				   ,[actualrate]
				   ,[matchid]
				   ,[recommend]
				   ,[mrecommend]
				   ,[ruben]
				   ,[betid]
				   ,[statuswinlost]
				   ,[modds]
				   ,[bettype]				   
				   ,[actual_stake]
				   ,[currency]
				   ,[ip]
				   ,[transdesc]
				   ,[sdiscount]
				   ,[scomm]
				   ,[spositiontaking]
				   ,[swinlost]
				   ,[srecommend]
				   ,[Username]
				   ,[CurrencyName]
				   ,[virtualrate]
				   ,[oddstype]
				   ,[statusID]
				   ,[currency2]
				   ,[balance]
				   ,[SecAcceptFlag]
				   ,[transid2]
				   ,[RecommDate])
			SELECT custid
				,transdate
				,0 as oddsid
				,0 as hdp1
				,0 as hdp2
				,odds
				,stake
				,[status]
			   ,CASE 
					WHEN Statusid = 112 THEN actual_stake + stake * (case when odds<0 then 1 else odds end)
					WHEN StatusID = 111 THEN actual_stake
					WHEN Statusid =  113 THEN 0 END [winlost]
			   ,CASE 
					WHEN Statusid = 112 THEN stake * (case when odds<0 then 1 else odds end)* -mpositiontaking
					WHEN StatusID = 111 THEN 0
					WHEN Statusid =  113 THEN actual_stake * mpositiontaking 
					END [awinlost]
			   ,CASE 
					WHEN Statusid = 112 THEN stake * (case when odds<0 then 1 else odds end)* -mpositiontaking
					WHEN StatusID = 111 THEN 0
					WHEN Statusid =  113 THEN actual_stake * mpositiontaking 
					END [mwinlost]
			   ,CASE 
					WHEN Statusid = 112 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 0 
												ELSE 1 END) * playerdiscount * stake		
					WHEN Statusid = 111 THEN 0							
					WHEN Statusid = 113 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 2 
												ELSE 1 END) * playerdiscount * stake					
					END [playercomm]
			   ,CASE 
					WHEN Statusid = 112 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 0 
												ELSE 1 END) * discount * stake * (1-apositiontaking)		
					WHEN Statusid = 111 THEN 0												
					WHEN Statusid = 113 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 2 
												ELSE 1 END) * discount * stake * (1-apositiontaking)						
					END [comm]
			   ,CASE
					WHEN Statusid = 112 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 0 
												ELSE 1 END) * adiscount * stake * (1-(mpositiontaking+apositiontaking))		
					WHEN Statusid = 111 THEN 0												
					WHEN Statusid = 113 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 2 
												ELSE 1 END) * adiscount * stake * (1-(mpositiontaking+apositiontaking))						
					END[acomm]
			   ,[apositiontaking]
			   ,[mpositiontaking]
			   ,[tpositiontaking]
			   ,[playerdiscount]
			   ,[discount]
			   ,[adiscount]
			   ,0 as [livehomescore]
			   ,0 as [liveawayscore]
			   ,[liveindicator]
			   ,SUBSTRING(transdesc,11,CHARINDEX(';bettypetime',transdesc)-11) [betteam]
			   ,[creator]
			   ,translogid as [refno]
			   ,custom2 as [comstatus]
			   ,[winlostdate]
			   ,[betfrom]
			   ,'0' as [betcheck]
			   ,NULL as [checktime]
			   ,0 as [oddsspread]
			   ,[actualrate]
			   ,EventID as [matchid]
			   ,[recommend]
			   ,[mrecommend]
			   ,1 as [ruben]
			   ,custom3 as [betid]
			   ,NULL as [statuswinlost]
			   ,1 as [modds]
			   ,gameID as [bettype]			   
			   ,[actual_stake]
			   ,[currency]
			   ,[ip]
			   ,[transdesc]
			   ,[sdiscount]
			   ,CASE
					WHEN Statusid = 112 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 0 
												ELSE 1 END) * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))		
					WHEN Statusid = 111 THEN 0												
					WHEN Statusid = 113 THEN (CASE custom2
												WHEN '0' THEN 1
												WHEN '1' THEN 2 
												ELSE 1 END) * sdiscount * stake * (1-(spositiontaking+mpositiontaking+apositiontaking))						
					END [scomm]
			   ,[spositiontaking]
			   ,CASE	
					WHEN Statusid = 112 THEN stake * (case when odds<0 then 1 else odds end)* -spositiontaking
					WHEN Statusid = 111 THEN 0
					WHEN Statusid =  113 THEN actual_stake * spositiontaking 
					END [swinlost]
			   ,[srecommend]
			   ,[Username]
			   ,[CurrencyName]
			   ,[virtualrate]
			   ,custom1 as [oddstype]
			   ,[statusID]
			   ,NULL as [currency2]
			   ,[balance]
			   ,0 as [SecAcceptFlag]
			   ,0 as [transid2]
			   ,NULL as [RecommDate]
			FROM translog WITH(NOLOCK)
			WHERE translogid IN (SELECT t.refno 
								FROM #tmpTrans t
									LEFT JOIN bettrans b(NOLOCK) ON t.refno = b.refno								
								WHERE matchid = @matchid
									AND bettype = @bettype
									AND b.refno IS NULL
							)
		END
			
	END
	IF @Action = 'Refund'
	BEGIN
		
	END
	IF @Action = 'Undo'
	BEGIN
		
	END
	
END
GO