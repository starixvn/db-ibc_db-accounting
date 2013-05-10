ALTER PROCEDURE [dbo].[Acc_BA_GroupCurrencyUpd]
	@LicenseeID INT,
	@str  VARCHAR(300),
	@ModifyBy INT,
	@Language VARCHAR(10) = 'en-us',
	@IP		  VARCHAR(40) ='',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS 
/*
Created: 20111114@Jim
Task : Update BAGroup  WHEN Currency list is Selection
DB: DBLIC/bodb_Licensee
Revisions:
	- 20111212@Henry: hardcode Alog members to just only allow group a
	- 20120208@Jim:  hardcode to change point spread for members (group a and group d)
	- 20120215@Henry: add more customer for hard-code group a
	- 20120223@Jim: add more customer for spread member (group a and group d)
	- 20120403@Jim: get SpecialCust from LicenseeSpecialCust replace for hard-code
	- 20120426@Henry: fix bug due to update wrong groupcomm in LicenseeBAHistory
    - 20130123@Daniel: Change link server alias

Param's Explanation:

*/
DECLARE @CurrencyList   AS TABLE (ID int IDENTITY(1,1),strvalue char(10))
DECLARE @CustIDList    AS TABLE (ID int IDENTITY(1,1) ,custid int )
DECLARE @SpecialCustIDList    AS TABLE (custid int,ugroup varchar(3) )
DECLARE @BACustID  AS INT	
DECLARE @i	 AS INT
DECLARE @j  AS INT 
DECLARE @custid AS INT 
DECLARE @substr	AS VARCHAR(5)
DECLARE @ugroup AS VARCHAR(3), @currency AS INT
DECLARE @1x2Comm AS DECIMAL(9,8) 
DECLARE @OtherComm AS DECIMAL(9,8) 
DECLARE @groupComm AS  decimal(9, 8),@groupComm_temp decimal(9, 8)
DECLARE @groupCommA AS  decimal(9, 8),@groupCommB AS  decimal(9, 8),@groupCommC AS  decimal(9, 8),@groupCommD AS  decimal(9, 8)




