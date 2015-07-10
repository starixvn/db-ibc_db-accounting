DECLARE @ID INT
DECLARE @MSG CHAR(8), @DataName sysname

set @DataName = 'bodb02'

While 1 = 1
BEGIN
    Set RowCount 1

 SELECT
  @id = spid
 FROM
  Master..Sysprocesses P,
  Master..Sysdatabases D
 WHERE
  D.Name=@DataName 
 AND
  D.dbid = P.dbid


    IF @@rowcount = 0
    break

    SELECT @msg = 'KILL ' + convert(char(8) ,@ID) 
    Print @msg
    EXEC( @msg)
    --break
END

GO