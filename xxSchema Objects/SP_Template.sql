CREATE PROCEDURE  [dbo].[Stored_Procedure_Name]
	@parameter1 int = 5,
	@parameter2 datatype OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
Created: 20090122@[creator]
Task : [description of SP]
DB: DB02.bodb02
Original:

Revisions:
	- 20090122@[Reviewer]: [Description of revision]	

Param's Explanation:
• @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Specific Error.
	
• @ErrMsg: Error description.
*/
SET NOCOUNT ON
--CONTENT OF SP HERE

GO
GRANT EXECUTE ON [dbo].[Stored_Procedure_Name] TO [bodb..]
GO
GRANT VIEW DEFINITION ON [dbo].[Stored_Procedure_Name] TO [vnteam]
GO