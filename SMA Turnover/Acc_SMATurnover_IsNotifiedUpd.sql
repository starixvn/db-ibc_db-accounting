


ALTER PROCEDURE [dbo].[Acc_SMATurnover_IsNotifiedUpd]
(
	@matchids	VARCHAR(1000),
	@supers		VARCHAR(1000),
	@nlevel		TINYINT = 80,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = '' OUTPUT
)
AS
/*
	Created: 20130702@Lukas
	Task: Update isNotified after sending mail successfully
	DB: DBAGE/bodb02
	
	Revisions:
		-- 20140630@Lukas: add 1 more specific level for notification - 95% [Redmine:#18384]
	Parameter explaination:
		@nlevel: level of notification,	only two levels now: 80% & 95%
*/
BEGIN
	SET NOCOUNT ON 
	
	;WITH tmp AS
	(
		SELECT m.val AS matchid, c.val AS custid
		FROM dbo.strSplit(@matchids,',') m
			INNER JOIN dbo.strSplit(@supers,',') c ON m.rank = c.rank
	)
	UPDATE t WITH(ROWLOCK,UPDLOCK)
	SET t.IsNotified = @nlevel
	FROM DownlineTurnover_Setting t
		INNER JOIN tmp ON t.matchid = tmp.matchid AND t.custid = tmp.custid
	
	IF @@ERROR <> 0
	BEGIN
		SELECT	@ErrCode = 101,
				@ErrMsg  = 'Update does not successfully.'
	END
END
GO
GRANT EXECUTE ON [dbo].[Acc_SMATurnover_IsNotifiedUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_SMATurnover_IsNotifiedUpd] TO vnteam


