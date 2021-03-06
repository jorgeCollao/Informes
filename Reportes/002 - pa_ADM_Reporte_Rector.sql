

USE [matricula]
GO
/****** Object:  StoredProcedure [matricula].[pa_ADM_Reporte_Rector]    Script Date: 06-10-2016 9:25:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/************************************************************
 * ALEXANDERS GUTIERREZ M.
 * Fecha: 27-9-2013
 ************************************************************/
 
 /*
 * modificaciones:
 * autor		: Alexanders Gutierrez
 * fecha		: 18/08/2014
 * descripción	: se realiza nuevamente la consulta evitando la utilizacion de funciones.
 * autor		: Alexanders Gutierrez
 * fecha		: 19/08/2014
 * descripcion	: se agregan datos historicos, para comparativos por dia y rangos de hora
 * 
 *
 * autor			: Alexanders Gutierrez
 * fecha			: 11/11/2014
 * descripcion	: se agregan nuevas vias de admision proceso 2015, cod_via 44 y 45, que corresponden al admsion especial 15%
 */

-- EXEC [pa_ADM_Reporte_Rector] 'concepcion',0,NULL,1,'20:00'

ALTER PROCEDURE [matricula].[pa_ADM_Reporte_Rector](
    @CODSEDE      VARCHAR(30) = NULL
   ,@RESUMEN      BIT = 1
   ,@USUARIO      VARCHAR(50) = NULL
   ,@DIA          INT = NULL
   ,@HORA_FIN     VARCHAR(5) = '23:59'
   ,@CSV          BIT = 0
)
AS
BEGIN
	DECLARE @ANOPROCESO         INT
	       ,@PERIODOPROCESO     INT
	       ,@FECHA              VARCHAR(10)
	
	SELECT @ANOPROCESO = MATRICULA.FN_OBTIENEANOPERIODO('A' ,'M')
	      ,@PERIODOPROCESO = 1
	
	
	SET @FECHA = (
	        SELECT TOP 1 ahpd.FECHA
	        FROM   ADM_HISTORICO_POR_DIA ahpd
	        WHERE  ahpd.DIA = @DIA
	               AND ahpd.ANO = @ANOPROCESO
	               AND ahpd.PERIODO = @PERIODOPROCESO
	    )
	--METAS BACH. UDD  2014
	DECLARE @TMP_METAS_BACH TABLE (CODCARR VARCHAR(30) ,META INT)
	
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1100S'
	   ,174
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1200S'
	   ,37
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1300S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1301S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1304S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1400S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1401S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1500S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1501S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1502S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1504S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1603S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1631S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1632S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1634S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1700S'
	   ,40
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1800S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1801S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1900S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1901S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1902S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1903S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1904S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '2500S'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '2501S'
	   ,0
	  )
	
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1100C'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1200C'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1300C'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1400C'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1401C'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1500C'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1502C'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1603C'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1700C'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1801C'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1900C'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1901C'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1902C'
	   ,0
	  )
	INSERT INTO @TMP_METAS_BACH
	VALUES
	  (
	    '1903C'
	   ,0
	  )
	
	--- FIN METAS BACH.
	
	
	/******************************************************************
	GUARDAR EN TEMPORAL LAS CARRERAS DEL PROCESO Y QUE ESTEN VIGENTES
	******************************************************************/
	DECLARE @TMP_CARRERA_PROCESO TABLE (ID INT IDENTITY(1 ,1) ,CODCARR VARCHAR(30),NOMBRE VARCHAR(100),SEDE VARCHAR(100))
	INSERT INTO @TMP_CARRERA_PROCESO
	SELECT mcc.CODCARR,MC.NOMBRE_C,MC.SEDE
	FROM   MT_CARRER AS mc
	       INNER JOIN MT_CARRER_CLASIFICACION AS mcc
	            ON  mcc.CODCARR = mc.CODCARR
	WHERE  mcc.CODTIPO = 2
	       AND @ANOPROCESO BETWEEN mcc.ANO_INI AND mcc.ANO_FIN        
	
	--SELECT AMC.CODCARR
	--FROM   DB_ADMISION.DBO.ADM_MAE_CARRERA AMC
	--WHERE  AMC.CODCARR <> 'GLOBAL'
	--       AND AMC.VIGENTE = 1
	
	
	/*******************************************
	* INICIO INSERCIÓN DE SEDES Y CARRERAS DEL PROCESO JUNTO A SUS METAS
	*******************************************/
	DECLARE @TmpInfoRector TABLE (
	            CODSEDE VARCHAR(30)
	           ,CODCARR VARCHAR(30)
	           ,CARRERA VARCHAR(100)
	           ,META_PSU_PPTO INT
	           ,META_ESP_PPTO INT
	           ,META_UDD INT
	           ,META_BACH_UDD_PPTO INT
	           ,MATRICULA_PSU INT
	           ,MATRICULA_ESP INT
	           ,MATRICULA_UDD INT
	           ,ESTIMADO_PSU INT
	           ,ESTIMADO_ESP INT
	           ,ESTIMADO_UDD INT
	           ,MATRICULA_BACH_UDD INT
	           ,ESTIMADO_BACH_UDD INT
	        )
	
	
	INSERT INTO @TmpInfoRector
	SELECT 
			--CASE amc.CODSEDE
	  --          WHEN 1 THEN 'CONCEPCION'
	  --          WHEN 2 THEN 'SANTIAGO'
	  --     END AS CODSEDE
		   AMC.SEDE
	      ,amc.CODCARR
	      ,amc.NOMBRE
	      ,COALESCE(MP.META_OFICIAL ,0)
	      ,COALESCE(MP.META_ADMESP ,0)
	      ,COALESCE(MP.META_CARRERA ,0)
	      ,COALESCE(BA.META ,0)
	      ,NULL
	      ,NULL
	      ,NULL
	      ,NULL
	      ,NULL
	      ,NULL
	      ,NULL
	      ,NULL
	FROM   @TMP_CARRERA_PROCESO AMC -- ADM_MAE_CARRERA
	       LEFT JOIN MT_PJECORTEPONDERADOCARRERA MP
	            ON  MP.CODCARR = AMC.CODCARR
	                AND MP.ANO = @ANOPROCESO
	                AND MP.PERIODO = @PERIODOPROCESO
	       LEFT JOIN @TMP_METAS_BACH BA
	            ON  BA.CODCARR = AMC.CODCARR
	--WHERE  AMC.CODCARR <> 'GLOBAL'
	--       AND AMC.VIGENTE = 1
	
	/*******************************************
	* FIN INSERCIÓN DE SEDES,CARRERAS DEL PROCESO Y SUS METAS
	*******************************************/
	
	/*******************************************
	* INICIO ACTUALIZACION DE TOTALES DE MATRICULADOS POR CARRERA
	*******************************************/
	DECLARE @ID INT
	SET @ID = (
	        SELECT TOP 1                    ID
	        FROM   @TMP_CARRERA_PROCESO     tcp1
	    )
	
	WHILE @ID > 0
	BEGIN
	    DECLARE @MAT_PSU      INT
	           ,@MAT_ESP      INT
	           ,@MAT_UDD      INT
	           ,@MAT_BACH     INT
	           ,@CODCARR      VARCHAR(30)
	    
	    SET @CODCARR = (
	            SELECT tcp1.CODCARR
	            FROM   @TMP_CARRERA_PROCESO tcp1
	            WHERE  tcp1.ID = @ID
	        )
	    
	    SET @MAT_PSU = (
	            SELECT COUNT(I.RUT)  AS MATRICULA_PSU
	            FROM   (
	                       SELECT A.RUT
	                       FROM   MT_ALUMNO A
	                              INNER JOIN MT_POSCAR P
	                                   ON  P.CODPOSTUL = A.RUT
	                                       AND P.CODCARR = A.CODCARPR
	                                       AND P.ANO = A.ANO
	                                       AND P.PERIODO = A.PERIODO
	                              INNER JOIN MT_VIADMISION V
	                                   ON  V.COD_VIA = A.COD_VIA
	                                       AND V.CODTIPOADMISION = 1
	                       WHERE  A.CODCARPR = @CODCARR
	                              AND A.ANO = @ANOPROCESO
	                              AND A.PERIODO = @PERIODOPROCESO
	                              AND A.ANO_MAT = A.ANO
	                              AND A.PERIODO_MAT = A.PERIODO
	                              AND A.ESTACAD IN ('VIGENTE' ,'SUSPENDIDO')
	                       UNION
	                       SELECT A.RUT
	                       FROM   MATRICULA.MT_ALUMNO A
	                              INNER JOIN MATRICULA.MT_POSCAR P
	                                   ON  A.RUT = P.CODPOSTUL
	                                       AND A.CODCARPR = P.CODCARR
	                              INNER JOIN MATRICULA.MT_CARRER C
	                                   ON  A.CODCARPR = C.CODCARR
	                              INNER JOIN MATRICULA.MT_CLIENT CC
	                                   ON  CC.CODCLI = A.RUT
	                       WHERE  A.ANO = @ANOPROCESO
	                              AND A.PERIODO = @PERIODOPROCESO
	                              AND A.ANO_MAT = A.ANO
	                              AND A.PERIODO_MAT = A.PERIODO
	                              AND P.ANO = A.ANO
	                              AND P.PERIODO = A.PERIODO
	                              AND C.CODCARR = @CODCARR
	                              AND A.ESTACAD IN ('VIGENTE' ,'SUSPENDIDO')
	                              AND A.COD_VIA  IN (29) --Via 9: Repostulación
	                   )             AS I
	        )
	    
	    
	    SET @MAT_ESP = (
	            SELECT COUNT(CODCLI)  AS MATRICULA_ESP
	            FROM   MT_ALUMNO         A
	            WHERE  A.CODCARPR = @CODCARR
	                   AND A.ESTACAD IN ('VIGENTE' ,'SUSPENDIDO')
	                   AND A.ANO = @ANOPROCESO
	                   AND A.PERIODO = @PERIODOPROCESO
	                   AND A.ANO_MAT = A.ANO
	                   AND A.PERIODO_MAT = A.PERIODO
	                   AND LTRIM(RTRIM(A.COD_VIA)) IN (10
	                                                  ,24
	                                                  ,33
	                                                  ,41
	                                                  ,44
	                                                  ,45
	                                                  ,46
	                                                  ,47
	                                                  ,51
	                                                  ,36
	                                                  ,20
	                                                  ,22
	                                                  ,23
	                                                  ,25
	                                                  ,26
	                                                  ,8
	                                                  ,28)
	        )
	    
	    SET @MAT_BACH = (
	            SELECT COUNT(CODCLI)  AS MATRICULA_BACH
	            FROM   MT_ALUMNO         A
	            WHERE  A.CODCARPR = @CODCARR
	                   AND A.ESTACAD IN ('VIGENTE' ,'SUSPENDIDO')
	                   AND A.ANO = @ANOPROCESO
	                   AND A.PERIODO = @PERIODOPROCESO
	                   AND A.ANO_MAT = A.ANO
	                   AND A.PERIODO_MAT = A.PERIODO
	                   AND LTRIM(RTRIM(A.COD_VIA)) IN (19)
	        ) -- matriculas bachillerato UDD
	    
	    SET @MAT_UDD = @MAT_PSU + @MAT_ESP + @MAT_BACH
	    
	    UPDATE @TmpInfoRector
	    SET    MATRICULA_PSU = @MAT_PSU
	          ,MATRICULA_ESP = @MAT_ESP
	          ,MATRICULA_UDD = @MAT_UDD
	          ,MATRICULA_BACH_UDD = @MAT_BACH
	    WHERE  CODCARR = @CODCARR
	    
	    DELETE 
	    FROM   @TMP_CARRERA_PROCESO
	    WHERE  ID = @ID
	    
	    SET @ID = (
	            SELECT TOP 1 ID
	            FROM   @TMP_CARRERA_PROCESO tcp1
	        )
	END
	
	IF @CSV = 0
	BEGIN
	    SELECT H.CODSEDE
	          ,H.CODCARR
	          ,H.CARRERA
	          ,H.META_PSU_PPTO	--META PSU (1)
	          ,H.META_ESP_PPTO	--META AE  (2)
	          ,H.META_UDD	--META TOTAL (PSU+AE+BACH) (4)
	          ,H.META_BACH_UDD_PPTO	--META BACH (3)
	          ,H.MATRICULA_PSU	--MAT. PSU A LA FECHA (1)
	          ,H.MATRICULA_ESP	--MAT. AE  A LA FECHA (2)
	          ,H.MATRICULA_UDD	--MAT. TOTAL  (PSU+AE+BACH) A LA FECHA (4)
	          ,H.ESTIMADO_PSU	--MAT. EST. DIR. DE CARR. PSU   (1)
	          ,H.ESTIMADO_ESP	--MAT. EST. DIR. DE CARR. AE    (2)
	          ,H.ESTIMADO_UDD	--MAT. EST. DIR. DE CARR. TOTAL (4)
	          ,H.MATRICULA_BACH_UDD	--MAT. BACH. A LA FECHA (3)
	          ,H.ESTIMADO_BACH_UDD	--MAT. EST. DIR DE CARR. BACH. (3)
	          ,SUM(H.MAT_PSU_ANTERIOR)   AS MAT_PSU_ANTERIOR	--MAT.PSU AÑO ANT. (HORA SELEC.) (1)
	          ,SUM(H.MAT_ESP_ANTERIOR)   AS MAT_ESP_ANTERIOR	--
	          ,SUM(H.MAT_UDD_ANTERIOR)   AS MAT_UDD_ANTERIOR	--
	          ,SUM(H.MAT_BACH_ANTERIOR)  AS MAT_BACH_ANTERIOR	--
	          ,MAX(H.MAT_CIERRE_PSU)     AS MAT_CIERRE_PSU_ANTERIOR	--MAT. PSU   AÑO ANT. (CIERRE DEL PROC.) (1)
	          ,MAX(H.MAT_CIERRE_ESP)     AS MAT_CIERRE_ESP_ANTERIOR	--MAT. AE    AÑO ANT. (CIERRE DEL PROC.) (2)
	          ,MAX(H.MAT_CIERRE_BACH)    AS MAT_CIERRE_BACH_ANTERIOR --MAT. BACH. AÑO ANT. (CIERRE DEL PROC.) (3)
	    FROM   (
	               SELECT tir.CODSEDE
	                     ,tir.CODCARR
	                     ,tir.CARRERA
	                     ,tir.META_PSU_PPTO
	                     ,tir.META_ESP_PPTO
	                     ,tir.META_UDD
	                     ,tir.META_BACH_UDD_PPTO
	                     ,tir.MATRICULA_PSU
	                     ,tir.MATRICULA_ESP
	                     ,tir.MATRICULA_UDD
	                     ,tir.ESTIMADO_PSU
	                     ,tir.ESTIMADO_ESP
	                     ,tir.ESTIMADO_UDD
	                     ,tir.MATRICULA_BACH_UDD
	                     ,tir.ESTIMADO_BACH_UDD
	                     ,COALESCE(AHPD.MAT_PSU ,0) AS MAT_PSU_ANTERIOR
	                     ,COALESCE(AHPD.MAT_ESP ,0) AS MAT_ESP_ANTERIOR
	                     ,COALESCE(AHPD.MAT_UDD ,0) AS MAT_UDD_ANTERIOR
	                     ,COALESCE(AHPD.MAT_BACH ,0) AS MAT_BACH_ANTERIOR
	                     ,COALESCE(AHPD.MAT_CIERRE_PSU ,0) AS MAT_CIERRE_PSU
	                     ,COALESCE(AHPD.MAT_CIERRE_ESP ,0) AS MAT_CIERRE_ESP
	                     ,COALESCE(AHPD.MAT_CIERRE_BACH ,0) AS MAT_CIERRE_BACH
	               FROM   @TmpInfoRector tir
	                      LEFT JOIN matricula.ADM_HISTORICO_POR_DIA AHPD
	                           ON  AHPD.CODCARR = TIR.CODCARR
	                               AND AHPD.ANO = @ANOPROCESO - 1
	                               AND AHPD.PERIODO = @PERIODOPROCESO
	                               AND
	                               (
	                                (AHPD.DIA < @DIA OR @DIA IS NULL) 
									OR
	                                (ahpd.DIA = @DIA and AHPD.HORA_FIN <= @HORA_FIN ) 
	                                )
	                               
	               WHERE  tir.CODCARR IN (SELECT AUAC.CODCARR
	                                      FROM   ADM_USUARIO_ASIGNACION_CARRERA 
	                                             AUAC
	                                      WHERE  AUAC.CODCARR = tir.CODCARR
	                                             AND AUAC.ID_USUARIO = @USUARIO
	                                             OR @USUARIO IS NULL)
	                      AND (tir.CODSEDE = @CODSEDE OR @CODSEDE IS NULL)
	           )                         AS H
	    GROUP BY
	           H.CODSEDE
	          ,H.CODCARR
	          ,H.CARRERA
	          ,H.META_PSU_PPTO
	          ,H.META_ESP_PPTO
	          ,H.META_UDD
	          ,H.META_BACH_UDD_PPTO
	          ,H.MATRICULA_PSU
	          ,H.MATRICULA_ESP
	          ,H.MATRICULA_UDD
	          ,H.ESTIMADO_PSU
	          ,H.ESTIMADO_ESP
	          ,H.ESTIMADO_UDD
	          ,H.MATRICULA_BACH_UDD
	          ,H.ESTIMADO_BACH_UDD
	END
	ELSE
	BEGIN
	    SELECT H.CODSEDE AS SEDE
	          ,H.CODCARR AS CODIGO
	          ,H.CARRERA AS [NOMBRE CARRERA]
	          ,H.META_PSU_PPTO AS [META PSU]	--META PSU (1)
	          ,H.META_ESP_PPTO AS [META AE]	--META AE  (2)
	          ,H.META_BACH_UDD_PPTO AS [META BACH]	--META BACH (3)
	          ,H.META_UDD AS [META TOTAL]	--META TOTAL (PSU+AE+BACH) (4)
	          
	          ,H.MATRICULA_PSU AS [MAT.PSU]	--MAT. PSU A LA FECHA (1)
	          ,H.MATRICULA_ESP AS [MAT.AE]	--MAT. AE  A LA FECHA (2)
	          ,H.MATRICULA_BACH_UDD	AS [MAT.BACH]--MAT. BACH. A LA FECHA (3)
	          ,H.MATRICULA_UDD AS [MAT.TOTAL]	--MAT. TOTAL  (PSU+AE+BACH) A LA FECHA (4)
	          ,ISNULL(H.ESTIMADO_PSU,0) AS[ESTIMADO PSU]	--MAT. EST. DIR. DE CARR. PSU   (1)
	          ,ISNULL(H.ESTIMADO_ESP,0) AS [ESTIMADO AE]	--MAT. EST. DIR. DE CARR. AE    (2)
	          ,ISNULL(H.ESTIMADO_BACH_UDD,0) AS [ESTIMADO BACH.]	--MAT. EST. DIR DE CARR. BACH. (3)
	          ,ISNULL(H.ESTIMADO_UDD,0) AS[ESTIMADO TOTAL]	--MAT. EST. DIR. DE CARR. TOTAL (4)
	          
	          
	          ,SUM(H.MAT_PSU_ANTERIOR)   AS [MAT. PSU ANTERIOR]	--MAT.PSU AÑO ANT. (HORA SELEC.) (1)
	          ,SUM(H.MAT_ESP_ANTERIOR)   AS [MAT. AE ANTERIOR]	--
	          ,SUM(H.MAT_BACH_ANTERIOR)  AS [MAT. BACH. ANTERIOR]	--
	          ,SUM(H.MAT_UDD_ANTERIOR)   AS [MAT TOTAL ANTERIOR]	--
	          
	          
	          ,MAX(H.MAT_CIERRE_PSU)     AS [MAT. PSU CIERRE]	--MAT. PSU   AÑO ANT. (CIERRE DEL PROC.) (1)
	          ,MAX(H.MAT_CIERRE_ESP)     AS [MAT AE CIERRE]--MAT. AE    AÑO ANT. (CIERRE DEL PROC.) (2)
	          ,MAX(H.MAT_CIERRE_BACH)    AS [MAT BACH. CIERRE] --MAT. BACH. AÑO ANT. (CIERRE DEL PROC.) (3)
	          
	          ,CONVERT(VARCHAR(10),GETDATE(),103) AS [FECHA DEL REPORTE]
	          ,CONVERT(VARCHAR(8), GETDATE(), 108)  AS [HORA DEL REPORTE]
	    
	    FROM   (
	               SELECT tir.CODSEDE
	                     ,tir.CODCARR
	                     ,tir.CARRERA
	                     ,tir.META_PSU_PPTO
	                     ,tir.META_ESP_PPTO
	                     ,tir.META_UDD
	                     ,tir.META_BACH_UDD_PPTO
	                     ,tir.MATRICULA_PSU
	                     ,tir.MATRICULA_ESP
	                     ,tir.MATRICULA_UDD
	                     ,tir.ESTIMADO_PSU
	                     ,tir.ESTIMADO_ESP
	                     ,tir.ESTIMADO_UDD
	                     ,tir.MATRICULA_BACH_UDD
	                     ,tir.ESTIMADO_BACH_UDD
	                     ,COALESCE(AHPD.MAT_PSU ,0) AS MAT_PSU_ANTERIOR
	                     ,COALESCE(AHPD.MAT_ESP ,0) AS MAT_ESP_ANTERIOR
	                     ,COALESCE(AHPD.MAT_UDD ,0) AS MAT_UDD_ANTERIOR
	                     ,COALESCE(AHPD.MAT_BACH ,0) AS MAT_BACH_ANTERIOR
	                     ,COALESCE(AHPD.MAT_CIERRE_PSU ,0) AS MAT_CIERRE_PSU
	                     ,COALESCE(AHPD.MAT_CIERRE_ESP ,0) AS MAT_CIERRE_ESP
	                     ,COALESCE(AHPD.MAT_CIERRE_BACH ,0) AS MAT_CIERRE_BACH
	               FROM   @TmpInfoRector tir
	                      LEFT JOIN matricula.ADM_HISTORICO_POR_DIA AHPD
	                           ON  AHPD.CODCARR = TIR.CODCARR
	                               AND AHPD.ANO = @ANOPROCESO - 1
	                               AND AHPD.PERIODO = @PERIODOPROCESO
	                               AND
	                               (
	                                (AHPD.DIA < @DIA OR @DIA IS NULL) 
									OR
	                                (ahpd.DIA = @DIA and AHPD.HORA_FIN <= @HORA_FIN ) 
	                                )
	               WHERE  tir.CODCARR IN (SELECT AUAC.CODCARR
	                                      FROM   ADM_USUARIO_ASIGNACION_CARRERA 
	                                             AUAC
	                                      WHERE  AUAC.CODCARR = tir.CODCARR
	                                             AND AUAC.ID_USUARIO = @USUARIO
	                                             OR @USUARIO IS NULL)
	                      AND (tir.CODSEDE = @CODSEDE OR @CODSEDE IS NULL)
	           )                         AS H
	    GROUP BY
	           H.CODSEDE
	          ,H.CODCARR
	          ,H.CARRERA
	          ,H.META_PSU_PPTO
	          ,H.META_ESP_PPTO
	          ,H.META_UDD
	          ,H.META_BACH_UDD_PPTO
	          ,H.MATRICULA_PSU
	          ,H.MATRICULA_ESP
	          ,H.MATRICULA_UDD
	          ,H.ESTIMADO_PSU
	          ,H.ESTIMADO_ESP
	          ,H.ESTIMADO_UDD
	          ,H.MATRICULA_BACH_UDD
	          ,H.ESTIMADO_BACH_UDD
	END
END

