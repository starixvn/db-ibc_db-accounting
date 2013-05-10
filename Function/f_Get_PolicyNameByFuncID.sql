 /****** Object:  UserDefinedFunction [dbo].[f_Get_PolicyNameByFuncID]    Script Date: 05/26/2011 10:02:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[f_Get_PolicyNameByFuncID]
 (@FuncID INT)  
RETURNS NVARCHAR(500) AS  
/*
Created: 20110526:TOM
Task : Get Policy Name by FuncID in User Control 
DB: DB03.bodb02
 
*/
BEGIN 

	declare @returnVal nvarchar(500)

	select  @returnVal=FuncDesc from dbo.Acc_FunctionInfo with(nolock)
	Where FuncID=@FuncID
	
	Return IsNull(@returnVal,'FuncID:'+convert(nvarchar(100),@FuncID))

END

GO
GRANT VIEW DEFINITION ON [dbo].[f_Get_PolicyNameByFuncID] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[f_Get_PolicyNameByFuncID] TO [bodbAdminNet]