 /****** Object:  UserDefinedFunction [dbo].[f_CustNameByCustID] Script Date: 05/26/2011 10:02:37 ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[f_Get_CustNameByCustID]
 (@CustID INT)  
RETURNS NVARCHAR(500) AS  
/*
Created:   20110526:TOM
Task : Get Customer Name by CustID in User Control 
DB: DBTRANS.bodb02

Revisions:
- 20110624@Tom: Change DB02 to DBTRANS (Splitting DB02 to DBPros and DBTRANS)
*/
BEGIN 
	
	declare @returnVal nvarchar(500)

	Select @returnVal=username from [dbo].[custinfo] with(nolock)
	Where custid=@CustID 

	Return @returnVal

END
GO
GRANT VIEW DEFINITION ON [dbo].[f_Get_CustNameByCustID] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[f_Get_CustNameByCustID] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[f_Get_CustNameByCustID] TO [bodbExtAccNet]