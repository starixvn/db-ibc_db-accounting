

ALTER PROCEDURE [dbo].[Admin_Recalculate_Preview]
(
	@matchid	INT,
	@creator	INT,
	@fth		SMALLINT = NULL,
	@fta		SMALLINT = NULL,
	@hth		SMALLINT,
	@hta		SMALLINT,
	@goalrecord VARCHAR(50)= NULL,
	@betstatus	NVARCHAR(50),	
	@IP			VARCHAR(15) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = '' OUTPUT,
	@DelayTime	INT = 0 OUTPUT
)
AS
/*
	Created by: 20111116@Lukas
	Task: Get affected tickets after re-calculate
	DB: DB052.BODB_REVIEW
	
	Revision:
		
*/
BEGIN
	
	EXEC Admin_Recalculate_settlement	
			@matchid	= @matchid,
			@creator	= @creator,
			@fth		= @fth,
			@fta		= @fta,
			@hth		= @hth,
			@hta		= @hta,
			@goalrecord = @goalrecord,
			@betstatus	= @betstatus,			
			@IP			= @IP,
			@ErrCode	= @ErrCode OUTPUT,
			@ErrMsg		= @ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN

	EXEC [dbo].[Admin_Recalculate_Result]
			@matchid = @matchid
	
END

GO 

GO
GRANT EXECUTE ON [dbo].[Admin_Recalculate_Preview] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Recalculate_Preview] TO [VNTeam]
GO 
