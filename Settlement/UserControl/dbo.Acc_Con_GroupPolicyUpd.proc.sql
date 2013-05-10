ALTER PROCEDURE [dbo].[Acc_Con_GroupPolicyUpd]
	@GroupPolicys NVARCHAR(4000),
	@UserID int, 
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@System varchar(50)='ACCOUNTING'
AS
-- Update Acc_GroupPolicy
-- Format of @GroupPolicys: @GroupID,@FuncID,@Policy;@GroupID,@FuncID,@Policy; ...;
	SET NOCOUNT ON
	
--Check permission for account site: @phuc20080213
EXEC dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UserControl]',@System=@System,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end
	
	
	DECLARE @GroupPolicy nvarchar(4000)
	DECLARE @GroupID INT
	DECLARE @FuncID INT
	DECLARE @Policy int
	DECLARE @GroupPolicyCount int 
	DECLARE GroupPolicysCur CURSOR FOR 
		SELECT val as row_index 
		  FROM dbo.strSplit(@GroupPolicys, ';')
		 ORDER BY row_index
	
	OPEN GroupPolicysCur
	FETCH NEXT FROM GroupPolicysCur INTO @GroupPolicy
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @GroupID = dbo.Acc_SplitIndex(@GroupPolicy, ',', 1)
		SET @FuncID = dbo.Acc_SplitIndex(@GroupPolicy, ',', 2)
		SET	@Policy = dbo.Acc_SplitIndex(@GroupPolicy, ',', 3)
		SET @GroupPolicyCount = (SELECT COUNT(1) FROM Acc_GroupPolicy_1 with (nolock) WHERE GroupID = @GroupID AND funcid = @FuncID)

		IF(@GroupPolicyCount = 0)
			BEGIN
				INSERT INTO Acc_GroupPolicy_1 
					(GroupID, Funcid, Policy, Createdate, Modifydate, Creator)
				Values
					(@GroupID, @Funcid, @Policy, CURRENT_TIMESTAMP,CURRENT_TIMESTAMP, @UserID)
			END
		ELSE
			BEGIN
				UPDATE Acc_GroupPolicy_1
				   SET policy = @Policy,
					 modifydate = CURRENT_TIMESTAMP
				 WHERE GroupID = @GroupID
				   AND funcid = @FuncID
			END
		
		declare @LogData nvarchar(300)	
		Select @LogData = '[' + @System + '] UPDATE (multiple) Policy = ' + convert(varchar(10), @Policy) + ' of Function ' + convert(varchar(10), @Funcid) +  ' for Group ' + convert(varchar(10), @GroupID)
				
		EXEC LOG.bodb02.dbo.WriteLog_UserLog @UserID = @UserID, @Doing = @LogData

		FETCH NEXT FROM GroupPolicysCur INTO @GroupPolicy
	END 
	CLOSE GroupPolicysCur
	DEALLOCATE GroupPolicysCur
	
	


GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_GroupPolicyUpd] TO [vnteam]
go
GRANT EXECUTE ON [dbo].[Acc_Con_GroupPolicyUpd] TO [bodbAdminNet]