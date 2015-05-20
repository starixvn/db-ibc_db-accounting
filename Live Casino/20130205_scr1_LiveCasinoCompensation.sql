


/*
	refund mistake game
*/

DECLARE @matchid INT,
		@adminID INT

SELECT  @matchid = ,
		@adminID = 5067934   -- Livecasino

declare @ErrCode int,
		@ErrMsg nvarchar(200)

exec [dbo].[Admin_Settlement_s162]
	@matchid = @matchid,
	@action = 'Refund', -- CAL  / Refund 
	@AdminID = @adminID, 
	@betstatus ='',
	@CardsResult = '',
	@IP = '' ,
	@CommRate = 0.05,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg  = @ErrMsg OUTPUT
select @ErrCode, @ErrMsg


