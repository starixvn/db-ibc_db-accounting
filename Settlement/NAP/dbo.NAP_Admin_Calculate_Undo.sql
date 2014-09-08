/****** Object:  StoredProcedure [dbo].[NAP_Admin_Calculate_Undo]    Script Date: 09/08/2014 10:38:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.NAP_Admin_Calculate_Undo    Script Date: 3/20/2014 5:36:25 PM ******/

/****** Object:  Stored Procedure dbo.Admin_Calculate_Undo    Script Date: 2/26/2014 6:01:44 PM ******/
ALTER PROCEDURE [dbo].[NAP_Admin_Calculate_Undo] @matchid INT
AS
/*
	Created: Kathy
	Date: 20140213
	Task : unsettle a match, called by main SP Acc_Settlement_Undo, uses Rep execution
	DB: DBTRANS.bodb02
	Original: Admin_Calculate_Undo

	Revisions:
		- 20140905@Lukas: exclude virtual racing bettype 1231,1232,1233
	Param's Explanation:
			• @matchid: matchid of match to be unsettled
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
			--status NOT IN ('running','waiting','void','reject')
			statusID NOT IN (0, 1, 102, 101) AND bettype NOT BETWEEN 1301 AND 1334 -- exclude sporting solution product
			AND bettype NOT IN (1231,1232,1233)

		IF @@ROWCOUNT < 10000
			BREAK
	END
END

GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Admin_Calculate_Undo] TO [vnteam] AS [dbo]