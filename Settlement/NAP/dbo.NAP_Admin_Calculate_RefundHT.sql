/****** Object:  StoredProcedure [dbo].[NAP_Admin_Calculate_RefundHT]    Script Date: 08/15/2014 14:05:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_RefundHT] @matchid INT
	,@IsExcludeBetdaq BIT = 0
	,@IsExcludeBetfair BIT = 0
AS
/*	Created by: Kathy
	Date: 20140213
	Task: Refund HT 
	DB: DBTXN/BODB02
	Revisions:
		- 20140426@Kathy: Add 1H total goal (126) [Redmine:#14449]
		- 20140729@Kathy: Add one more account(BF3) into BetFair's group [Redmine:#19665]
		- 20140620@Kathy: Apply BetRadar:
							- Add 1st Correct Score(151) 	
							- Refund FT bettypes  [Redmine:#17142]
		- 20140811@Kathy: Support new 11 bettypes [Redmine:#19667]					
		

	Param's Explanation:
		+ @IsExcludeBetdaq: 
			= 1 : Refund Excluding BetDaq
			= 0 : Refund HT including BetDaq 
		+ @IsExcludeBetfair: 
			= 1 : Refund Excluding Betfair
			= 0 : Refund HT including Betfair
				
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

		SELECT @LASCommand = 'EXEC [dbo].[Admin_Calculate_RefundHT] @matchid = ' + CONVERT(NVARCHAR(10), @matchid)
			,@createdDate = GETDATE()

		EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand] @SPName = 'Admin_Calculate_RefundHT'
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
			,ruben = 1
			,winlost = actual_stake
			,awinlost = 0
			,mwinlost = 0
			,swinlost = 0
			,playercomm = 0
			,comm = 0
			,acomm = 0
			,scomm = 0
		WHERE matchid = @matchid
			--AND [status] not in (N'Void', N'Reject')
			AND statusID NOT IN (103, 101, 102) 			
			AND bettype IN (7, 8, 15, 12, 21, 30, 125, 126, 129, 136, 138, 143, 151, 
							128,
							133, 134, 140, 141, 142, 146, 147, 148, 149, 150, 152 ) -- BetRadar: refund FT ticket in case of 30x3 match
			AND 1 = CASE 
						WHEN @IsExcludeBetdaq = 1 AND (custid IN (50057, 879241, 103873, 78761, 851668, 878902) OR recommend = 1688156) THEN 0
						WHEN @IsExcludeBetfair = 1 AND custid IN (2331, 1077687, 115770, 15523642) THEN 0
						ELSE 1
					END

		IF @@ROWCOUNT < 10000
			BREAK
	END
END





GO
GRANT EXECUTE ON [dbo].[NAP_Admin_Calculate_RefundHT] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_RefundHT] TO [vnteam] AS [dbo]