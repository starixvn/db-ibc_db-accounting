 /*<info serverAlias="DBTXN-bodb02,DBCUST-CustDB" executers="" isFunction="1"></info>*/
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
	DB: DBTRANS-bodb02,DBCUST-CustDB

	Revisions:
	- 20110624@Tom: Change DB02 to DBTRANS (Splitting DB02 to DBPros and DBTRANS)
	- 20181204@Phillip: Deploy to DBCUST [RedmineID: #104848] 
*/
BEGIN 
	
	declare @returnVal nvarchar(500)

	Select @returnVal=username from [dbo].[custinfo] with(nolock)
	Where custid=@CustID 

	Return @returnVal

END