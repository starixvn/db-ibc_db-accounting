CREATE PROCEDURE [dbo].[NAP_EventSelect] 
	@MatchId	INT
	,@VendorID  INT = 5
	,@ErrCode	INT OUTPUT
	,@ErrMsg	NVARCHAR(200) OUTPUT
AS
/*  
	Created: 20150623@Dominic  
	Task : Get event details
	DB: DBAGE/bodb02  

	  
	Revisions:    
	      
	Param's Explanation:  

*/
BEGIN
	SELECT @ErrCode = 0, @ErrMsg = ''
	IF NOT EXISTS(SELECT TOP 1 1 FROM [ResultDetail3rd] WITH(NOLOCK) WHERE MatchID = @MatchId)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid match'
		RETURN
	END
	SELECT GameID, CASE WHEN gameid = 805 THEN Custom1+'%' ELSE Custom1 END Custom1
	FROM [dbo].[ResultDetail3rd] WITH(NOLOCK)
	WHERE MatchID = @MatchId AND VendorID = @VendorID
	ORDER BY GameID,Custom1
END
GO
GRANT EXECUTE ON [dbo].[NAP_EventSelect] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_EventSelect] TO [vnteam] AS [dbo]