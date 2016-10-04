USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustomerInformationSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustomerInformationSel];
GO
USE [CustDB];
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustomerInformationSel]    Script Date: 07/07/2015 16:09:41 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustomerInformationSel] @CustId INT
AS
	
/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].

Parameters Explanation:

Example: 
EXEC [NAP_WinLimit_CustomerInformationSel] @CustId = 807023


*/

     SET NOCOUNT ON;
     DECLARE @Username NVARCHAR(50)= '', @Site NVARCHAR(50)= '';
     DECLARE @AgentId INT= 0, @Agent NVARCHAR(50)= '';
     DECLARE @MasterId INT= 0, @Master NVARCHAR(50)= '';
     DECLARE @SuperId INT= 0, @Super NVARCHAR(50)= '';
     DECLARE @Status BIT= 0, @IsCreditSite BIT= 0;
     
     -- User information
     SELECT @Username = ISNULL(username, ''),
            @AgentId = ISNULL(recommend, 0),
            @MasterId = ISNULL(recommend, 0),
            @SuperId = ISNULL(recommend, 0),
            @Status = CASE
                          WHEN closed = 0
                               AND reject = 0
                          THEN 1
                          ELSE 0
                      END
     FROM dbo.custInfo WITH (NOLOCK)
     WHERE custid = @CustId;
     -- Site
     SELECT @IsCreditSite = CASE
                                WHEN isDeposit = 0
                                THEN 1
                                ELSE 0
                            END
     FROM dbo.[Site] WITH (NOLOCK)
     WHERE [site] = @Site;
     -- Agent
     SELECT @Agent = ISNULL(username, ''),
            @Site = [site]
     FROM dbo.Customer WITH (NOLOCK)
     WHERE custid = @AgentId;
     -- Master
     SELECT @Master = ISNULL(username, '')
     FROM dbo.custInfo WITH (NOLOCK)
     WHERE custid = @MasterId;
     -- Super
     SELECT @Super = ISNULL(username, '')
     FROM dbo.custInfo WITH (NOLOCK)
     WHERE custid = @SuperId;
     -- Query
     SELECT @CustId CustId,
            @Username Username,
            @Site SiteName,
            @IsCreditSite IsCreditSite,
            @Status [Status],
            @AgentId AgentId,
            @Agent Agent,
            @MasterId MasterId,
            @Master [Master],
            @SuperId SuperId,
            @Super Super;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustomerInformationSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustomerInformationSel] TO [vnteam];
GO