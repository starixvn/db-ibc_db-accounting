USE bodb02
GO

ALTER PROCEDURE [dbo].[NAP_WinLimit_Notification_MemUpd]
(
	@MemNotify		XML
	, @ErrCode 		INT = 0 OUTPUT
	, @ErrMsg 		NVARCHAR(200) = '' OUTPUT
)
AS
/*
Created: 20150702@bobby.nguyen
Task : #35215 - Win Limit Control - Notification update member
DB: DBTXN.bodb02
Original:
Revisions:
	- 20150702@bobby.nguyen: Initial
	- 20160507@Patrick: #57213 - Voidbridge integration
	
Param's Explanation:
	• @ErrCode	:
		= 0		: Transaction recorded successfully.
		> 0		: Specific Error.
	• @ErrMsg	: Error description.
	• @MemNotify: XML.format(<notify><row custid = "1" productid="1" winlostdate="" /></notify>)
*/
BEGIN
	SET NOCOUNT ON
	
	CREATE TABLE #tempMemNotify
	(
		custid			INT
		, productid		TINYINT
		, winlostdate	SMALLDATETIME
	)
	
	-- RESET output
	SELECT 	@ErrCode 	= 0
			, @ErrMsg 	= ''
	
	INSERT INTO #tempMemNotify
	SELECT  
       Tbl.Col.value('@custid', 'INT'),  
       Tbl.Col.value('@productid', 'TINYINT'),
	   Tbl.Col.value('@winlostdate', 'SMALLDATETIME')

	FROM @MemNotify.nodes('//notify/row') Tbl(Col)
	
	IF ( @@ROWCOUNT = 0 )
	BEGIN
		SELECT 	@ErrCode 	= 100
			, @ErrMsg 		= 'There is no information.'
			
		RETURN;
	END
	
	UPDATE g 
	SET g.IsNotified = 1
	FROM dbo.WinLimit_Game g WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #tempMemNotify t
		ON g.custid 		= t.custid
		AND g.winlostdate	= t.winlostdate
		AND g.productid		= t.productid
	
	
	RETURN;
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_Notification_MemUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_Notification_MemUpd] TO [vnteam]
GO