SET @str = LTRIM(RTRIM(@str))
BEGIN
	IF (@str='')
		BEGIN
			SELECT @ErrMsg=CASE @Language
							WHEN 'en-us' THEN N'Please check data again !'
							WHEN 'zh-cn' THEN N'Please check data again !'
							WHEN 'zh-tw' THEN N'Please check data again !'
							WHEN 'TH'    THEN N'Please check data again !'
							WHEN 'Ja'    THEN N'Please check data again !'
							WHEN 'KO'    THEN N'Please check data again !'
							ELSE N'Please check data again !'
							END, @ErrCode = 101
							RETURN
		END
	ELSE
		BEGIN	
			--Get GroupComm
			SELECT @groupCommA= l.groupa , @groupCommB = l.groupb,@groupCommC = l.groupc, @groupCommD = l.groupd
			FROM LicenseeBAConfig l WITH (NOLOCK)
			WHERE l.LicenseeID=@LicenseeID 
		
		
			INSERT INTO @SpecialCustIDList(CustID,ugroup)
			SELECT  custid,ugroup FROM LicenseeSpecialCust (NOLOCK) 
			
			INSERT @CurrencyList(strvalue)  SELECT VAL FROM strSplit(@str,',')
			SET @i=1
			WHILE (@i<=(SELECT MAX(ID) FROM @CurrencyList))
			BEGIN	 
				SELECT @substr = strvalue from @CurrencyList WHERE ID=@i
				SELECT @ugroup = LEFT(@substr,1), @currency = CONVERT(INT,substring(@substr,2,len(@substr)-1))
				IF NOT EXISTS(SELECT 1 FROM LicenseeCurrencyBAGroup WITH (NOLOCK) WHERE LicenseeID = @LicenseeID AND Currency= @currency)
				BEGIN
					INSERT INTO LicenseeCurrencyBAGroup(LicenseeID,Currency,ugroup,ModifyBy,ModifyDate)
						VALUES (@LicenseeID,@currency,@ugroup,@ModifyBy,GETDATE())
						
					INSERT INTO UserLog_LicenseeCurrencyBAGroup
					Select @LicenseeID,@currency,@ugroup,@ModifyBy,GETDATE(),@IP
				END
				ELSE
				BEGIN
					--Check ugroup, if not exist then update
					IF NOT EXISTS(SELECT 1 FROM LicenseeCurrencyBAGroup WITH (NOLOCK) WHERE LicenseeID = @LicenseeID AND Currency= @currency AND ugroup=@ugroup)
					BEGIN
						SELECT @1x2Comm=[1x2Comm],@OtherComm=[OtherComm],
							   @groupComm=CASE  WHEN @ugroup='a' THEN groupa 
												WHEN @ugroup='b' THEN groupb
												WHEN @ugroup='c' THEN groupc
												WHEN @ugroup='d' THEN groupd ELSE '' END 					
						FROM LicenseeBAConfig WITH (NOLOCK) 
						WHERE LicenseeID=@LicenseeID
									
						UPDATE LicenseeCurrencyBAGroup WITH (ROWLOCK,UPDLOCK)
						SET ugroup = @ugroup
						WHERE LicenseeID = @LicenseeID AND Currency= @currency
									
						INSERT @CustIDList(custid) 
						SELECT 
							lba.CustID 
						FROM LicenseeBAHistory lba WITH (NOLOCK)
							INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON lba.custid = c.custid
						WHERE
							LicenseeID=@LicenseeID AND Status = 'Running' AND c.currency = @currency
							
						SET @j=1
						WHILE (@j <= (SELECT max(ID) FROM @CustIDList))
						BEGIN
							SELECT @groupComm_temp = @groupComm --initial
						
							SELECT @BACustID=CustID FROM @CustIDList  WHERE ID=@j
							--- Update commission for BA Member
							EXEC DBTXN.bodb02.dbo.[Lrf_CustomerUpdMemberBAComm]
								@LicenseeID=@LicenseeID,
								@custid=@BACustID,
								@ModifyBy=@ModifyBy,
								@IsBA=1,
								@IP=@IP,
								@IsAdmin=1,
								@ErrCode = @ErrCode OUTPUT,
								@ErrMsg = @ErrMsg OUTPUT
								
							IF EXISTS (SELECT 1 FROM @SpecialCustIDList WHERE CustID = 	@BACustID)
							BEGIN
								SELECT 
									@groupComm_temp=CASE  WHEN ugroup='a' THEN @groupCommA 
													 WHEN ugroup='b' THEN @groupCommB
													 WHEN ugroup='c' THEN @groupCommC
													 WHEN ugroup='d' THEN @groupCommD ELSE '' END 					
								FROM @SpecialCustIDList WITH (NOLOCK) 
								WHERE CustID = 	@BACustID		
							END
							
							UPDATE LicenseeBAHistory WITH (ROWLOCK,UPDLOCK)
							SET 
								GroupComm=@groupComm_temp,[1X2Comm]=@1x2Comm,[OtherComm]=@OtherComm
							WHERE	
								LicenseeID = @LicenseeID AND
								CustID = @BACustID AND
								Status = 'Running'
								
							SET @j=@j+1	
						END	
																			
						INSERT INTO UserLog_LicenseeCurrencyBAGroup
						Select @LicenseeID,@currency,@ugroup,@ModifyBy,GETDATE(),@IP
																			
						DELETE FROM @CustIDList
					END
				END
				SET @i=@i+1		
			END
		END
	END	

GO
GRANT EXECUTE ON [dbo].[Acc_BA_GroupCurrencyUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_BA_GroupCurrencyUpd] TO [vnteam] 


