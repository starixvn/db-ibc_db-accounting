USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Admin_Calculate_801]    Script Date: 07/17/2015 08:53:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_801]
	@matchid				INT,
	@bettype				INT,
	@bettypeTime			VARCHAR(100)	= '',
	@SuspendedTime			TINYINT			= 0,
	@Action					VARCHAR(50)		= 'CAL',
	@ResultID				INT,
	@Result					VARCHAR(4000),
	@isSettleDetermined		BIT				= 0
AS
	/*
		Created: Johnson
		Date: 2015-07-03
		Task: Main sp calculate for Metric Gaming
			NOTE: this sp doesn't need to inclucde execrep coz consistent transid on bettrans
		DB: DBTXN/bodb02
		
		Revisions:
		
		Parameter's Explanation:
		* @Result = <Result>
						<Row GameResult="7" OtherInfo="6:10"/>
						<Row GameResult="8" OtherInfo="6:20"/>
					</Result>: Every Single Minute
		  @Result = <Result>
						<Row GameResult="15"/>
					</Result>: NONE
		  @Result = <Result>
						<Row GameResult="9" OtherInfo="62"/>
					</Result>: Time of Posession
					
		* @SuspendedTime: For bettype 806 (first goal) only.It has value when result is No Goal
				- 11: match is suspended in 0-19 min
				- 12: match is suspended in 20-45+ min
				- 13: match is suspended in 2nd half
								
	*/ 
