DECLARE @ABS TABLE(rn int , oldname nvarchar(50),newname nvarchar(50))

INSERT INTO @ABS (rn,oldname,newname)
SELECT 1,'ABS001','ABSJOHN'
UNION SELECT 2,'ABS002','ABSCK'
UNION SELECT 3,'ABS003','ABSMK'
UNION SELECT 4,'ABS004','ABSMICHAEL'
UNION SELECT 5,'ABS005','ABSYEN'
UNION SELECT 6,'ABS006','ABSONN'
UNION SELECT 7,'ABS007','ABSLOON'
UNION SELECT 8,'ABS008','ABSBOONLAY'
UNION SELECT 9,'ABS009','ABSCHIN'
UNION SELECT 10,'ABS010','ABSLHUGO'
UNION SELECT 11,'ABS011','SSGIB'
UNION SELECT 12,'ABS012','SSDANIEL'
UNION SELECT 13,'ABS013','SSCAMELL'

DECLARE @oldname nvarchar(50), @newname nvarchar(50), @i int,
		@ErrCode int, @ErrMsg nvarchar(200), @userid int

select @userid = 1948903-- dbaJamie
--
SELECT @i = 1

WHILE @i <=13
BEGIN
	SELECT @oldname = oldname,@newname = newname
	FROM @ABS
	WHERE rn = @i

	EXEC Acc_CustomerUpdUserName @oldname = @oldname, @newname = @newname, @userid = @userid, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrCode as ErrCode, @ErrMsg as ErrMsg,@oldname as oldname_fail, @newname as newname
		BREAK;		
	END
	ELSE		
		SELECT @i = @i + 1
	
	WAITFOR DELAY '0:00:01'
			
END
-------------------------
--INACTIVE some ABS's users not use
DECLARE @ABS TABLE (rn int, custid int)

INSERT INTO @ABS(rn,custid)
SELECT 1, 5452637 --ABS014
UNION SELECT 2, 5452639 --ABS015
UNION SELECT 3, 5519908 --ABS016
UNION SELECT 4, 5519911 --ABS017
UNION SELECT 5, 5519914 --ABS018
UNION SELECT 6, 5519916 --ABS019
UNION SELECT 7, 5519917 --ABS020
UNION SELECT 8, 5519919 --ABS021
UNION SELECT 9, 5519921 --ABS022
UNION SELECT 10,5519922 --ABS023
UNION SELECT 11,5519924 --ABS024
UNION SELECT 12,5519926 --ABS025
UNION SELECT 13,5848823 --ABS026
UNION SELECT 14,6081162 --ABSJackyTING

DECLARE @custid int, @userid int, @i int, @ErrCode int , @ErrMsg nvarchar(200)

SELECT @i = 1, @userid = 1948903-- dbaJamie

WHILE @i <= 14
BEGIN
	SELECT @custid = custid FROM @ABS WHERE rn = @i
	
	EXEC Acc_Con_AdminUpdClosed @CustID=@custid,@Closed=1,@UserID=@userid,@isABS=1,@ErrCode=@errcode output,@ErrMsg=@ErrMsg output

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrCode as ErrCode, @ErrMsg as ErrMsg, @custid as custid
		BREAK;
	END
	ELSE 
		SELECT @i = @i + 1
		
	WAITFOR DELAY '0:00:01'
END