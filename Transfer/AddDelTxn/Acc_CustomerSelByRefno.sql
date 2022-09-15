/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,bodbExtAccNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_CustomerSelByRefno]
	@refno bigint = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*	Created by: Danny
	Task:	For Delete Transaction (transfer)
			Account / Lefmenu / Statement / Detail/ Del
			
	Revisions:
		- 20220809@Danny: Init. SP [Redmine: #175253]
	
*/
BEGIN
	SET NOCOUNT ON 

	IF @refno IS NULL OR @refno = 0
	BEGIN
		SELECT @ErrMsg =  'Input Refno is invalid.' ,  @ErrCode = 101
		RETURN
	END

	DECLARE @transferDetail TABLE (transid BIGINT, CustID INT, IsDel BIT, currency INT, bettype INT)
	INSERT INTO @transferDetail (transid, CustID, IsDel, currency, bettype)
	SELECT t.transid, t.CustID, ISNULL(u.IsDel,0), Currency, bettype
	FROM dbo.transfer t WITH(NOLOCK) 
	LEFT JOIN dbo.transferInfo u WITH(NOLOCK) ON t.TransId = u.TransId
	WHERE t.refno = @refno AND t.CustID <> 0


	IF EXISTS (SELECT 1 FROM @transferDetail WHERE IsDel = 1)
	BEGIN
		SELECT @ErrMsg =  'Unable to delete this transaction due to it is marked as "Deleted"!' ,  @ErrCode = 102
		RETURN
	END

	DECLARE @cnt_tickets INT, @cnt_customers INT, @bettype INT
	SELECT @cnt_tickets = COUNT(1), @cnt_customers = COUNT(DISTINCT Custid), @bettype = MAX(bettype) FROM @transferDetail

	IF ( @cnt_tickets % 2 = 1  OR  @cnt_customers = 1) AND @bettype NOT IN (21001, 21002)
	BEGIN
		SELECT @ErrMsg =  'Input Refno is invalid.' ,  @ErrCode = 103
		RETURN
	END

	SELECT DISTINCT CustID FROM @transferDetail

END
GO	