ALTER PROCEDURE [Admin_Calculate_RefundAll]
	@matchid			int,
	@fth				SMALLMONEY = 0,
	@fta				SMALLMONEY = 0,
	@IsExcludeBetdaq	bit = 0,
	@IsExcludeBetfair	bit = 0,
	@IsSettleAbandonedMatchIBC bit = 0
AS
/*	Created by: Jamie
	Date: 2010-06-10
	Task: Refund All
	DB: DBTXN/BODB02	
	Revisions:
	- 20101001@Henry: Using f_GetBetDaqCustomer to query betdaq customer
	- 20101013@Henry: add custid 1077687 (BFOS as betdaq member)
	- 20110817@Lukas: Exclude refund FG/LG bettype
	- 20121022@Elodie: Exclude sporting solution product
	- 20131227@Kathy: Add more Betdaq's customer: BDUS016, BDUS01 [Redmine:#9765]
	- 20140106@Elodie: Option to exclude Bet Fair tickets in refund process (Redmine:#9764)
	- 20140120@Lukas: insert settled command into LAS queue [Redmine:#8785]
	- 20140312@Kathy: Execute settlement for abandoned/postponed matches (bettype 13,26,27) [Redmine:#12049] 
	- 20140411@Kathy: Add more param for LAS command
	- 20140421@Kathy: Add 1H FGLG bettypes (127) [Redmine:#14718]

	Note: For settlement SPs should hardcode the custid of betdaq customer to avoid replication problem
*/
BEGIN
	SET NOCOUNT ON 
	--- LAS settlement 
	IF @@SERVERNAME IN ('DB052','DB054','DB231', 'DB232')  AND EXISTS (SELECT * FROM sys.databases WHERE name = 'LASDB')
	BEGIN		
		DECLARE @LASCommand NVARCHAR(1000),
				@createdDate DATETIME

		SELECT	 @LASCommand = 'EXEC [dbo].[Admin_Calculate_RefundAll] @matchid = ' + CONVERT(NVARCHAR(10),@matchid)	
								+ ', @IsSettleAbandonedMatchIBC = ' + CONVERT(NVARCHAR(10), ISNULL(@IsSettleAbandonedMatchIBC, 0)) 													
				,@createdDate = GETDATE()

		EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand]	 @SPName		= 'Admin_Calculate_RefundAll'
															,@SQLCommand	= @LASCommand
															,@CreatedDate	= @createdDate
															,@StatusID		= 0 -- waiting
															,@MatchID		= @matchid
															,@Bettype		= 0 -- hardcode
															,@Status		= 'waiting'
															,@BetCount		= 0

	END

	WHILE 1=1
	BEGIN
		UPDATE TOP (10000) dbo.bettrans with (ROWLOCK, UPDLOCK)	
		set	
			[status]=N'Refund',
			statusID = 103,
			winlost=actual_stake,
			awinlost=0,
			mwinlost=0,
			swinlost=0,
			
			playercomm=0,
			comm=0,
			acomm=0,
			scomm=0,
			
			ruben=1,
			statuswinlost=0
		where
			matchid=@matchid
			AND statusID not in (103,101,102)	
			AND bettype NOT In (14, 127)
			AND bettype not between 1301 and 1334 -- exclude sporting solution product
			AND 1 = CASE WHEN @IsExcludeBetdaq = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) THEN 0 
							WHEN @IsExcludeBetfair = 1 AND custid IN (2331, 1077687, 115770) THEN 0
							WHEN @IsSettleAbandonedMatchIBC = 1 
									AND (custid not IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770) AND  recommend <> 1688156)
									AND statusID IN (112,113)
									 and bettype in (13,26,27)
								THEN 0
					ELSE 1 END
		IF @@ROWCOUNT < 10000 BREAK
	END	
END
GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_RefundAll] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_RefundAll] TO [vnteam] AS [dbo]