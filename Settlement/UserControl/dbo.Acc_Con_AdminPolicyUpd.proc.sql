ALTER PROCEDURE [dbo].[Acc_Con_AdminPolicyUpd]
	@MemPolicys NVARCHAR(4000),
	@UserID int, 
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@System varchar(50)='ACCOUNTING'
AS
-- Update Acc_GroupPolicy
-- Format of @MemPolicys @CustID,@FuncID,@Policy;@CustID,@FuncID,@Policy; ...;
SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UserControl]',@System=@System,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end



DECLARE @MemPolicy nvarchar(4000)
DECLARE @CustID INT
DECLARE @FuncID INT
DECLARE @Policy int
DECLARE @CustPolicyCount int 
DECLARE CustPolicysCur CURSOR FOR 
	SELECT val as row_index 
	  FROM dbo.strSplit(@MemPolicys, ';')
	 ORDER BY row_index
	 


OPEN CustPolicysCur
FETCH NEXT FROM CustPolicysCur INTO @MemPolicy
WHILE @@FETCH_STATUS = 0
BEGIN

	SET @CustID = dbo.Acc_SplitIndex(@MemPolicy, ',', 1)
	SET @FuncID = dbo.Acc_SplitIndex(@MemPolicy, ',', 2)
	SET	@Policy = dbo.Acc_SplitIndex(@MemPolicy, ',', 3)
	SET @CustPolicyCount = (SELECT COUNT(1) FROM Acc_MemberPolicy_1 with (nolock) WHERE CustID = @CustID AND funcid = @FuncID)

	IF(@CustPolicyCount = 0)
		BEGIN
			INSERT INTO Acc_MemberPolicy_1 
				(CustID, Funcid, Policy, Createdate, Modifydate, Creator)
			Values
				(@CustID, @Funcid, @Policy, CURRENT_TIMESTAMP,CURRENT_TIMESTAMP, @UserID)
		END
	ELSE
		BEGIN
			UPDATE Acc_MemberPolicy_1
			   SET policy = @Policy,
				 modifydate = CURRENT_TIMESTAMP
			 WHERE CustID = @CustID
			   AND funcid = @FuncID
		END
		
	declare @LogData nvarchar(300)	
	Select @LogData ='[' + @system + ']' + ' UPDATE (multiple) Policy = ' + convert(varchar(10), @Policy) + ' of Function ' + convert(varchar(10), @Funcid) +  ' for Admin ' + convert(varchar(10), @CustID)
	EXEC LOG.bodb02.dbo.WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
		

	FETCH NEXT FROM CustPolicysCur INTO @MemPolicy
END 
CLOSE CustPolicysCur
DEALLOCATE CustPolicysCur




GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminPolicyUpd] TO [vnteam]
go
GRANT EXECUTE ON [dbo].Acc_Con_AdminPolicyUpd TO [bodbAdminNet]