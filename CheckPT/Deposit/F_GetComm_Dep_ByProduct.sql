USE CheckResultDB
GO 

ALTER FUNCTION [dbo].f_GetComm_Dep_ByProduct
(
	@sporttype INT=0
)
RETURNS  @tblSport  TABLE(
	Sportid INT
	)
AS
/*
	Created: 20131015@Tom.Vo	
	Task :  Retrieve comm licensee's by product 
	DB: DB052.CheckResultDB
	Original:

	Revisions:
		
	Param's Explanation:
		@sporttype: Product Id
			-1 : All
			0  : SB
			151: Racing
			161: NumberGame
			162: Live Casino
			180: Virtual Sport
			202: Keno
			251: RnG Casino		
*/
BEGIN

IF @sporttype IN (-1,0) OR @sporttype <=99 OR @sporttype = 154--Sportbooks
		BEGIN
			INSERT INTO @tblSport (Sportid)
			select sp.sporttype
			from bodb02.dbo.sports sp with (nolock)				
			where (sporttype <= 99 OR sporttype = 154)
				AND  (sporttype = @sporttype OR @sporttype IN (-1,0) )
		END

DECLARE @sporttype_old INT=@sporttype
IF @sporttype IN (-1,151) 	--Racing
		BEGIN
			SET @sporttype_old=151
			WHILE (@sporttype_old<154)
			BEGIN
				INSERT INTO @tblSport (Sportid)
				SELECT @sporttype_old
	
				SET @sporttype_old=@sporttype_old+1
			END
		END

IF @sporttype IN (-1,161) 	--NumberGame
		BEGIN			
			INSERT INTO @tblSport (Sportid)
			SELECT 161
		END

IF @sporttype IN (-1,162)  	--Live Casino
		BEGIN
			INSERT INTO @tblSport (Sportid)
			SELECT 162
		END

IF @sporttype IN (-1,180)  	--Virtual Sport
		BEGIN
			SET @sporttype_old=180
			WHILE (@sporttype_old<186)
			BEGIN
				INSERT INTO @tblSport (Sportid)
				SELECT @sporttype_old 
	
				SET @sporttype_old=@sporttype_old+1
			END
		END

IF @sporttype IN (-1,202) 	--Keno
		BEGIN
			INSERT INTO @tblSport (Sportid)
			SELECT 202
		END

IF @sporttype IN (-1,251) 	--RNG Casino
		BEGIN
			INSERT INTO @tblSport (Sportid)
			SELECT 251
		END

RETURN

END