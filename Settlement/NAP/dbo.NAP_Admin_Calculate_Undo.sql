ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_Undo] 
	 @matchid INT
	,@SelectedSet	VARCHAR(50)	= NULL
	,@ResourceIDs	VARCHAR(MAX)= NULL 
AS
/*
	Created: Kathy
	Date: 20140213
	Task : unsettle a match, called by main SP Acc_Settlement_Undo, uses Rep execution
	DB: DBTRANS.bodb02
	Original: Admin_Calculate_Undo

	Revisions:
		- 20140905@Lukas: exclude virtual racing bettype 1231,1232,1233
		- 20140909@Kathy: Exclude virtual racing (bettype 1231,1232,1233, 1237, 1238), outright (bettype 10, 31, 32, 33), keno (1501 -> 1599)
		- 20141022@Jamie: Sporting Solution for Tennis [Redmine:#23034]
		- 20150206@Jamie: Auto Settlement Betradar phase 2 [Redmine: #27212]
	Param's Explanation:
			• @matchid: matchid of match to be unsettled
*/
BEGIN
	SET NOCOUNT ON

	--- LAS settlement 
	IF @@SERVERNAME IN ('DB052', 'DB054', 'DB231', 'DB232','DB215') AND EXISTS (
			SELECT *
			FROM sys.databases
			WHERE NAME = 'LASDB'
			)
	BEGIN
		DECLARE @LASCommand NVARCHAR(1000)
			,@createdDate DATETIME

		SELECT @LASCommand = 'EXEC [dbo].[Admin_Calculate_Undo] @matchid = ' + CONVERT(NVARCHAR(10), @matchid)
			,@createdDate = GETDATE()

		EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand] @SPName = 'Admin_Calculate_Undo'
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
		WHERE matchid = @matchid AND
			statusID NOT IN (0, 1, 102, 101)  ---('running','waiting','void','reject')
			AND bettype NOT IN (10, 31, 32, 33, 1231, 1232, 1233, 1237, 1238) -- Outright, VSRacing
			AND bettype NOT BETWEEN 1501 and 1599 -- Keno
			AND 1 = CASE WHEN @SelectedSet IS NULL THEN 1 
						 WHEN @SelectedSet LIKE '%1%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND (BetID = 801 OR BetID BETWEEN 80101 AND 80199) THEN 1 
						 WHEN @SelectedSet LIKE '%2%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND (BetID = 802 OR BetID BETWEEN 80201 AND 80299) THEN 1
						 WHEN @SelectedSet LIKE '%3%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND (BetID = 803 OR BetID BETWEEN 80301 AND 80399) THEN 1
						 WHEN @SelectedSet LIKE '%4%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND (BetID = 804 OR BetID BETWEEN 80401 AND 80499) THEN 1
						 WHEN @SelectedSet LIKE '%5%' AND Bettype IN (154,155,156,1311,1312,1316,1317,1318,1324) AND (BetID = 805 OR BetID BETWEEN 80501 AND 80599) THEN 1
						 WHEN @SelectedSet LIKE '%6%' AND Bettype IN (1,2,3,20,153,1301,1302,1303,1305,1306,1308) THEN 1 
						 ELSE 0 END 
			AND 1 = CASE WHEN @ResourceIDs IS NULL AND Bettype NOT IN (135,160,164,168,169,174,175,176,180,192,193) THEN 1 
						 WHEN @ResourceIDs IS NOT NULL AND Bettype IN (160,164,169,180) AND CHARINDEX(SUBSTRING(CAST(BetID AS VARCHAR(20)),2,5),@ResourceIDs)>0 THEN 1 
						 WHEN @ResourceIDs IS NOT NULL AND Bettype IN (135,168,174,175,176,192,193) AND CHARINDEX(CAST(Bettype AS VARCHAR(20)),@ResourceIDs)>0 THEN 1 
						 ELSE 0 END  
		IF @@ROWCOUNT < 10000
			BREAK
	END
END
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_Undo] TO [vnteam] AS [dbo]