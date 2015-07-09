ALTER Procedure [dbo].[Dot_Casino_CustomerSelInfo]
	@UserName varchar(30),
	@MaxCustid int
AS
/*
Created: 20090919
Task : Select all customers does not sync Casino
DB: DB052.bodb02

Revisions:
    - 20091021@[HanhVu]: Remove condition Closed=0

Param's Explanation:
• @Username = '' will select all external supers.
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
		co.Credit,
		co.SyncCasino,
		co.DisableCasino
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
		co.Credit,
		co.SyncCasino,
		co.DisableCasino
	FROM CustInfo co with (nolock) 
	INNER JOIN Customer c with (nolock) on co.custid=c.custid
	WHERE c.srecommend=@CustID 
		and Enabled=1       
		and co.custid<=@MaxCustid
	
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
		co.Credit,
		co.SyncCasino,
		co.DisableCasino		
	FROM CustInfo co with (nolock) 
	INNER JOIN Customer c with (nolock) on co.custid=c.custid
	WHERE c.mrecommend=@CustID 
		and Enabled=1      
		and co.custid<=@MaxCustid
	
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
		co.Credit,
		co.SyncCasino,
		co.DisableCasino
	FROM CustInfo co with (nolock) 
	INNER JOIN Customer c with (nolock) on co.custid=c.custid
	WHERE c.recommend=@CustID 
		and Enabled=1       
		and co.custid<=@MaxCustid
	
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
		co.Credit,
		co.SyncCasino,
		co.DisableCasino
	FROM CustInfo co with (nolock) 
	INNER JOIN Customer c with (nolock) on co.custid=c.custid
	WHERE c.CustID=@CustID 
		and Enabled=1      
		and co.custid<=@MaxCustid
	
GO
GRANT EXECUTE ON [dbo].[Dot_Casino_CustomerSelInfo] TO [Dot_Casino]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Casino_CustomerSelInfo] TO [vnTeam]