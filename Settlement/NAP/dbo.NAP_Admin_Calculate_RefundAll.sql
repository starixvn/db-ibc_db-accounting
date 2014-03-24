ALTER PROCEDURE [NAP_Admin_Calculate_RefundAll] @matchid INT
	,@fth SMALLMONEY
	,@fta SMALLMONEY
	,@IsExcludeBetdaq BIT = 0
	,@IsExcludeBetfair BIT = 0
	,@IsSettleAbandonedMatchIBC BIT = 0
AS
/*	Created by: Kathy
	Date: 20140213
	Task: Refund All
	DB: DBTXN/BODB02	
	Revisions:
	

	Note: For settlement SPs should hardcode the custid of betdaq customer to avoid replication problem
*/
BEGIN
	SET NOCOUNT ON

	--- LAS settlement 
	IF @@SERVERNAME IN ('DB052', 'DB054', 'DB231', 'DB232') AND EXISTS (
			SELECT *
			FROM sys.databases
			WHERE NAME = 'LASDB'
			)
	BEGIN
		DECLARE @LASCommand NVARCHAR(1000)
			,@createdDate DATETIME

		SELECT @LASCommand = 'EXEC [dbo].[Admin_Calculate_RefundAll] @matchid = ' + CONVERT(NVARCHAR(10), @matchid)
			,@createdDate = GETDATE()

		EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand] @SPName = 'Admin_Calculate_RefundAll'
			,@SQLCommand = @LASCommand
			,@CreatedDate = @createdDate
			,@StatusID = 0 -- waiting
			,@MatchID = @matchid
			,@Bettype = 0 -- hardcode
			,@Status = 'waiting'
			,@BetCount = 0
	END

	WHILE 1 = 1
	BEGIN
		UPDATE TOP (10000) dbo.bettrans WITH (ROWLOCK, UPDLOCK)
		SET [status] = N'Refund'
			,statusID = 103
			,winlost = actual_stake
			,awinlost = 0
			,mwinlost = 0
			,swinlost = 0
			,playercomm = 0
			,comm = 0
			,acomm = 0
			,scomm = 0
			,ruben = 1
			,statuswinlost = 0
		WHERE matchid = @matchid AND statusID NOT IN (103, 101, 102) AND bettype NOT IN (14) AND bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
			AND 1 = CASE 
				WHEN @IsExcludeBetdaq = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) THEN 0
				WHEN @IsExcludeBetfair = 1 AND custid IN (2331, 1077687, 115770) THEN 0
				WHEN @IsSettleAbandonedMatchIBC = 1 AND (custid NOT IN (50057, 879241, 103873, 78761, 851668, 878902, 2331, 1077687, 115770) AND recommend <> 1688156) AND statusID IN (112, 113) AND bettype IN (13, 26, 27) THEN 0
				ELSE 1
				END

		IF @@ROWCOUNT < 10000
			BREAK
	END
END



GO

GRANT EXECUTE ON [NAP_Admin_Calculate_RefundAll] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_Calculate_RefundAll] TO [vnteam] AS [dbo]
GO


