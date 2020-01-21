/*<info serverAlias="DBAGE-bodb02,DBACC-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/

CREATE FUNCTION [dbo].[f_GetHeadlineNoPT]()	
RETURNS TABLE
RETURN

/*
Created: 20200113@Sophia
Task : Get HeadlineID/ SuperID which has No PT
DB: DBAGE.bodb02, DBACC.bodb02, DBWH.bodb02

Revisions:
	- 20200113@Sophia: Initial [redmine: #127042]
Param's Explanation:
	
*/
SELECT  s.CustID as SuperId, s.UplineID as HeadlineId
FROM   	bodb02.dbo.CustInfo c WITH (NOLOCK)
INNER JOIN bodb02.dbo.CustSuper s WITH (NOLOCK) 
		ON c.CustID = s.UplineID 
WHERE  	c.username LIKE 'XP%'
		AND c.RoleID = 0


GO
GRANT SELECT ON [dbo].[f_GetHeadlineNoPT] TO [bodbAdminNet]
GO
GRANT SELECT ON [dbo].[f_GetHeadlineNoPT] TO [bodbDownlineNet]
GO
GRANT SELECT ON [dbo].[f_GetHeadlineNoPT] TO [bodbDownlineNetView]