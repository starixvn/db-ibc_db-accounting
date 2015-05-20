ALTER PROCEDURE [dbo].[Task_Daily3rdProductWinlost_Add]
@Winlostdate		DATETIME,
@WinlostRM			MONEY,
@FromCustID			INT,
@FromUsername		VARCHAR(30),
@FromRecommend		INT,
@FromMRecommend		INT,
@FromSRecommend		INT,
@ToCustID			INT,
@ToUsername			VARCHAR(30),
@ToRecommend		INT,
@ToMRecommend		INT,
@ToSRecommend		INT,
@TransDesc			VARCHAR(100),
@Creator			INT = 0  

AS 
/*
	Created by:Jamie 
	Date: 2012-02-22
	Task: Add transfers for balancing amounts 
	DB: DBTRANS.BODB02

	Revisions: 

	Param's Explanation:


*/
BEGIN
		SET NOCOUNT ON 
		
		IF @WinlostRM = 0 RETURN 
		
		DECLARE @TransCode	INT,
				@RefNo		BIGINT

		BEGIN TRANSACTION
			EXEC dbo.Acc_SelTransCode @transcode = @TransCode OUTPUT
			select @refno=200000000000+@TransCode
		COMMIT TRANSACTION 

		-- Creator: 5838421 (dbaAdmin)

		INSERT INTO bettrans (
			custid, creator, recommend, mrecommend, srecommend, matchid, bettype, transdate, winlostdate, ruben, [status], statusID,
			actual_stake,
			stake,
			winlost,
			awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm,
			tpositiontaking, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount,
			oddsid, betteam, hdp1, hdp2, odds, modds, betfrom, transdesc,
			actualrate, virtualrate, currency, refno, username, currencyName
			)
		VALUES (
			@FromCustID,@Creator, @FromRecommend, @FromMRecommend, @FromSRecommend, 0, 21003, @Winlostdate, @Winlostdate, 1,'Completed',131,
			CASE WHEN @WinlostRM>0 THEN 0 ELSE ABS(@WinlostRM) END,
			CASE WHEN @WinlostRM>0 THEN 0 ELSE ABS(@WinlostRM) END,
			CASE WHEN @WinlostRM>0 THEN @WinlostRM ELSE 0 END,
			0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,'0',0,0,0,0,'i',@TransDesc,
			1,1,2,@Refno,@FromUsername,'RM' 
		)
		
		INSERT INTO bettrans (
			custid, creator, recommend, mrecommend, srecommend, matchid, bettype,transdate, winlostdate, ruben, [status], statusID,
			actual_stake,
			stake,
			winlost,
			awinlost, mwinlost, swinlost, playercomm, comm, acomm, scomm,
			tpositiontaking, apositiontaking, mpositiontaking, spositiontaking, playerdiscount, discount, adiscount, sdiscount,
			oddsid, betteam, hdp1, hdp2, odds, modds, betfrom, transdesc,
			actualrate, virtualrate, currency, refno, username, currencyName
			)
		VALUES(
			@ToCustID,@Creator,@ToRecommend, @ToMRecommend, @ToSRecommend,0,21003, @Winlostdate, @Winlostdate, 1,'Completed',131,
			CASE WHEN @WinlostRM > 0 THEN @WinlostRM ELSE 0 END,
			CASE WHEN @WinlostRM > 0 THEN @WinlostRM ELSE 0 END,
			CASE WHEN @WinlostRM > 0 THEN 0 ELSE ABS(@WinlostRM) END,
			0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,
			0,'0',0,0,0,0,'i',@TransDesc,
			1,1,2,@Refno,@ToUsername,'RM'		 
		)
END 
GO 
GRANT VIEW DEFINITION ON [dbo].[Task_Daily3rdProductWinlost_Add] TO [VNTeam] 