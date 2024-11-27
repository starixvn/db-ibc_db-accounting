/*<info serverAlias="DBACC-bodb02" executers="wsv_nap,wsv_xnap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_RewardPayment_CustomerSelByRefNo]
	@RefNo			BIGINT,
	@ErrCode		INT	=	0	OUTPUT,
	@ErrMsg			NVARCHAR(200) =	''	OUTPUT
AS
/*
	Created by: 20240826@Bobby
	Task: 209633 - RewardPayment - Get Customer by RefNo
	DB: DBAGE.bodb02
	
	Revisions:
		- 20240826@Bobby: Init [Redmine: #209633]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @RefNoCheck		BIGINT
	;

	SELECT @RefNoCheck		= ISNULL(@RefNo,  0)
		,@ErrCode			= 0
		,@ErrMsg			= ''
	;

	IF ISNULL(@RefNoCheck, 0) = 0
	BEGIN
		SELECT @ErrMsg =  'Input Refno is invalid.' ,  @ErrCode = 101
		RETURN
	END

	DECLARE @txnDetail TABLE (transid BIGINT, CustID INT, IsReversed BIT, ReverseOrder TINYINT)

	INSERT INTO @txnDetail
	SELECT t.transid, t.custid, t.IsReversed, ReverseOrder
	FROM (
	
		SELECT t.transid, t.custid,ISNULL(ti.IsDel, 0) AS IsReversed, 1 AS ReverseOrder
		FROM dbo.[Transfer] t WITH (NOLOCK)
			LEFT JOIN dbo.[TransferInfo] ti WITH (NOLOCK) ON ti.transid = t.transid
		WHERE RefNo = @RefNoCheck

		UNION ALL
		SELECT transid, custid, ISNULL(IsReversed, 0) AS IsReversed, 2
		FROM dbo.TransferExtra WITH (NOLOCK)
		WHERE RefNo = @RefNoCheck
	) AS t;

	--select * from @txnDetail

	IF EXISTS (SELECT 1 FROM @txnDetail WHERE IsReversed = 1)
	BEGIN
		SELECT @ErrMsg =  'Invalid transaction due to it is marked as "Reversed"!' ,  @ErrCode = 102
		RETURN
	END

	SELECT CustID
	FROM (
		SELECT DISTINCT CustID, ReverseOrder
		FROM @txnDetail
	) AS t
	ORDER BY ReverseOrder;

END
