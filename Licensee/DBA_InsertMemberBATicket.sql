ALTER PROCEDURE [dbo].[DBA_InsertMemberBATicket]
	@LicenseeID INT,
	@username varchar(50)='',
	@custid INT=0,
	@IsUpdateBAOnDate BIT = 0,
	@IsTurnOnBA BIT = 0,
	@IsUpdatePT BIT = 0
	
AS
/*
	Created by: [20111117@Henry]
	Task: Insert Member BA Ticket (Dela problem)
	DB: DBLIC/bodb_Licensee
	
	Revisions:
    - 20130123@Daniel: Change link server alias
	
*/
DECLARE @recommend INT, @TransDate DATETIME

SET @username = RTRIM(LTRIM(@username))
	
IF NOT EXISTS(SELECT 1 FROM	LicenseeBAConfig (NOLOCK) WHERE LicenseeID = @LicenseeID AND EnableBA = 1)
BEGIN
	print 'This licensee is not offer BA yet!'
	RETURN
END

IF @username='' AND @custid=0
BEGIN
	print 'Please input username or custid!'
	return
END

IF @username <> ''
BEGIN
	SELECT @CustID = CustID, @recommend = Recommend FROM bodb02.dbo.Customer c WITH (NOLOCK)
	WHERE Username=@Username AND roleid = 1
END
ELSE
BEGIN
	SELECT @recommend = Recommend FROM bodb02.dbo.Customer c WITH (NOLOCK)
	WHERE CustID=@CustID AND roleid = 1
END


IF ISNULL(@CustID,0) = 0
BEGIN
	print 'This member''s username does not exist!'
	RETURN
END

IF NOT EXISTS(SELECT 1 FROM LicenseeCust (NOLOCK) WHERE LicenseeID = @LicenseeID AND custid = @recommend AND RoleID = 2)
BEGIN
	print 'This member does not belong to Licensee!'
	RETURN
END

--Turn On BA member
IF @IsTurnOnBA = 1
BEGIN
	IF NOT EXISTS(
		SELECT 1 FROM [LicenseeBAHistory] WITH (NOLOCK)
		WHERE 
			[LicenseeID] = @LicenseeID AND
			[CustID] = @CustID AND
			[Status] = 'Running'
			
	)
	BEGIN
		DECLARE @ErrCode int,
		@ErrMsg nvarchar(2000)
		SET @ErrMsg=''
		SET @ErrCode=0
		
		IF (SELECT EnableBA FROM bodb_licensee.dbo.LicenseeBAConfig WITH (NOLOCK) WHERE LicenseeID = @LicenseeID) = 1
		BEGIN
			EXEC DBTXN.bodb02.dbo.[Lrf_CustomerUpdMemberBAStatus]
				@LicenseeID=@LicenseeID,
				@CustID = @CustID,
				@ModifyBy = 1, --dbaThien
				@IsBA = 1,
				@IP = '',
				@ErrCode = @ErrCode OUTPUT,
				@ErrMsg = @ErrMsg OUTPUT
		END
		IF @ErrCode<>0
		BEGIN
			PRINT @ErrMsg
			RETURN
		END
	END
	
END


--Update ondate 
IF @IsUpdateBAOnDate=1
BEGIN
	IF EXISTS(
			SELECT 1 FROM [LicenseeBAHistory] WITH (NOLOCK)
			WHERE 
				[LicenseeID] = @LicenseeID AND
				[CustID] = @CustID AND
				[Status] = 'Running' 
		)
	BEGIN
		
		SELECT  @transdate=MIN(transdate) FROM DBARC.bodb_archive.dbo.bettrans_bk WITH(nolock)
		WHERE custid = @custid and (bettype <31 OR bettype BETWEEN 121 AND 999) AND tpositiontaking=0
		
		IF ISNULL(@transdate,'') = ''
		BEGIN
			SELECT  @transdate=MIN(transdate) FROM bodb02.dbo.bettrans14 WITH(nolock,INDEX=bettrans1423)
			WHERE custid = @custid and (bettype <31 OR bettype BETWEEN 121 AND 999) AND tpositiontaking=0
		END

		IF ISNULL(@transdate,'') = ''
		BEGIN
			SELECT  @transdate=MIN(transdate) FROM bodb02.dbo.bettrans WITH(nolock,INDEX=IX_custid_matchid_bettype)
			WHERE custid = @custid and (bettype <31 OR bettype BETWEEN 121 AND 999) AND tpositiontaking=0
		END

		IF ISNULL(@transdate,'') <> ''
		BEGIN
			SELECT @transdate=DATEADD(MINUTE,-5,@transdate)
		END
		ELSE
		BEGIN
			SELECT @transdate = creatdate FROM bodb02.dbo.customer (nolock) WHERE custid = @custid
		END

		update bodb_licensee.dbo.licenseebahistory with (rowlock,updlock)
		set OnDate = @transdate
		where 
			licenseeID = @LicenseeID
			and custid = @CustID
			and status = 'Running'
	END
END

IF @IsUpdatePT=1
BEGIN
	UPDATE DBTXN.bodb02.dbo.bettrans WITH (ROWLOCK,UPDLOCK)
	SET tpositiontaking=0,
		apositiontaking=0,
		awinlost=0
	WHERE 
		custid = @CustID
		and (bettype <31 or bettype between 121 AND 999)
		and tpositiontaking<>0
END

--bettrans
insert into licenseebatransaction (transid,transdate)
select 
	b.transid,b.transdate 
from  bodb02.dbo.bettrans b with (nolock,index=IX_CustID_matchid_bettype)
	left join Licenseebatransaction  ba (nolock) on b.transid = ba.transid
where custid = @CustID
and bettype < 19000
and (bettype <31 or bettype between 121 AND 999)
and tpositiontaking = 0
and isnull(ba.transid,0) = 0

--bettrans14
insert into licenseebatransaction (transid,transdate)
select 
	b.transid,b.transdate 
from  bodb02.dbo.bettrans14 b with (nolock,index=bettrans1413)
	left join Licenseebatransaction  ba (nolock) on b.transid = ba.transid
where custid = @CustID
and bettype < 19000
and (bettype <31 or bettype between 121 AND 999)
and tpositiontaking = 0
and isnull(ba.transid,0) = 0

GO
GRANT EXECUTE ON [dbo].[DBA_InsertMemberBATicket] TO [vnteam] 