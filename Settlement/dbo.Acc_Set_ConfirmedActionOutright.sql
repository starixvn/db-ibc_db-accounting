ALTER PROCEDURE  [dbo].[Acc_Set_ConfirmedActionOutright]
	@matchid int,
	@actionid tinyint,
	@status nvarchar(10),
	@deadheat float
AS	
/**
 * Created by	: Dan
 * Date			: 20130712
 * Task			: Update Confirmed Action value for outright
 * DB			: DBTRANS/bodb02
 * Revisions	:
 *	•
 * Parameters:	
	
 */

SET NOCOUNT ON
EXEC [Acc_Apl_ExecRep_02]		
	@matchid = @matchid,
	@actionid = @actionid,
	@status = @status,
	@deadheat = @deadheat	

GO
GRANT EXECUTE ON [dbo].[Acc_Set_ConfirmedActionOutright] TO [Dot_Admin] AS [dbo]