ALTER PROCEDURE [dbo].[Acc_Set_MatchUpdScore]
	@matchid int,
	@finalhomescore int,
	@finalawayscore int,
	@hthomescore int,
	@htawayscore int,
	@betstatus nvarchar(50) = '',
	@UserID int
AS
/*
Created by:[]
Date:
Task: Update match score
DB: DB02.BODB02
Original: \account\Calculate_SaveScore.asp

Revisions:
    - 20100825@Lukas: Update last time modify (changetime column) for match table
    - 20120309@Hurri: Update isUndecided = 0 after performing Bill/Key Score/Refund
 */


SET NOCOUNT ON

UPDATE match WITH(ROWLOCK,UPDLOCK)
SET finalhomescore = @finalhomescore,
	finalawayscore = @finalawayscore,
	hthomescore = @hthomescore,
	htawayscore = @htawayscore,
	eventstatus='closed',
	betstatus = @betstatus,
	changetime = getdate()
WHERE matchid = @matchid
 
EXEC updateMatch_remark @matchid, 'IsU', 0	--update isUndecided

DECLARE @LogData NVARCHAR(200)
SELECT @LogData = 'Calculate SaveScore matchid:' + cast(@matchid as varchar(30)) + ' HT:' + cast(@hthomescore as varchar(10)) + '-' + cast(@htawayscore as varchar(10)) + ' FT:' + cast(@finalhomescore as varchar(10)) + '-' + cast(@finalawayscore as varchar(10)) + ' Status = ' + cast(@betstatus as nvarchar(50))
EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData


GO
GRANT EXECUTE ON [dbo].[Acc_Set_MatchUpdScore] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Set_MatchUpdScore] TO [VNTeam]
GO 