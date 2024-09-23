/*<info serverAlias="DBACC-bodb02" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_StatementRewardSel_Old]
	@fromdate	SMALLDATETIME,
	@todate		SMALLDATETIME,
	@custid		INT
AS
/*
	Created by: 20240826@Bobby
	Task: 209633 - CreditReward - Reward Statement
	DB: DBACC.bodb02
	ORIGINAL: Acc_AllStatement_Full

	Revisions:
		- 20240826@Bobby: Init [Redmine: #209633]
*/
BEGIN
	SET NOCOUNT ON;
END
