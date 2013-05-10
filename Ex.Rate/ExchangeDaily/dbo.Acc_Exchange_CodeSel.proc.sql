CREATE PROCEDURE [dbo].[Acc_ExchangeCodeSel]
AS
/*
Created: Henry
Task : Get the list of Code need to get the exchange rate
DB: DB052.BODB02 
Revisions:
*/		
	SET NOCOUNT ON

	SELECT DISTINCT Code FROM exchange WITH (nolock)
	WHERE isnull(Code,'') <> ''

GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeCodeSel] TO [bodbAdminNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeCodeSel] TO [vnteam]