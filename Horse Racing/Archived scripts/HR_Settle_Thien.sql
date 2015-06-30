Update outright set oddsstatus = 'closed' where programID = 'UK-LF'

Update outright set odds = 5, PlaceOdds = 3,  placing = 1 where programID = 'UK-LF' and matchcode = '05'
Update outright set odds = 6, PlaceOdds = 4, placing = 5 where programID = 'UK-LF' and matchcode = '01'

EXEC dbo.Admin_3rdAutoSettlement_s151 
@ProgramID = 'UK-LF',
@raceNumber = 1,
@eventdate = '2008-12-21'