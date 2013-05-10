ALTER PROCEDURE [dbo].[Acc_Con_AdminPolicySelByCustID]
               @CustID  INT,
               @GroupID INT  = NULL OUTPUT,
               @System varchar(50)='ACCOUNTING'
AS
/*
	Created by: []
	Task: Get functionID by CustID 
	DB: DB03.BODB02
	
	Revisions:
		- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1 
*/

SET NOCOUNT ON 
If @System='ACCOUNTING'
BEGIN
  SELECT   c.username,
           fi.funcname,
           fi.funcdesc,
           mp.funcid,
           mp.policy,
           gp.policy AS gpolicy,
           (Isnull(mp.policy,0) | Isnull(gp.policy,0)) & Isnull(fi.funcrender,0) AS actual_policy,
           fi.parentid,
           COUNT(fip.funcid) AS subfunccount,
           fi.displayorder
  FROM     acc_memberpolicy_1 mp WITH (nolock)
           INNER JOIN acccustomer_1 ac WITH (nolock)
             ON ac.custid = mp.custid
           INNER JOIN acc_functioninfo fi WITH (nolock)
             ON mp.funcid = fi.funcid --or mp.funcid=fi.parentid
           INNER JOIN customer c WITH (nolock)
             ON c.custid = mp.custid
           INNER JOIN acc_grouppolicy_1 gp WITH (nolock)
             ON gp.groupid = ac.groupid
                AND gp.funcid = mp.funcid
           LEFT JOIN acc_functioninfo fip WITH (nolock)
             ON fi.funcid = fip.parentid
                AND fip.parentid <> fip.funcid
  WHERE    mp.custid = @CustID
  GROUP BY c.username,fi.funcname,fi.funcdesc,mp.funcid,
           mp.policy,fi.displayorder,gp.policy,fi.funcrender,
           fi.parentid
  ORDER BY fi.parentid,
           COUNT(fip.funcid) DESC,
           fi.displayorder
  
  SELECT @GroupID = groupid
  FROM   acccustomer_1 WITH (nolock)
  WHERE  custid = @custid
END
ELSE
BEGIN
	SELECT   c.username,
           fi.funcname,
           fi.funcdesc,
           mp.funcid,
           mp.policy,
           gp.policy AS gpolicy,
           (Isnull(mp.policy,0) | Isnull(gp.policy,0)) & Isnull(fi.funcrender,0) AS actual_policy,
           fi.parentid,
           COUNT(fip.funcid) AS subfunccount,
           fi.displayorder
  FROM     acc_memberpolicy_1 mp WITH (nolock)
           INNER JOIN affiliate_user ac WITH (nolock)
             ON ac.custid = mp.custid
           INNER JOIN acc_functioninfo fi WITH (nolock)
             ON mp.funcid = fi.funcid --or mp.funcid=fi.parentid
           INNER JOIN customer c WITH (nolock)
             ON c.custid = mp.custid
           INNER JOIN acc_grouppolicy_1 gp WITH (nolock)
             ON gp.groupid = ac.groupid
                AND gp.funcid = mp.funcid
           LEFT JOIN acc_functioninfo fip WITH (nolock)
             ON fi.funcid = fip.parentid
                AND fip.parentid <> fip.funcid
  WHERE    mp.custid = @CustID 
  GROUP BY c.username,fi.funcname,fi.funcdesc,mp.funcid,
           mp.policy,fi.displayorder,gp.policy,fi.funcrender,
           fi.parentid
  ORDER BY fi.parentid,
           COUNT(fip.funcid) DESC,
           fi.displayorder
  
  SELECT @GroupID = groupid
  FROM   affiliate_user WIT
END



GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminPolicySelByCustID] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].acc_con_adminpolicyselbycustid TO [bodbadminnet]
GO
GRANT EXECUTE ON [dbo].acc_con_adminpolicyselbycustid TO [bodbExtAccNet]