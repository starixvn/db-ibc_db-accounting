ALTER PROCEDURE [dbo].[Acc_CheckSettledDate]
@winlostdate DATETIME,
@UserID INT,
@ErrCode INT = 0 OUTPUT,
@ErrMsg VARCHAR(500) = '' OUTPUT
AS
/*
Created: 20111101@Sophia
Task: Check winlostdate before resettle, delete transaction, recover bet...
DB: DBTRANS.BODB02

Revisions:
	- 20111110@Jamie: Allow Ahwan23 to delete historical transactions 

Param's Explanation:
*/
 
SET NOCOUNT ON 

SET  @ErrCode = 0
SET  @ErrMsg = ''

IF @userid NOT IN ( 26020, --ahwan23
					360418 , ---'dbaThien',
					862400, ---'pgmViet',
					1948903, ---'dbaJamie',
					25520, ---'joe',
					8)  --sa
BEGIN 
	DECLARE @AllowedDate DATETIME

	SELECT  @AllowedDate = MAX(winlostdate)+ 1
	FROM	bettrans WITH (NOLOCK)
	WHERE	custid  = 44621 AND bettype > 20000 AND matchID =0

	IF @winlostdate < @AllowedDate
	BEGIN 
		SELECT  @ErrCode = 1,
				@ErrMsg = 'You are not authorized to perform the current operation before ' + convert(varchar(10),@AllowedDate,120) 
					+'. Please contact to the administrator for assistance!'
		RETURN
	END 
END 
 


GO
GRANT EXECUTE ON [dbo].[Acc_CheckSettledDate] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CheckSettledDate] TO [vnteam]