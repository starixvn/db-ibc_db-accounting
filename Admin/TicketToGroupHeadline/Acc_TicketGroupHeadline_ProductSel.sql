/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_TicketGroupHeadline_ProductSel]
AS

/*
	Created by Percy
	Date: 2017-08-31
	DB: DBACC.bodb02
	Task: NAP - Admin - Ticket to Group Headline - Get list of offered products

	Revisions:
		- 20170831@Percy: Create new SP [RedmineID: #82419]
*/

BEGIN
	SET NOCOUNT ON

	SELECT ProductID, ProductName
	FROM dbo.Products WITH (NOLOCK)
	WHERE ProductID NOT IN (11,13,14,16,17,20,25)
		AND [Enabled] = 1
END
GO