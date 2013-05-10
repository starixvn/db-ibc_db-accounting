
ALTER PROCEDURE [dbo].[Acc_MailingListSel] 
	@FuncID int = 287  -- [SpecialDeleteMailing]
AS 
/*    
	Created by: Scott    
	Date: 2013-01-08  
	Task : select Mailing list  
	DB: DBACC/BODB_ACC
	Original SP:     
	
	Revisions:   
		- 20130305@Lukas: move SP to bodb_acc
		- 20130306@Lukas: modify to get licensees in case of no data for specific function ID
*/    
BEGIN 

	SET NOCOUNT ON  

	SELECT a.siteid, a.site,b.tolist,b.cclist,b.bcclist,
	CASE WHEN tolist IS NOT NULL OR cclist IS NOT NULL OR bcclist IS NOT NULL THEN 1 ELSE 0 END isavailabe  
	FROM bodb02.dbo.[site] a WITH(NOLOCK)
		INNER JOIN [Acc_MailingList] b  WITH(NOLOCK) on a.siteid = b.siteid  
	WHERE a.islicensee= 1 and b.funcid = @FuncID
	UNION  --- not union all
	SELECT a.siteid, a.site,b.tolist,b.cclist,b.bcclist,
	CASE WHEN tolist IS NOT NULL OR cclist IS NOT NULL OR bcclist IS NOT NULL THEN 1 ELSE 0 END isavailabe  
	FROM bodb02.dbo.[site] a WITH(NOLOCK)
		LEFT JOIN ( SELECT *
					FROM [Acc_MailingList] WITH(NOLOCK)
					WHERE funcid = @FuncID
				  ) b ON a.siteid = b.siteid
	WHERE a.islicensee= 1 AND b.funcid IS NULL
      
END  
 

go

/*
==========Execute sample=================  
Acc_MailingListSel   
*/
  
GRANT EXECUTE ON [dbo].[Acc_MailingListSel] TO [bodbAdminNet]
go
GRANT VIEW DEFINITION ON [dbo].[Acc_MailingListSel] TO [vnteam]
go