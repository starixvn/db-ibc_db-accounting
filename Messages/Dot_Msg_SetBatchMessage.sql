set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go


ALTER PROCEDURE [dbo].[Dot_Msg_SetBatchMessage]
@BatchId int = NULL,
@Content_en	nvarchar(4000) = NULL,
@Content_ch	nvarchar(4000) = NULL,
@Content_cs	nvarchar(4000) = NULL,
@Content_jp	nvarchar(4000) = NULL,
@Content_it	nvarchar(4000) = NULL,
@Content_th	nvarchar(4000) = NULL,
@Content_ko nvarchar(4000) = NULL,
@Content_es nvarchar(4000) = NULL
AS
BEGIN 
	SET NOCOUNT ON
	IF EXISTS (SELECT BatchId FROM dbo.BatchMsg with (nolock) WHERE BatchId = @BatchId)
	BEGIN
		UPDATE dbo.BatchMsg WITH (rowlock,updlock)
		SET
			BContent_ch = @Content_ch,
			BContent_cs = @Content_cs,
			BContent_it = @Content_it,
			BContent_jp = @Content_jp,
			BContent_th = @Content_th,
			BContent_en = @Content_en,
			BContent_ko = @Content_ko,
			BContent_es = @Content_es
		WHERE BatchId = @BatchId;
		SELECT @BatchId AS BatchId;
	END
	ELSE
	BEGIN
		INSERT dbo.BatchMsg (BContent_ch, BContent_it, BContent_cs, BContent_jp, BContent_th,
							 BContent_en, BContent_ko, BContent_es) 
		VALUES(@Content_ch, @Content_it, @Content_cs, @Content_jp, @Content_th, 
			   @Content_en, @Content_ko, @Content_es);
		SELECT scope_identity() AS BatchId;
	END
END


GO
GRANT EXECUTE ON [dbo].[Dot_Msg_SetBatchMessage] TO [bodbadminnet]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_SetBatchMessage] TO [vnteam]