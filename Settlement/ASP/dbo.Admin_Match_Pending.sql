 
ALTER PROCEDURE [dbo].[Admin_Match_Pending]
	@matchid int,
	@IsPending bit,
	@userID int 
WITH RECOMPILE
/*	Created:
	Task:  	
	DB: DB02.bodb02
	Original SP: 
	
	Revisions:
	
	Param's Explanation: 
*/
AS
SET NOCOUNT ON 

DECLARE @dbisPending BIT, @dbIsHTCal BIT, @dbcalculate BIT

SELECT	@dbisPending = isPending, @dbIsHTCal = IsHTCal, @dbcalculate = calculate 
FROM	Match_remark WITH (NOLOCK) 
WHERE	matchid = @matchid 

EXEC updateMatch_remark @matchid, 'IsP', @IsPending

--write log
DECLARE @LogData NVARCHAR(200)
SELECT @LogData = 'Update Pending Match : ' + cast(@matchid as varchar(30)) + ' with IsPending = ' + cast(@IsPending as varchar(2)) 
				+ '. Old Value : IsPending = ' + cast(@dbisPending as varchar(2)) + ' - IsHTCal = ' + cast(@dbIsHTCal as varchar(2))+ ' - calculate = ' + cast(@dbcalculate as varchar(2))

EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData



GO
GRANT EXECUTE ON [dbo].[Admin_Match_Pending] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Match_Pending] TO [VNTeam]
GO