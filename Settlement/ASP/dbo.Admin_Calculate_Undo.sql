
ALTER PROCEDURE [dbo].[Admin_Calculate_Undo] 
	@matchid int
As
/*
Created: 20090202@VinhTruong
Task : unsettle a match, called by main SP Acc_Settlement_Undo, uses Rep execution
DB: DBTRANS.bodb02
Original: DBA_Unsettle

Revisions:
		- 20100424@Henry: Update column StatusID of Bettrans 
		- 20100521@Henry: Change to use StatusID instead of Status in WHERE statement
		- 20100610@Thien: Change to update batch by batch
		- 20121022@Elodie: Exclude sporting solution product
		- 20140120@Lukas: insert settled command into LAS queue [Redmine:#8785]

Param's Explanation:
		• @matchid: matchid of match to be unsettled
*/
BEGIN
	SET NOCOUNT ON 
	--- LAS settlement 
	IF @@SERVERNAME IN ('DB052','DB054','DB231', 'DB232')  AND EXISTS (SELECT * FROM sys.databases WHERE name = 'LASDB')
	BEGIN		

		DECLARE @LASCommand NVARCHAR(1000),
				@createdDate DATETIME

		SELECT	 @LASCommand = 'EXEC [dbo].[Admin_Calculate_Undo] @matchid = ' + CONVERT(NVARCHAR(10),@matchid)							
				,@createdDate = GETDATE()

		EXEC LASDB.[dbo].[Las_GeneratingSettlementCommand]	 @SPName		= 'Admin_Calculate_Undo'
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
		SET
			ruben = 0, status = 'running', statusID = 0,
			winlost = 0, awinlost = 0, mwinlost = 0, swinlost = 0,
			playercomm = 0, comm = 0, acomm = 0, scomm = 0
		WHERE
			matchid = @matchid AND 
			--status NOT IN ('running','waiting','void','reject')
			statusID NOT IN (0,1,102,101)
			and bettype not between 1301 and 1334 -- exclude sporting solution product
    
		IF @@ROWCOUNT < 10000 BREAK
	END
END
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Calculate_Undo] TO [vnteam]