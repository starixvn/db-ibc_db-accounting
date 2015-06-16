ALTER FUNCTION [dbo].[f_Get_SportNameBySporttype]
(
    @Sporttype    TINYINT,
    @Language    NVARCHAR(5)='E' 
)
RETURNS NVARCHAR(100) 
AS
/*
    Created by: Elodie
    Date: 2012-11-27
    Task: Get the sport name from sporttype by language
    DB: DBCUST/CustDB
    
    Revisions: 
        - 20130124@Elodie: return SportName with English language in case of @SportName = '' or @SportName is null
        - 20130808@Elodie: Splitting DBTXN into DBCUST (call sport by link server)
		- 20130808@Elodie: Migrate CustDB to new server DBCUST
*/
BEGIN
    -- Declare the return variable here
    DECLARE    @SportName    NVARCHAR(100)

    SELECT    @SportName = CASE @Language    WHEN 'E'    THEN SportName 
                                        WHEN 'CS'    THEN SportNameCs
                                        WHEN 'CT'    THEN SportNameCh
                                        WHEN 'TH'    THEN SportNameTh
                                        WHEN 'J'    THEN SportNameJp
                                        WHEN 'KO'    THEN SportNameKo
                                        WHEN 'ES'    THEN SportNameES
                                        WHEN 'VI'    THEN SportNameVN
                                        ELSE SportName END 
                                        
    FROM    DBTXN.bodb02.dbo.Sports WITH (NOLOCK)
    WHERE    SportType = @Sporttype
    
    IF (@SportName = '' or @SportName IS NULL)
        SELECT    @SportName = SportName 
        FROM    DBTXN.bodb02.dbo.Sports WITH (NOLOCK)
        WHERE    SportType = @Sporttype

    -- Return the result of the function
    RETURN    @SportName

END


GO
GRANT VIEW DEFINITION ON [dbo].[f_Get_SportNameBySporttype] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[f_Get_SportNameBySporttype] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[f_Get_SportNameBySporttype] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[f_Get_SportNameBySporttype] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[f_Get_SportNameBySporttype] TO [bodbDownlineNetView]