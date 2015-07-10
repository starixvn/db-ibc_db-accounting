USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Dot_MiniGame_CustomerSelInfo]    Script Date: 04/17/2010 15:18:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER Procedure [dbo].[Dot_MiniGame_CustomerSelInfo]
	@UserName varchar(30),
	@MaxCustid int
AS
/*
Created: 20090919
Original: Dot_Casino_CustomerSelInfo created by Amy
Task : Select inf of all customers under username
DB: DB052.bodb02

Revisions:
	- 20100416@Daniel: Added

Param's Explanation:
• @Username = '': Get info of all all supers.
• @Username = 'ABC': Get info of account 'ABC' and his downlines

*/

if @UserName = ''
BEGIN
    SELECT 
		co.Custid as IBCCustID,
		co.Username,
		c.Username2,
		c.FirstName,
		c.LastName,
		c.UserPwd,
		c.Phone,
		c.MobilePhone,
		co.Currency as IBCExchangeID,
		c.Fax,
		co.Closed,
		co.reject as Suspend,
		c.srecommend as SIBCCustID,
		c.mrecommend as MIBCCustID,
		c.recommend as AIBCCustID,
		c.RoleId,
		co.Credit
	FROM CustInfo co with (nolock) 
	INNER JOIN Customer c with (nolock) on co.custid=c.custid
	WHERE c.roleid = 4
	    and Enabled=1
	    and co.custid not in (689422,--SSP
	                          1533014) --ISPO
	    and co.currency not in (16, --YEN
                                17, --NTD
                                35, --$US
                                40, --IRR
                                36 --Y$US
                            )
        and co.username not like 'MS88%'
        and co.username not like 'AB88%'
        and co.username not like '3rdSuper%'
        and co.custid<=@MaxCustid                       
	   
    RETURN	                            
END

Declare @RoleID int, @CustID int

SELECT @RoleID=	roleid, @CustID=custid FROM CustInfo with (nolock) WHERE username=@UserName

IF @RoleID=4
	SELECT 
		co.Custid as IBCCustID,
		co.Username,
		c.Username2,
		c.FirstName,
		c.LastName,
		c.UserPwd,
		c.Phone,
		c.MobilePhone,
		co.Currency as IBCExchangeID,
		c.Fax,
		co.Closed,
		co.reject as Suspend,
		c.srecommend as SIBCCustID,
		c.mrecommend as MIBCCustID,
		c.recommend as AIBCCustID,
		c.RoleId,
		co.Credit
	FROM CustInfo co with (nolock) 
	INNER JOIN Customer c with (nolock) on co.custid=c.custid
	WHERE c.srecommend=@CustID
		and Enabled=1       
		and co.custid<=@MaxCustid
	ORDER BY c.RoleId DESC
	
ELSE IF @RoleID=3
	SELECT 
		co.Custid as IBCCustID,
		co.Username,
		c.Username2,
		c.FirstName,
		c.LastName,
		c.UserPwd,
		c.Phone,
		c.MobilePhone,
		co.Currency as IBCExchangeID,
		c.Fax,
		co.Closed,
		co.reject as Suspend,
		c.srecommend as SIBCCustID,
		c.mrecommend as MIBCCustID,
		c.recommend as AIBCCustID,
		c.RoleId,
		co.Credit
	FROM CustInfo co with (nolock) 
	INNER JOIN Customer c with (nolock) on co.custid=c.custid
	WHERE c.mrecommend=@CustID
		and Enabled=1      
		and co.custid<=@MaxCustid
	ORDER BY c.RoleId DESC
	
ELSE IF @RoleID=2
	SELECT 
		co.Custid as IBCCustID,
		co.Username,
		c.Username2,
		c.FirstName,
		c.LastName,
		c.UserPwd,
		c.Phone,
		c.MobilePhone,
		co.Currency as IBCExchangeID,
		c.Fax,
		co.Closed,
		co.reject as Suspend,
		c.srecommend as SIBCCustID,
		c.mrecommend as MIBCCustID,
		c.recommend as AIBCCustID,
		c.RoleId,
		co.Credit
	FROM CustInfo co with (nolock) 
	INNER JOIN Customer c with (nolock) on co.custid=c.custid
	WHERE c.recommend=@CustID
		and Enabled=1       
		and co.custid<=@MaxCustid
	ORDER BY c.RoleId DESC
	
ELSE
	SELECT 
		co.Custid as IBCCustID,
		co.Username,
		c.Username2,
		c.FirstName,
		c.LastName,
		c.UserPwd,
		c.Phone,
		c.MobilePhone,
		co.Currency as IBCExchangeID,
		c.Fax,
		co.Closed,
		co.reject as Suspend,
		c.srecommend as SIBCCustID,
		c.mrecommend as MIBCCustID,
		c.recommend as AIBCCustID,
		c.RoleId,
		co.Credit
	FROM CustInfo co with (nolock) 
	INNER JOIN Customer c with (nolock) on co.custid=c.custid
	WHERE c.CustID=@CustID 
		and Enabled=1      
		and co.custid<=@MaxCustid
	


GO
GRANT EXECUTE ON [dbo].[Dot_MiniGame_CustomerSelInfo] TO [Dot_Casino]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_MiniGame_CustomerSelInfo] TO [vnteam]