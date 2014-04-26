ALTER PROCEDURE [Admin_Calculate_RefundFGLG_External] 
(
	@matchid	int,
	@action varchar(10) = 'CAL',
	@LGOnly		bit,
	@matchdate	datetime
)
AS
/*	Created by: @Lukas
	Date: 2013-04-10
	Task: Refund FGLG 
	DB: DBAGE/BODB02

	Revisions: 
		- 20140421@Kathy: Add 1H FGLG bettypes (127) [Redmine:#14718]
	
*/
SET NOCOUNT ON
DECLARE @bettype int

select @bettype = CASE WHEN @action = 'CAL-HT' then 127
						when @action = 'CAL-FT' then 14
						ELSE 0
					end 
WHILE 1=1
BEGIN
	UPDATE TOP (10000) dbo.bettrans with (ROWLOCK, UPDLOCK)
	SET
		status = 'Refund',
		statusID = 103,
		winlost=actual_stake,
		awinlost=0,
		mwinlost=0,
		swinlost=0,
		playercomm=0,
		comm=0,
		acomm=0,
		scomm=0,
		ruben = 1 
	where
		matchid=@matchid
		--AND [status] not in ('Void', 'Reject')
		AND statusID not in (103,101,102)
		AND ((@bettype = 0 AND bettype IN (14,127)) 
					OR (bettype = @bettype))
		--AND ruben = 1 
		AND right(betteam, 1) = case when @LGOnly = 1 then '2' else right(betteam, 1) end
    
    IF @@ROWCOUNT < 10000 BREAK
END

-------------Start: Refund FGLG for bettransm-------------

--WHILE 1=1
BEGIN
    --UPDATE TOP (10000) dbo.bettransm with (ROWLOCK, UPDLOCK)
	UPDATE dbo.bettransm with (ROWLOCK, UPDLOCK)
    SET 
		winlostdate=@matchdate,
		[status]='Refund',
		statusID = 103,
		statuswinlost=0,	
		ruben=1 
	WHERE 
		((@bettype = 0 and bettype in (14, 127)) OR (bettype = @bettype))
		AND matchid=@matchid
		AND statusID not in (103,101,102)
		AND right(betteam, 1) = case when @LGOnly = 1 then '2' else right(betteam, 1) end		
	
--	IF @@ROWCOUNT < 10000 BREAK

    UPDATE dbo.betParlayDetail with (ROWLOCK, UPDLOCK)
    SET 
		winlostdate=@matchdate,
		statusID = 103,
		statuswinlost=0
	WHERE 
		((@bettype = 0 and bettype IN (14, 127)) OR (bettype = @bettype))
		AND matchid=@matchid
		AND statusID not in (103,101,102)
		AND right(betteam, 1) = case when @LGOnly = 1 then '2' else right(betteam, 1) end		

END
-------------End: Refund FGLG for bettransm-------------


