ALTER PROCEDURE [dbo].[Admin_Settlement_1]
	@creator int,
	@matchid int,
	@fth smallint = NULL,
	@fta smallint = NULL,
	@hth smallint,
	@hta smallint,
	@goalrecord varchar(50)= NULL,
	@betstatus nvarchar(50),
	@action varchar(10) = 'CAL',
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@DelayTime int = 0 OUTPUT
AS


/*	Creator: Viet
	Date: 21 Sep 2011
	Task: main SP for settlement
	DB: DB052.bodb_review
	
	History:		
			
	Param's Explanation:
		+ @betstatus: Used for score table, FGLG status, refund status
		
*/

SET NOCOUNT ON


-- do it later

GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_1] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Admin_Settlement_1] TO [vnteam]