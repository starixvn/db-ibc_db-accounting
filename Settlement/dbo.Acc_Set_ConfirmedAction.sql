ALTER PROCEDURE  [dbo].[Acc_Set_ConfirmedAction]		
@matchid INT,
@action tinyint,
@fth smallint = NULL,
@fta smallint = NULL,
@hth smallint = NULL,
@hta smallint = NULL,
@goalrecord varchar(50)= NULL,
@betstatus nvarchar(50) = NULL
AS	
/**
 * Created by	: Kaden
 * Date			: 20130318
 * Task			: Update Confirmed Action value
 * DB			: SVRTRANS/TransDB
 * Revisions	:
 *	•
 * Parameters:
	@ConfirmedAction: new action
	@action: action key (0: Unsettlement; 1-9: Calculate; 11-19: Refund)
	@fth: finalhomescore,
	@fta: finalawayscore,
	@hth: hthomescore,
	@hta: htawayscore,
	@goalrecord: Goal Record,
	@betstatus: Bet Status
 */

SET NOCOUNT ON
EXEC [Acc_Apl_ExecRep_00]		
	@matchid = @matchid,
	@action = @action,
	@fth = @fth,
	@fta = @fta,
	@hth = @hth,
	@hta = @hta,
	@goalrecord = @goalrecord,
	@betstatus  = @betstatus
GO
GRANT EXECUTE ON [dbo].[Acc_Set_ConfirmedAction] TO [bodbAdminNet] AS [dbo]