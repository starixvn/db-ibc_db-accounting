ALTER PROCEDURE [dbo].[Acc_ExecRep_07]
AS
BEGIN
    if NOT exists (select * from dbo.sysobjects where name = 'custsetting')
    BEGIN
	    RETURN
    END
     
     update custsetting3rd set	
        apositiontaking=0.5, mpositiontaking=0
     where sporttype = 151
	    and custid IN
	    (	select custid from custinfo with (nolock)
		    where recommend in (860379, 1813583, 860386, 860387, 1752421, 860380, 860376) 

	    )
    	

     update custsetting set	
        apositiontaking=0, alivepositiontaking=0
     where custid IN
	    (	select custid from custinfo with (nolock)
		    where recommend in (1015423, 1015433, 860379, 860383, 1813583, 860386, 860387, 1752421, 860380, 860376, 916515) 
	    )

END
