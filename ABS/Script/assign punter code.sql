/*
	Created: Johnson
	DB:DB052.BODB02
*/ 

DECLARE @tmpUser TABLE(adminID INT)
DECLARE @tmpFunction TABLE (funcid INT)
DECLARE @groupid INT, @isCopy BIT

SELECT @groupid = groupid FROM DB03.BODB02.dbo.Acc_GroupInfo_1 WITH(NOLOCK) WHERE GroupName = 'ABS'


INSERT INTO @tmpFunction (funcid)
SELECT FuncID from DB03.BODB02.dbo.Acc_FunctionInfo WITH(NOLOCK) 
WHERE FuncName IN ('[ABSBetListInstantRecord]',
'[ABSReportInstantReport]',
'[ABSReportSummary]',
'[ABSReportEMFT]',
'[ABSCustomerManegement]',
'[ABSAdminUserControl]'
)

IF EXISTS (SELECT 1
			FROM DB03.BODB02.dbo.Acc_GroupPolicy_1 WITH(NOLOCK) 
			WHERE groupid = @groupID AND funcID IN (SELECT funcid FROM @tmpFunction)
				AND policy > 0)
	SELECT @isCopy = 1
ELSE SELECT @isCopy = 0

INSERT INTO @tmpUser(adminid)
SELECT DISTINCT CustID
FROM DB03.BODB02.dbo.Acc_MemberPolicy_1 WITH(NOLOCK)
WHERE FuncID IN (SELECT FuncID FROM @tmpFunction)
AND Policy > 0

IF @isCopy = 1
INSERT INTO @tmpUser(adminid)
SELECT custid
FROM DB03.BODB02.dbo.accCustomer_1 WITH(NOLOCK)
WHERE groupID = @groupID 
	AND custid NOT IN (SELECT adminID FROM @tmpUser)

INSERT INTO ABPunterGroup (adminid,punterid)
SELECT adminID,punterid
FROM @tmpUser,ABPunterCode
where enabled = 1
