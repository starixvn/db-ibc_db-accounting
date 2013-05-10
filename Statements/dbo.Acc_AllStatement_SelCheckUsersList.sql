ALTER PROCEDURE [dbo].[Acc_AllStatement_SelCheckUsersList]
	@userlist varchar(6000)
	
AS
 
 /*
	Created by: KhoaTran
	Date: 20100203
	Task: Check the users list is valid or not
	DB: DB06.BODB02 
	
	Revisions:		
 */

SET NOCOUNT ON
BEGIN
	DECLARE @TEMP_USER_VALID TABLE (username varchar(50)) 	
	DECLARE @TEMP_USER_LIST TABLE (username varchar(50), IsValid bit) 

	INSERT INTO @TEMP_USER_LIST (username, IsValid)
	SELECT  val					 AS username , 
			0                    As IsValid 
	FROM dbo.strSplit(@userlist, ',') 

	INSERT INTO @TEMP_USER_VALID	
	SELECT c.username FROM custinfo (NOLOCK) c INNER JOIN @TEMP_USER_LIST t ON c.username = t.username	

	UPDATE @TEMP_USER_LIST SET IsValid = 1	WHERE username in (SELECT USERNAME FROM @TEMP_USER_VALID)
	
	SELECT * FROM @TEMP_USER_LIST ORDER BY IsValid, UserName
	
	
END

GO
GRANT EXECUTE ON [dbo].[Acc_AllStatement_SelCheckUsersList] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AllStatement_SelCheckUsersList] TO [vnteam]



