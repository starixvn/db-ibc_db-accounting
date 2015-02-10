 USE [IPDB]
GO
/****** Object:  StoredProcedure [dbo].[GetIPVN]    Script Date: 10/28/2009 15:41:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[GetIPVN]
AS
/*
Created: HuyNguyen
Task : Get IP VN ranges 
DB: BODB02.IPDB
Original:Accounting site
Revisions:
	- 20150205@Johnson: get IP VN from IPTable [redmine: #30656]
*/		
	SET NOCOUNT ON

	SELECT ipFROM,ipTO, 0 as isManual from IPTable with (nolock)
	WHERE countrySHORT = 'vn'

GO
GRANT EXECUTE ON [dbo].[GetIPVN] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetIPVN] TO [vnteam]