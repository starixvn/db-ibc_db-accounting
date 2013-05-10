ALTER PROCEDURE [dbo].[Acc_Set_HR_SelforBill]
	@leagueid	INT,
	@raceNo		VARCHAR(5),
	@eventdate	DATETIME 
AS
/*	Creator: Phuong Dao
	Date: 2009-03-13
	Task: Display Horse Racing info for Billing
	DB: DB02.bodb02
	
	Rivisions:

*/

	SET NOCOUNT ON

	SELECT	case when o.placing = 0 then 5 else isnull(placing,5) end placing, 
			o.matchcode horseNo, 
			o.teamid Horseid , 
			o.odds,
			o.placeodds,
			o.IsSCR,
			o.IsFavor,
			o.oddsstatus eventstatus
	FROM	dbo.outright o WITH (NOLOCK)
	WHERE	o.eventdate = @eventdate 
			and o.groupmatch =LTRIM(@raceNo)
			and o.leagueid = @leagueid 
	ORDER BY placing, o.IsSCR, horseNo
	GO
	GRANT EXECUTE ON [dbo].[Acc_Set_HR_SelforBill] TO [bodbAdminNet]
	GO
	GRANT VIEW DEFINITION ON [dbo].[Acc_Set_HR_SelforBill] TO [VNTeam]

