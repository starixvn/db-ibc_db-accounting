ALTER PROCEDURE [dbo].[Dot_Admin_UpdateWinlostDate] 
	@matchid int = 0,
	@neweventdate nvarchar(50) = NULL
AS
-- admin page
-- event/updatestatus.asp
-- 23.Jan.2010@viet: update winlostdate for mix parlay ticket also
IF @matchid <> 0
BEGIN
	IF @neweventdate is null
		SELECT @neweventdate = eventdate from Match with(nolock) where matchid=@matchid
		
	IF EXISTS (SELECT TOP 1 1 FROM bettransM with(nolock) where matchid=@matchid)
	BEGIN		
		DECLARE @eventdate smalldatetime
		SELECT TOP 1 @eventdate = winlostdate FROM bettrans with(nolock) where matchid=@matchid and bettype<99 and winlostdate <> @neweventdate
		
		IF @eventdate is not null
		BEGIN						
			Update bettrans with(updlock)
			set winlostdate = @neweventdate
			where transid in (	SELECT b.transid
								FROM bettrans b with(nolock)
									INNER JOIN bettransM bm with(nolock) on b.refno = bm.refno
								WHERE bm.matchid = @matchid
							 ) 
				and winlostdate < @neweventdate
				and status = 'running'
		END
		
		Update bettransM with(updlock)
		set matchdate = @neweventdate
		WHERE matchid = @matchid				
	END
	
	UPDATE bettrans with(updlock)
	SET winlostdate = @neweventdate
	WHERE matchid = @matchid
		and bettype < 99
END

GO
GRANT EXECUTE ON [dbo].[Dot_Admin_UpdateWinlostDate] TO [Dot_Admin]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Admin_UpdateWinlostDate] TO [vnteam]