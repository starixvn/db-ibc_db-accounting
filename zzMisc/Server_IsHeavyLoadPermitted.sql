ALTER PROCEDURE [dbo].[Server_IsHeavyLoadPermitted]
	@isPermit bit OUTPUT
AS
/*
	Created by:[Viet]
	Date:[20121109]
	Task: 
	DB: DBTrans.bodb02, DB052.bodb02, DB053.bodb02, DB06.bodb02
	
	Revisions:		
*/
SET NOCOUNT ON
	SET @isPermit = 1
	
	declare @pCPU tinyint
	EXEC dbo.Server_Check_CpuUtilization @pCPU = @pCPU OUTPUT

	IF @pCPU < 65 RETURN -- it's ok
	
	-- if cpu >= 65%, check again
	WAITFOR DELAY '000:00:00.050' 
	EXEC dbo.Server_Check_CpuUtilization @pCPU = @pCPU OUTPUT
	IF @pCPU < 65 RETURN -- it's ok
	
	-- > 65% again, don't allow to run
	SET @isPermit = 0  
SET NOCOUNT OFF

GO
GRANT EXECUTE ON [dbo].[Server_IsHeavyLoadPermitted] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Server_IsHeavyLoadPermitted] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Server_IsHeavyLoadPermitted] TO [bodbDownlineNetView] AS [dbo]