ALTER PROCEDURE [dbo].[NAP_SMATurnover_IsNotifiedUpd]
(
	@matchids	VARCHAR(1000),
	@supers		VARCHAR(1000),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = '' OUTPUT
)
AS
/*
	Created: 20140416@Elodie
	Task: Update isNotified after sending mail successfully
	DB: DBAGE/bodb02
	
	Revisions:
	
*/
BEGIN
	SET NOCOUNT ON 
	
	;WITH tmp AS
	(
		SELECT m.val AS matchid, c.val AS SMAID
		FROM dbo.strSplit(@matchids,',') m
			INNER JOIN dbo.strSplit(@supers,',') c ON m.rank = c.rank
	)
	UPDATE t WITH(ROWLOCK,UPDLOCK)
	SET t.IsNotified = 1
	FROM DownlineTurnover_Setting t
		INNER JOIN tmp ON t.matchid = tmp.matchid AND t.SMAID = tmp.SMAID
	
	IF @@ERROR <> 0
	BEGIN
		SELECT	@ErrCode = 101,
				@ErrMsg  = 'Update does not successfully.'
	END
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnover_IsNotifiedUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnover_IsNotifiedUpd] TO [vnteam]
 