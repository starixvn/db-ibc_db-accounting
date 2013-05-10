ALTER PROCEDURE [dbo].[Server_Check_CpuUtilization]
	@pCPU tinyint OUTPUT
AS
/*
	Created by:[Viet]
	Date:[20121109]
	Task: Check CPU 
	DB: DBTrans.bodb02, DB052.bodb02, DB053.bodb02, DB06.bodb02
	
	Revisions:		
*/
SET NOCOUNT ON
	declare @cpu_busy int, @idle int
	select @cpu_busy = @@cpu_busy, @idle = @@idle

	WAITFOR DELAY '000:00:00.050' 

	BEGIN TRY
		SELECT @pCPU = convert(tinyint,(@@CPU_BUSY - @cpu_busy)*@@TIMETICKS/((@@IDLE - @idle + @@CPU_BUSY - @cpu_busy) * CAST(@@TIMETICKS AS FLOAT))*100)  
	END TRY
	BEGIN CATCH
		-- in case divide by zero error encountered
		WAITFOR DELAY '000:00:00.100'
		SELECT @pCPU = convert(tinyint,(@@CPU_BUSY - @cpu_busy)*@@TIMETICKS/((@@IDLE - @idle + @@CPU_BUSY - @cpu_busy) * CAST(@@TIMETICKS AS FLOAT))*100)  
	END CATCH
SET NOCOUNT OFF
