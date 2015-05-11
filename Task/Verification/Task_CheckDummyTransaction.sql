ALTER PROCEDURE [dbo].[Task_CheckDummyTransaction]

AS

/*	Created by: Jamie
	Date: 2012-05-31
	Task: Checking dummy transaction in bettrans or not
		  Effect from 1st Jun, 2012 onwards 

*/

BEGIN
	SET NOCOUNT ON 
	
	DECLARE	@Message	VARCHAR(8000),
			@ErrorCode	TINYINT,
			@Bettypes	VARCHAR(7500),
			@Winlostdate DATETIME
	
	SELECT	@Message='',
			@ErrorCode=0,
			@Bettypes=''
	
	SELECT	@Winlostdate = '2012-06-01'

	IF EXISTS (	SELECT TOP 1 1 
				FROM	bettrans WITH (NOLOCK) 
				WHERE	winlostdate >=@Winlostdate
						AND statusID=121 --DONE
						AND bettype <=19000
			) 
	BEGIN
		SELECT	@Bettypes = @Bettypes + cast( Bettype AS varchar(20)) +','
		FROM	bettrans WITH (NOLOCK) 
				WHERE	winlostdate >=@Winlostdate
						AND statusID=121 --DONE
						AND bettype <=19000

		SELECT	@Message = 	@Message + 'Dummy Transaction problem:' + @Bettypes
		SELECT	@Message

		RAISERROR(@Message,16,1)
	END


END
GO
GRANT VIEW DEFINITION ON [dbo].[Task_CheckDummyTransaction] TO [VNTeam]



