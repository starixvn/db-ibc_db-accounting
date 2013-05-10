CREATE PROCEDURE [dbo].[NAP_Set_MatchUpdIsUndecided]
	@matchid int,
	@IsUndecided bit,
	@userID int 
WITH RECOMPILE
/*	Created: 20120306@Hurri
	Task: Update to mark/unmark a match as Undecided
	DB: DB02.bodb02
	Original SP:[Acc_Set_MatchUpdIsUndecided] 
	
	Revisions:
	
	Param's Explanation: 
*/
AS
SET NOCOUNT ON 

DECLARE @dbisUndecided BIT

SELECT	@dbisUndecided = isUndecided
FROM	Match_remark WITH (NOLOCK) 
WHERE	matchid = @matchid 

IF(@dbisUndecided <> @IsUndecided)
BEGIN
	EXEC updateMatch_remark @matchid, 'IsU', @IsUndecided

	--write log
	DECLARE @LogData NVARCHAR(200)
	SELECT @LogData = 'Update Undecided Match : MatchID = ' + cast(@matchid as varchar(30)) + ' with IsUndecided = ' + cast(@IsUndecided as varchar(2))

	EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
END

GO
GRANT EXECUTE ON [dbo].[NAP_Set_MatchUpdIsUndecided] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Set_MatchUpdIsUndecided] TO [VNTeam]
GO