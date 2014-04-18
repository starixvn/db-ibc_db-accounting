CREATE PROCEDURE [NAP_Admin_PreCalculate_s161_Refund] 
	@MatchId INT
	,@Action VARCHAR(10) = 'Refund-FT' -- Refund / Refund-FT
AS
/*
	Created by: Kathy
	Date:20131212
	Task: Settlement (Refund) 
	Original SP: Admin_PreCalculate_s161_Refund
	DB: DBTXN/BODB02		

	Revisions:		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @IgnoreList VARCHAR(200)
	SET @IgnoreList = 'DB04,DB042,DB043,DB044'

	DECLARE @_xml XML, @_sXML VARCHAR(MAX)

	SET @_xml = '<root><r matchid="'+ CONVERT(VARCHAR(12), @MatchId) +'" action="'+ @Action +'" /></root>'

	SELECT @_sXML = CONVERT(VARCHAR(max), @_xml)

	EXEC dbo.Bet_ExecRep_05 @IgnoreList = @IgnoreList
		,@updatetype = 4 --refund NG
		,@_sXML = @_sXML		
END


GO

GRANT EXECUTE ON [NAP_Admin_PreCalculate_s161_Refund] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [NAP_Admin_PreCalculate_s161_Refund] TO [vnteam] AS [dbo]
GO