BEGIN
	SET NOCOUNT ON 

	DECLARE @tmpResult TABLE (
			GameResult	TINYINT,
			OtherInfo	VARCHAR(50)
		)		
	
	DECLARE @GameResult		VARCHAR(100) = ''
			,@OtherInfo		VARCHAR(100) = ''
			,@StatusID		TINYINT
			,@commWinRate	SMALLMONEY
			,@commLostRate	SMALLMONEY
			,@xml			XML
	
	SELECT @xml = CONVERT(XML, @Result)
	
	INSERT INTO @tmpResult 
	SELECT	t.c.value('@GameResult','TINYINT')		AS GameResult
			,t.c.value('@OtherInfo', 'VARCHAR(50)') AS OtherInfo
	FROM	@xml.nodes('Result/Row') t( c )	
	
	IF @Action = 'CAL'
	BEGIN
		CREATE TABLE #tmpTrans (refno BIGINT)	
		
		IF @bettype IN (801,803,804,805)
		BEGIN
			UPDATE translog WITH(UPDLOCK,ROWLOCK)
			SET @Statusid = statusid = CASE WHEN SUBSTRING(transdesc,11,CHARINDEX(';bettypetime',transdesc)-11) IN (SELECT GameResult FROM @tmpResult) THEN 112
											WHEN EXISTS(SELECT 1 FROM @tmpResult WHERE GameResult = 14) AND @bettype = 805 THEN 111--DRAW
											ELSE 113 END,				
				status = CASE WHEN @StatusID = 112 THEN 'WON' 
								WHEN @StatusID = 113 THEN 'LOSE'
								ELSE 'DRAW' END,
				custom3 = @ResultID				
			OUTPUT INSERTED.translogid
			INTO #tmpTrans
			WHERE GameID = @bettype
				AND EventID = @matchid
				AND SUBSTRING(transdesc,CHARINDEX('bettypetime',transdesc)+12,CHARINDEX(';time',transdesc)-CHARINDEX('bettypetime',transdesc)-12) = @bettypeTime
				AND StatusID NOT IN (101,102)--('VOID','REJECT')
			
			--update existing tickets on bettrans
			UPDATE bettrans WITH(UPDLOCK,ROWLOCK)
			SET @Statusid = statusid = CASE WHEN SUBSTRING(transdesc,11,CHARINDEX(';bettypetime',transdesc)-11) IN (SELECT GameResult FROM @tmpResult) THEN 112
											WHEN EXISTS(SELECT 1 FROM @tmpResult WHERe GameResult = 14) THEN 111
											ELSE 113 END,
				status = CASE WHEN @StatusID = 112 THEN 'WON' 
							WHEN @statusID = 113 THEN 'LOSE' 
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
		IF @bettype = 806
		BEGIN
			UPDATE translog WITH(UPDLOCK,ROWLOCK)
			SET @Statusid = statusid = CASE WHEN SUBSTRING(transdesc,11,CHARINDEX(';bettypetime',transdesc)-11) IN (SELECT GameResult FROM @tmpResult) THEN 112
											ELSE 113 END,				
				status = CASE WHEN @StatusID = 112 THEN 'WON' ELSE 'LOSE' END,
				custom3 = @ResultID				
			OUTPUT INSERTED.translogid
			INTO #tmpTrans
			WHERE GameID = @bettype
				AND EventID = @matchid				
				AND StatusID NOT IN (101,102)--('VOID','REJECT')
			
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
		
			
	END
	ELSE IF @Action = 'REFUND'
	BEGIN		
		CREATE TABLE #tmpSettledTicket (
			translogid				BIGINT
			,transdate				DATETIME
			,odds					SMALLMONEY
			,stake					MONEY
			,status					NVARCHAR(10)
			,statusID				TINYINT
			,actual_stake			MONEY
			,custom2				VARCHAR(50)
			,playerdiscount			DECIMAL(9,8)
			,discount				DECIMAL(9,8)
			,adiscount				DECIMAL(9,8)
			,apositiontaking 		SMALLMONEY
			,mpositiontaking 		SMALLMONEY
			,spositiontaking 		SMALLMONEY
			,tpositiontaking 		SMALLMONEY
			,liveindicator			BIT
			,creator				INT
			,transdesc				NVARCHAR(300)
			,winlostdate			SMALLDATETIME
			,betfrom				NVARCHAR(1)
			,actualrate				FLOAT
			,eventID				INT
			,recommend				INT
			,mrecommend				INT
			,srecommend				INT
			,custid					INT
			,custom3				VARCHAR(50)
			,gameID					INT
			,currency				TINYINT
			,CurrencyName			NVARCHAR(50)
			,ip						NVARCHAR(15)
			,sdiscount				DECIMAL(9,8)
			,username				NVARCHAR(50)
			,virtualrate			FLOAT
			,custom1				VARCHAR(50)
			,balance				MONEY
		)
		CREATE TABLE #tmpRefundedTicket (
			translogid				BIGINT
			,transdate				DATETIME
			,odds					SMALLMONEY
			,stake					MONEY
			,status					NVARCHAR(10)
			,statusID				TINYINT
			,actual_stake			MONEY
			,custom2				VARCHAR(50)
			,playerdiscount			DECIMAL(9,8)
			,discount				DECIMAL(9,8)
			,adiscount				DECIMAL(9,8)
			,apositiontaking		SMALLMONEY
			,mpositiontaking		SMALLMONEY
			,spositiontaking		SMALLMONEY
			,tpositiontaking		SMALLMONEY
			,liveindicator			BIT
			,creator				INT
			,transdesc				NVARCHAR(300)
			,winlostdate			SMALLDATETIME
			,betfrom				NVARCHAR(1)
			,actualrate				FLOAT
			,eventID				INT
			,recommend				INT
			,mrecommend				INT
			,srecommend				INT
			,custid					INT
			,custom3				VARCHAR(50)
			,gameID					INT
			,currency				TINYINT
			,CurrencyName			NVARCHAR(50)
			,ip						NVARCHAR(15)
			,sdiscount				DECIMAL(9,8)
			,username				NVARCHAR(50)
			,virtualrate			FLOAT
			,custom1				VARCHAR(50)
			,balance				MONEY
		)
		IF @isSettleDetermined = 1 AND @Bettype = 806
		BEGIN
			-- update translog
			UPDATE 	dbo.translog WITH(UPDLOCK, ROWLOCK)
			SET 	@StatusId = StatusId = CASE WHEN SUBSTRING(transdesc,11,CHARINDEX(';bettypetime',transdesc)-11) IN (SELECT GameResult FROM @tmpResult WHERE GameResult <> 2) THEN 112
												ELSE 113
											END
					,Status = CASE WHEN @StatusId = 112 THEN 'WON' 
									ELSE 'LOSE' 
							  END
			OUTPUT 	INSERTED.translogid
					,INSERTED.transdate
					,INSERTED.odds
					,INSERTED.stake
					,INSERTED.status
					,INSERTED.statusID
					,INSERTED.actual_stake
					,INSERTED.custom2
					,INSERTED.playerdiscount
					,INSERTED.discount
					,INSERTED.adiscount
					,INSERTED.apositiontaking
					,INSERTED.mpositiontaking
					,INSERTED.spositiontaking
					,INSERTED.tpositiontaking
					,INSERTED.liveindicator
					,INSERTED.creator
					,INSERTED.transdesc
					,INSERTED.winlostdate
					,INSERTED.betfrom
					,INSERTED.actualrate
					,INSERTED.eventID
					,INSERTED.recommend
					,INSERTED.mrecommend
					,INSERTED.srecommend
					,INSERTED.custid
					,INSERTED.custom3
					,INSERTED.gameID
					,INSERTED.currency
					,INSERTED.CurrencyName
					,INSERTED.ip
					,INSERTED.sdiscount
					,INSERTED.username
					,INSERTED.virtualrate
					,INSERTED.custom1
					,INSERTED.balance
			INTO 	#tmpSettledTicket								
			WHERE	GameId 	= @Bettype
					AND EventId = @MatchId
					AND StatusId NOT IN (101, 102) -- Reject, Void
					AND 1 = CASE WHEN EXISTS (SELECT GameResult FROM @tmpResult WHERE GameResult = 2) AND @SuspendedTime >= SUBSTRING(transdesc,11,CHARINDEX(';bettypetime',transdesc)-11)  THEN 0
								 ELSE 1
							END	
			
			-- update & insert tickets in bettrans	
			MERGE	dbo.bettrans b 
			USING	(SELECT	  translogid
							  ,transdate
							  ,odds
							  ,stake
							  ,status
							  ,statusID
							  ,actual_stake
							  ,custom2
							  ,playerdiscount
							  ,discount
							  ,adiscount
							  ,apositiontaking
							  ,mpositiontaking
							  ,spositiontaking
							  ,tpositiontaking
							  ,liveindicator
							  ,creator
							  ,transdesc
							  ,winlostdate
							  ,betfrom
							  ,actualrate
							  ,eventID
							  ,recommend
							  ,mrecommend
							  ,srecommend
							  ,custid
							  ,custom3
							  ,gameID
							  ,currency
							  ,CurrencyName
							  ,ip
							  ,sdiscount	
							  ,username	
							  ,virtualrate
							  ,custom1	
							  ,balance
					FROM #tmpSettledTicket)	AS t
			ON	b.refno = t.translogid
			WHEN MATCHED THEN UPDATE SET	b.status	= t.status
											,b.statusID	= t.statusId
											,@commWinRate = CASE 
																WHEN b.comstatus = '0' THEN 1
																WHEN b.comstatus = '1' THEN 0
																ELSE 1
															END
											,@commLostRate = CASE 
																WHEN b.comstatus = '0' THEN 1
																WHEN b.comstatus = '1' THEN 2
																ELSE 1
															END
											,b.winlost	= CASE	
																WHEN t.statusID = 112 THEN b.actual_stake + b.stake * (CASE WHEN b.odds < 0 THEN 1 ELSE b.odds END)
																WHEN t.statusId = 113 THEN 0
																END
											,b.awinlost	= CASE	
																WHEN t.statusId = 112 THEN b.actual_stake + b.stake * (CASE WHEN b.odds < 0 THEN 1 ELSE b.odds END) * (- b.apositiontaking)
																WHEN t.StatusId = 113 THEN b.actual_stake * b.apositiontaking
																END
											,b.mwinlost	= CASE	
																WHEN t.StatusId = 112 THEN b.stake * (CASE WHEN b.odds < 0 THEN 1 ELSE b.odds END) * (-b.mpositiontaking)
																WHEN t.StatusId = 113 THEN b.actual_stake * b.mpositiontaking
																END
											,b.swinlost = CASE	
																WHEN t.StatusId = 112 THEN b.stake * (CASE WHEN b.odds < 0 THEN 1 ELSE b.odds END) * (-b.spositiontaking)
																WHEN t.StatusId = 113 THEN b.actual_stake * b.spositiontaking
																END
											,b.playercomm = CASE 
																WHEN t.StatusId = 112 THEN @commWinRate * b.playerdiscount * b.stake
																WHEN t.StatusId = 113 THEN @commLostRate * b.playerdiscount * b.stake
																END
											,b.comm	= CASE 
															WHEN t.StatusId = 112 THEN @commWinRate * b.discount * b.stake * (1 - b.apositiontaking)
															WHEN t.StatusId = 113 THEN @commLostRate * b.discount * b.stake * (1- b.apositiontaking)
															END
											,b.acomm = CASE 
															WHEN t.StatusId = 112 THEN @commWinRate * b.adiscount * b.stake * (1-(b.mpositiontaking + b.apositiontaking))
															WHEN t.StatusId = 113 THEN @commLostRate * b.adiscount * b.stake * (1 - (b.mpositiontaking + b.apositiontaking))
															END
											,b.scomm = CASE
															WHEN t.StatusId = 112 THEN @commWinRate * b.sdiscount * b.stake * (1 - (b.spositiontaking + b.mpositiontaking + b.apositiontaking))
															WHEN t.StatusId = 113 THEN @commLostRate * b.sdiscount * b.stake * (1 - (b.spositiontaking + b.mpositiontaking + b.apositiontaking))
															END
											,b.ruben = 1
			WHEN NOT MATCHED BY TARGET THEN INSERT ([custid]
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
											,[swinlost]											
											,[playercomm]
											,[comm]
											,[acomm]
											,[scomm]
											,[apositiontaking]
											,[mpositiontaking]
											,[spositiontaking]
											,[tpositiontaking]
											,[playerdiscount]
											,[discount]
											,[adiscount]
											,[sdiscount]
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
											,[srecommend]
											,[ruben]
											,[betid]
											,[statuswinlost]
											,[modds]
											,[bettype]				   
											,[actual_stake]
											,[currency]
											,[ip]
											,[transdesc]																																												
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
											VALUES (
											t.custid 
											,t.transdate
											,0 -- oddsid
											,0 -- hdp1
											,0 -- hdp2
											,t.odds
											,t.stake
											,t.status
											,CASE 
												WHEN t.statusId = 112 THEN t.actual_stake + stake * (CASE WHEN t.odds < 0 THEN 1 ELSE odds END)
												WHEN t.statusId = 113 THEN 0
												END -- winlost
											,CASE
												WHEN t.statusId = 112 THEN t.stake * (CASE WHEN t.odds < 0 THEN 1 ELSE t.odds END) * (- t.apositiontaking)
												WHEN t.statusId = 113 THEN t.actual_stake * t.apositiontaking
												END -- awinlost
											,CASE 
												WHEN t.statusId = 112 THEN t.stake * (CASE WHEN t.odds < 0 THEN 1 ELSE t.odds END) * (- t.mpositiontaking)
												WHEN t.statusId = 113 THEN t.actual_stake * t.mpositiontaking
												END -- mwinlost
											,CASE	
												WHEN t.Statusid = 112 THEN t.stake * (CASE WHEN t.odds<0 then 1 else t.odds end) * (-spositiontaking)												
												WHEN t.Statusid = 113 THEN t.actual_stake * t.spositiontaking 
												END -- swinlost
											,CASE 
												WHEN t.statusId = 112 THEN (CASE t.custom2
																				WHEN '0' THEN 1
																				WHEN '1' THEN 0
																				ELSE 1
																				END) * t.playerdiscount * t.stake
												WHEN t.statusId = 113 THEN (CASE t.custom2
																				WHEN '0' THEN 1
																				WHEN '1' THEN 2
																				ELSE 1
																				END) * t.playerdiscount * t.stake
												END -- playercomm
											,CASE 
												WHEN t.Statusid = 112 THEN (CASE t.custom2
																			WHEN '0' THEN 1
																			WHEN '1' THEN 0 
																			ELSE 1
																			END) * t.discount * t.stake * (1 - t.apositiontaking)													
												WHEN t.Statusid = 113 THEN (CASE t.custom2
																			WHEN '0' THEN 1
																			WHEN '1' THEN 2 
																			ELSE 1
																			END) * t.discount * t.stake * (1 - t.apositiontaking)						
												END -- comm
											,CASE
												WHEN t.Statusid = 112 THEN (CASE t.custom2
																			WHEN '0' THEN 1
																			WHEN '1' THEN 0 
																			ELSE 1
																			END) * t.adiscount * t.stake * (1 - (t.mpositiontaking + t.apositiontaking))																											
												WHEN t.Statusid = 113 THEN (CASE t.custom2
																			WHEN '0' THEN 1
																			WHEN '1' THEN 2 
																			ELSE 1 
																			END) * t.adiscount * t.stake * (1 - (t.mpositiontaking + t.apositiontaking))						
												END -- acomm
											,CASE
												WHEN t.Statusid = 112 THEN (CASE t.custom2
																			WHEN '0' THEN 1
																			WHEN '1' THEN 0 
																			ELSE 1 
																			END) * t.sdiscount * t.stake * (1 - (t.spositiontaking + t.mpositiontaking + t.apositiontaking))																										
												WHEN t.Statusid = 113 THEN (CASE t.custom2
																			WHEN '0' THEN 1
																			WHEN '1' THEN 2 
																			ELSE 1 
																			END) * t.sdiscount * t.stake * (1 -(t.spositiontaking + t.mpositiontaking + t.apositiontaking))						
												END -- scomm
											,t.[apositiontaking]
											,t.[mpositiontaking]
											,t.[spositiontaking]
											,t.[tpositiontaking]
											,t.[playerdiscount]
											,t.[discount]
											,t.[adiscount]
											,t.[sdiscount]		
											,0 -- livehomescore
											,0 -- liveawayscore
											,t.[liveindicator]
											,SUBSTRING(t.transdesc,11,CHARINDEX(';bettypetime',t.transdesc)-11) -- betteam
											,t.[creator]
											,t.translogid -- refno
											,t.custom2 -- comstatus
											,t.[winlostdate] 
											,t.[betfrom]
											,'0' -- betcheck
											,NULL -- checktime
											,0 -- oddsspread
											,t.[actualrate]
											,t.EventID -- matchid
											,t.[recommend]
											,t.[mrecommend]
											,t.[srecommend]
											,1 -- ruben
											,t.custom3 -- betid
											,NULL -- statuswinlost
											,1 -- modds
											,t.gameID -- bettype
											,t.[actual_stake]
											,t.[currency]
											,t.[ip]
											,t.[transdesc]																																																					
											,t.[Username]
											,t.[CurrencyName]
											,t.[virtualrate]
											,t.custom1 -- oddstype
											,t.[statusID]
											,NULL -- currency2
											,t.[balance]
											,0 -- secAcceptFlag
											,0 -- transid2
											,NULL -- RecommDate
										)		;																					
		END
		
		-- refund tickets in translog
		UPDATE	dbo.translog WITH (ROWLOCK, UPDLOCK)
		SET		statusID = 103 -- Refund
				,status = 'Refund'
		OUTPUT	INSERTED.translogid
				,INSERTED.transdate
				,INSERTED.odds
				,INSERTED.stake
				,INSERTED.status
				,INSERTED.statusID
				,INSERTED.actual_stake
				,INSERTED.custom2
				,INSERTED.playerdiscount
				,INSERTED.discount
				,INSERTED.adiscount
				,INSERTED.apositiontaking
				,INSERTED.mpositiontaking
				,INSERTED.spositiontaking
				,INSERTED.tpositiontaking
				,INSERTED.liveindicator
				,INSERTED.creator
				,INSERTED.transdesc
				,INSERTED.winlostdate
				,INSERTED.betfrom
				,INSERTED.actualrate
				,INSERTED.eventID
				,INSERTED.recommend
				,INSERTED.mrecommend
				,INSERTED.srecommend
				,INSERTED.custid
				,INSERTED.custom3
				,INSERTED.gameID
				,INSERTED.currency
				,INSERTED.CurrencyName
				,INSERTED.ip
				,INSERTED.sdiscount
				,INSERTED.username	
				,INSERTED.virtualrate
				,INSERTED.custom1	
				,INSERTED.balance
		INTO	#tmpRefundedTicket
		WHERE	eventID = @MatchId
				AND gameID = @Bettype
				AND NOT EXISTS (SELECT t.translogid FROM #tmpSettledTicket t)
		
		-- refund existing & insert new tickets in bettrans
		MERGE	dbo.bettrans b
		USING	(SELECT *
				 FROM	#tmpRefundedTicket) AS t
		ON	b.refno	= t.translogid
		WHEN MATCHED THEN UPDATE SET	b.status = t.status
										,b.statusID = t.statusID
										,b.winlost = b.actual_stake
										,b.awinlost = 0
										,b.mwinlost = 0
										,b.swinlost = 0
										,b.playercomm = 0
										,b.comm = 0
										,b.acomm = 0
										,b.scomm = 0
										,b.ruben = 1
										,b.statuswinlost = 0
		WHEN NOT MATCHED BY TARGET THEN INSERT (
										[custid]
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
										,[swinlost]											
										,[playercomm]
										,[comm]
										,[acomm]
										,[scomm]
										,[apositiontaking]
										,[mpositiontaking]
										,[spositiontaking]
										,[tpositiontaking]
										,[playerdiscount]
										,[discount]
										,[adiscount]
										,[sdiscount]
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
										,[srecommend]
										,[ruben]
										,[betid]
										,[statuswinlost]
										,[modds]
										,[bettype]				   
										,[actual_stake]
										,[currency]
										,[ip]
										,[transdesc]																																												
										,[Username]
										,[CurrencyName]
										,[virtualrate]
										,[oddstype]
										,[statusID]
										,[currency2]
										,[balance]
										,[SecAcceptFlag]
										,[transid2]
										,[RecommDate]
										)
										VALUES (
										t.[custid]
										,t.[transdate]
										,0 -- oddsid
										,0 -- [hdp1]
										,0 -- [hdp2]
										,t.[odds]
										,t.[stake]
										,t.[status]
										,t.actual_stake -- [winlost]
										,0 -- [awinlost]
										,0 -- [mwinlost]
										,0 -- [swinlost]											
										,0 -- [playercomm]
										,0 -- [comm]
										,0 -- [acomm]
										,0 -- [scomm]
										,t.[apositiontaking]
										,t.[mpositiontaking]
										,t.[spositiontaking]
										,t.[tpositiontaking]
										,t.[playerdiscount]
										,t.[discount]
										,t.[adiscount]
										,t.[sdiscount]
										,0 -- [livehomescore]
										,0 -- [liveawayscore]
										,t.[liveindicator]
										,SUBSTRING(t.transdesc,11,CHARINDEX(';bettypetime',t.transdesc)-11) -- betteam
										,t.[creator]
										,t.translogid -- [refno]
										,t.custom2 -- [comstatus]
										,t.[winlostdate]
										,t.[betfrom]
										,0 -- [betcheck]
										,NULL -- [checktime]
										,0 -- [oddsspread]
										,t.[actualrate]
										,t.EventId -- [matchid]
										,t.[recommend]
										,t.[mrecommend]
										,t.[srecommend]
										,1 --[ruben]
										,t.custom2 -- [betid]
										,0 -- [statuswinlost]
										,1 -- [modds]
										,t.GameId -- [bettype]				   
										,t.[actual_stake]
										,t.[currency]
										,t.[ip]
										,t.[transdesc]																																												
										,t.[Username]
										,t.[CurrencyName]
										,t.[virtualrate]
										,t.custom1 -- [oddstype]
										,t.[statusID]
										,NULL -- [currency2]
										,t.[balance]
										,0 -- [SecAcceptFlag]
										,0 -- [transid2]
										,NULL -- [RecommDate]
										)
		;
		DROP TABLE #tmpSettledTicket
		DROP TABLE #tmpRefundedTicket
	END	
	ELSE IF @Action = 'UNDO'
	BEGIN
		IF @bettype IN (801,803,804,805)
		BEGIN
			UPDATE translog WITH(UPDLOCK,ROWLOCK)
			SET statusid = 0,
				status = 'running'
			OUTPUT INSERTED.translogid
			INTO #tmpTrans				
			WHERE GameID = @bettype
				AND EventID = @matchid
				AND SUBSTRING(transdesc,CHARINDEX('bettypetime',transdesc)+12,CHARINDEX(';time',transdesc)-CHARINDEX('bettypetime',transdesc)-12) = @bettypeTime
				AND statusId NOT IN (0, 1, 102, 101)  ---('running','waiting','void','reject')
		
			UPDATE Bettrans WITH(UPDLOCK,ROWLOCK)
			SET ruben = 0
				,STATUS = 'running'
				,statusID = 0
				,winlost = 0
				,awinlost = 0
				,mwinlost = 0
				,swinlost = 0
				,playercomm = 0
				,comm = 0
				,acomm = 0
				,scomm = 0
			WHERE matchid = @matchid
				AND bettype = @bettype
				AND refno IN (SELECT refno FROM #tmpTrans)
		END
	END
END




GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Calculate_801] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_801] TO [vnteam] AS [dbo]