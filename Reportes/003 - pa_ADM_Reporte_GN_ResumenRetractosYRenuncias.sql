/************************************************************
 * DESCRIPCIÓN			:	Informe de retractados y renunciados
 * AUTOR				:	Jorge Collao Q.
 * Time					:	21-10-2016 12:14:17
 * pa_ADM_Reporte_GN_ResumenRetractosYRenuncias
 ************************************************************/

ALTER PROCEDURE [matricula].[pa_ADM_Reporte_GN_ResumenRetractosYRenuncias](
    @CODSEDE           VARCHAR(30) = NULL
   ,@CODCARR           VARCHAR(30) = NULL
   ,@USUARIO           VARCHAR(50) = NULL
   ,@AÑO_ADMISION      INT = NULL
   ,@DIA_COMPARAR      INT = NULL
   ,@HORA_COMPARAR     INT = NULL
)
AS
BEGIN
	DECLARE @TABLA_FECHAS TABLE (FECHA DATETIME ,ANO INT)
	DECLARE @TABLA_RETRACTADOS TABLE (
	            CODCARR VARCHAR(10)
	           ,RETRACTADOS INT
	           ,AÑO INT
	           ,FECHA DATETIME
	           ,HORA INT
	           ,DIA INT
	           ,TIPO VARCHAR(50)
	           ,SEDE VARCHAR(50)
	           ,CODDEMRE INT
	           ,NOMBRE_CARRERA VARCHAR(100)
	        )
	
	
	INSERT INTO @TABLA_FECHAS
	SELECT MIN(FECHA)
	      ,ahpd.ANO
	FROM   ADM_HISTORICO_POR_DIA AS ahpd
	WHERE  DIA = 1
	GROUP BY
	       ahpd.ANO
	ORDER BY
	       ahpd.ANO ASC
	
	
	IF @AÑO_ADMISION IS NULL
	BEGIN
		SET @AÑO_ADMISION=(SELECT MP.ANOADMISION FROM MT_PARAME AS mp)
	END
	
	INSERT INTO @TABLA_RETRACTADOS
	SELECT T.*
	      ,AMC.COD_DEMRE
	      ,AMC.NOMBRE
	FROM   (
	           SELECT CASE MA.CODCARPR 
							WHEN '1632S' THEN '1633S'
							WHEN '1631S' THEN '1635S'
							ELSE MA.CODCARPR 
					  END AS CODCARR
	                 ,COUNT(CODCLI)  AS RETRACTADOS
	                 ,MA.ANO
	                 ,CONVERT(VARCHAR(10) ,MA.FECHASITU ,103) AS FECHA_RETRACTO
	                 ,DATEPART(HOUR ,MA.FECHASITU) AS HORA
	                 ,DATEDIFF(DAY ,TF.FECHA ,MA.FECHASITU) + 1 AS DIA
	                 ,CASE 
	                       WHEN ma.TIPOSITU = 35 THEN 'RETRACTADO'
	                       ELSE 'RENUNCIADO'
	                  END            AS TIPO
	                 ,MA.CODSEDE
	           FROM   MT_ALUMNO      AS MA
	                  LEFT JOIN @TABLA_FECHAS TF
	                       ON  TF.ANO = MA.ANO
	           WHERE  MA.TIPOSITU IN (35 ,37 ,22)
	                  AND MA.ANO >= @AÑO_ADMISION -3
	                  AND ma.ANO = ma.ANO_MAT
	                  AND ma.PERIODO = ma.PERIODO_MAT
	                      --  AND DATEDIFF(DAY,TF.FECHA,MA.FECHASITU)<=10
	           GROUP BY
	                  MA.CODCARPR
	                 ,MA.ANO
	                 ,CONVERT(VARCHAR(10) ,MA.FECHASITU ,103)
	                 ,DATEPART(HOUR ,MA.FECHASITU)
	                 ,DATEDIFF(DAY ,TF.FECHA ,MA.FECHASITU) + 1
	                 ,TF.FECHA
	                 ,MA.TIPOSITU
	                 ,MA.CODSEDE
	       )T
	       INNER JOIN MT_CARRER_CLASIFICACION AS mcc
					ON  MCC.CODCARR =  T.CODCARR										
					AND MCC.CODTIPO = 2
			LEFT JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA AS amc		  
					ON  AMC.CODCARR =  T.CODCARR
	ORDER BY
	       T.ANO
	      ,T.CODCARR
	      ,T.DIA
	      ,T.FECHA_RETRACTO
	      ,T.HORA
	
	
	INSERT INTO @TABLA_RETRACTADOS
	SELECT amc.codcarr
	      ,0
	      ,@AÑO_ADMISION
	      ,(
	           SELECT fecha
	           FROM   @TABLA_FECHAS
	           WHERE  ANO = @AÑO_ADMISION
	       )
	      ,0
	      ,1
	      ,'RETRACTADO'
	      ,CASE 
	            WHEN AMC.CODSEDE = 1 THEN 'CONCEPCION'
	            ELSE 'SANTIAGO'
	       END
	      ,AMC.COD_DEMRE
	      ,AMC.NOMBRE
	FROM   DB_ADMISION.DBO.ADM_MAE_CARRERA AS amc	 
		INNER JOIN MT_CARRER_CLASIFICACION AS mcc ON MCC.CODCARR=AMC.CODCARR
		AND MCC.CODTIPO=2
	WHERE  AMC.CODCARR NOT IN (SELECT DISTINCT CODCARR
	                           FROM   @TABLA_RETRACTADOS
	                           WHERE  AÑO = @AÑO_ADMISION)
	       AND AMC.CODCARR NOT IN ( 'GLOBAL','1631S','1632S')
	       --AND AMC.VIGENTE = 1 
	
	

	
	SELECT @AÑO_ADMISION       AS ANO
	      ,1                   AS PERIODO
	      ,T.SEDE
	      ,T.CODCARR 
	      ,T.CODDEMRE AS COD_DEMRE
	      ,T.NOMBRE_CARRERA AS NOMBRECARR
	      ,ISNULL(
	           (
	               SELECT SUM(RA.RETRACTADOS)
	               FROM   @TABLA_RETRACTADOS RA
	               WHERE  RA.AÑO = @AÑO_ADMISION
	                      AND RA.CODCARR = T.CODCARR
	                     -- AND (RA.DIA <= @DIA_COMPARAR OR @DIA_COMPARAR IS NULL OR @DIA_COMPARAR=0)
	                     -- AND (RA.HORA <= @HORA_COMPARAR OR @HORA_COMPARAR IS NULL OR @HORA_COMPARAR=0)
	                      AND
	                      (
	                      	(
	                      		RA.DIA<@DIA_COMPARAR 
	                      		OR 
	                      		@DIA_COMPARAR IS NULL
	                      	)
	                      	OR
	                      	(
	                      		RA.DIA=@DIA_COMPARAR 
	                      		AND 
	                      		(RA.HORA<=@HORA_COMPARAR OR @HORA_COMPARAR IS NULL)
	                      	)
	                      )
	                      
	                      AND RA.TIPO = 'RETRACTADO'
	           )
	          ,0
	       )                   AS RANOACTUAL
	      ,ISNULL(
	           (
	               SELECT SUM(RA.RETRACTADOS)
	               FROM   @TABLA_RETRACTADOS RA
	               WHERE  RA.AÑO = @AÑO_ADMISION -1
	                      AND RA.CODCARR = T.CODCARR
	                     -- AND (RA.DIA <= @DIA_COMPARAR OR @DIA_COMPARAR IS NULL)
	                     -- AND (ra.HORA <= @HORA_COMPARAR OR @HORA_COMPARAR IS NULL)
	                       AND
	                      (
	                      	(
	                      		RA.DIA<@DIA_COMPARAR 
	                      		OR 
	                      		@DIA_COMPARAR IS NULL
	                      	)
	                      	OR
	                      	(
	                      		RA.DIA=@DIA_COMPARAR 
	                      		AND 
	                      		(RA.HORA<=@HORA_COMPARAR OR @HORA_COMPARAR IS NULL)
	                      	)
	                      )
	                      AND RA.TIPO = 'RETRACTADO'
	           )
	          ,0
	       )                   AS RETRACANO2
	      ,ISNULL(
	           (
	               SELECT SUM(RA.RETRACTADOS)
	               FROM   @TABLA_RETRACTADOS RA
	               WHERE  RA.AÑO = @AÑO_ADMISION -2
	                      AND RA.CODCARR = T.CODCARR
	                    --  AND (RA.DIA <= @DIA_COMPARAR OR @DIA_COMPARAR IS NULL)
	                    --  AND (ra.HORA <= @HORA_COMPARAR OR @HORA_COMPARAR IS NULL)
	                      AND
	                      (
	                      	(
	                      		RA.DIA<@DIA_COMPARAR 
	                      		OR 
	                      		@DIA_COMPARAR IS NULL
	                      	)
	                      	OR
	                      	(
	                      		RA.DIA=@DIA_COMPARAR 
	                      		AND 
	                      		(RA.HORA<=@HORA_COMPARAR OR @HORA_COMPARAR IS NULL)
	                      	)
	                      )
	                      AND RA.TIPO = 'RETRACTADO'
	           )
	          ,0
	       )                   AS RETRACANO3
	       ----------------------------------------------------------------------------------
	      ,ISNULL(
	           (
	               SELECT SUM(RA.RETRACTADOS)
	               FROM   @TABLA_RETRACTADOS RA
	               WHERE  RA.AÑO = @AÑO_ADMISION
	                      AND RA.CODCARR = T.CODCARR
	                     -- AND (RA.DIA <= @DIA_COMPARAR OR @DIA_COMPARAR IS NULL)
	                     -- AND (ra.HORA <= @HORA_COMPARAR OR @HORA_COMPARAR IS NULL)
	                       AND
	                      (
	                      	(
	                      		RA.DIA<@DIA_COMPARAR 
	                      		OR 
	                      		@DIA_COMPARAR IS NULL
	                      	)
	                      	OR
	                      	(
	                      		RA.DIA=@DIA_COMPARAR 
	                      		AND 
	                      		(RA.HORA<=@HORA_COMPARAR OR @HORA_COMPARAR IS NULL)
	                      	)
	                      )
	                      AND RA.TIPO = 'RENUNCIADO'
	           )
	          ,0
	       )                   AS RENUACTUAL
	      ,ISNULL(
	           (
	               SELECT SUM(RA.RETRACTADOS)
	               FROM   @TABLA_RETRACTADOS RA
	               WHERE  RA.AÑO = @AÑO_ADMISION -1
	                      AND RA.CODCARR = T.CODCARR
	                    --  AND (RA.DIA <= @DIA_COMPARAR OR @DIA_COMPARAR IS NULL)
	                      --AND (ra.HORA <= @HORA_COMPARAR OR @HORA_COMPARAR IS NULL)
	                        AND
	                      (
	                      	(
	                      		RA.DIA<@DIA_COMPARAR 
	                      		OR 
	                      		@DIA_COMPARAR IS NULL
	                      	)
	                      	OR
	                      	(
	                      		RA.DIA=@DIA_COMPARAR 
	                      		AND 
	                      		(RA.HORA<=@HORA_COMPARAR OR @HORA_COMPARAR IS NULL)
	                      	)
	                      )
	                      AND RA.TIPO = 'RENUNCIADO'
	           )
	          ,0
	       )                   AS RENUANO2
	      ,ISNULL(
	           (
	               SELECT SUM(RA.RETRACTADOS)
	               FROM   @TABLA_RETRACTADOS RA
	               WHERE  RA.AÑO = @AÑO_ADMISION -2
	                      AND RA.CODCARR = T.CODCARR
	                      --AND (RA.DIA <= @DIA_COMPARAR OR @DIA_COMPARAR IS NULL)
	                      --AND (ra.HORA <= @HORA_COMPARAR OR @HORA_COMPARAR IS NULL)
	                        AND
	                      (
	                      	(
	                      		RA.DIA<@DIA_COMPARAR 
	                      		OR 
	                      		@DIA_COMPARAR IS NULL
	                      	)
	                      	OR
	                      	(
	                      		RA.DIA=@DIA_COMPARAR 
	                      		AND 
	                      		(RA.HORA<=@HORA_COMPARAR OR @HORA_COMPARAR IS NULL)
	                      	)
	                      )
	                      AND RA.TIPO = 'RENUNCIADO'
	           )
	          ,0
	       )                   AS RENUANO3
	      ,(
	           SELECT COALESCE(COUNT(A.RUT) ,0) AS CUENTA
	           FROM   MT_ALUMNO A
	                  INNER JOIN MT_POSCAR P
	                       ON  P.CODPOSTUL = A.RUT
	                           AND P.CODCARR = A.CODCARPR
	                           AND P.ANO = A.ANO
	                           AND P.PERIODO = A.PERIODO
	                  INNER JOIN MT_MATRICULAS AS MM
	                       ON  A.CODCLI = MM.CODCLI
	                           AND MM.ITEM = 2
	                           AND MM.REMATRICULA IS NULL
	           WHERE  A.ANO_MAT = T.AÑO
	                  AND A.PERIODO_MAT = 1
	                  AND A.ANO = A.ANO_MAT
	                  AND A.PERIODO = A.PERIODO_MAT
	                  AND A.ESTACAD IN ('VIGENTE' ,'SUSPENDIDO')
	                  AND P.CODCARR = T.CODCARR
	       )                   AS MATRICULADOS
	FROM   @TABLA_RETRACTADOS     T
	WHERE  -- T.CODCARR='1300C' --AND
	       T.AÑO = @AÑO_ADMISION
	       AND (T.SEDE = @CODSEDE OR @CODSEDE IS NULL)
	       AND (T.CODCARR = @CODCARR OR @CODCARR IS NULL)
	GROUP BY
	       T.AÑO
	      ,T.SEDE
	      ,T.CODCARR
	      ,T.CODDEMRE
	      ,T.NOMBRE_CARRERA
	ORDER BY
	       T.SEDE
	      ,T.CODCARR
END

--/************************************************************
-- * ROBERTO LARRONDE RYBERTT
-- * Fecha: 12-10-2012 15:38:34
-- ************************************************************/
---- EXEC [pa_ADM_Reporte_GN_ResumenRetractosYRenuncias] 'CONCEPCION','1100C',NULL

--/* modificaciones:
--* autor			: Alexanders Gutierrez
--* fecha			: 04/09/2014
--* descripcion	: optimización completa de consulta para reducción de tiempo de respuesta.
--* EXEC pa_ADM_Reporte_GN_ResumenRetractosYRenuncias
--*
--*/

--ALTER PROCEDURE [matricula].[pa_ADM_Reporte_GN_ResumenRetractosYRenuncias](
--    @CODSEDE     VARCHAR(30) = NULL,
--    @CODCARR     VARCHAR(30) = NULL,
--    @USUARIO     VARCHAR(50) = NULL
--)
--AS
--BEGIN
--	DECLARE @ANOPROCESO         INT,
--	        @PERIODOPROCESO     INT,
--	        @CANTIDAD_ANOS      INT,
--	        @CONTADOR           INT

--	SELECT @ANOPROCESO = MATRICULA.FN_OBTIENEANOPERIODO('A', 'M'),
--	       @PERIODOPROCESO     = 1,
--	       @CANTIDAD_ANOS      = @ANOPROCESO - 2012



--	DECLARE @TMP TABLE(
--	            ANO INT,
--	            SEDE VARCHAR(30),
--	            CODCARR VARCHAR(30),
--	            COD_DEMRE VARCHAR(10),
--	            NOMBRECARR VARCHAR(100),
--	            RETRACTADOS INT,
--	            RENUNCIADOS INT,
--	            MATRICULADOS INT
--	        )

--	--guardamos carrera del proceso y con estado vigentes

--	SET @CONTADOR = 0 -- AÑO ACTUAL
--	WHILE @CONTADOR <= @CANTIDAD_ANOS
--	BEGIN
--	    INSERT INTO @TMP
--	    SELECT @ANOPROCESO - @CONTADOR,
--	           CASE amc.CODSEDE
--	                WHEN 1 THEN 'CONCEPCION'
--	                WHEN 2 THEN 'SANTIAGO'
--	           END              AS SEDE,
--	           amc.CODCARR,
--	           AMC.COD_DEMRE,
--	           AMC.NOMBRE,
--	           RETRACTADOS = (
--	               SELECT COUNT(*)
--	               FROM   MATRICULA.MT_ALUMNO A
--	                      INNER JOIN MATRICULA.MT_VIADMISION V
--	                           ON  V.COD_VIA = COALESCE(A.COD_VIA, A.COD_VIA)
--	               WHERE  A.ANO_MAT = @ANOPROCESO - @CONTADOR
--	                      AND A.PERIODO_MAT = @PERIODOPROCESO
--	                      AND A.ANO = A.ANO_MAT
--	                      AND A.PERIODO = A.PERIODO_MAT
--	                      AND A.TIPOSITU = 35
--	                      AND A.CODCARPR = AMC.CODCARR
--	           ),
--	           RENUNCIADOS = (
--	               SELECT COUNT(*)
--	               FROM   MATRICULA.MT_ALUMNO A
--	                      INNER JOIN MATRICULA.MT_VIADMISION V
--	                           ON  V.COD_VIA = COALESCE(A.COD_VIA, A.COD_VIA)
--	               WHERE  A.ANO_MAT = @ANOPROCESO - @CONTADOR
--	                      AND A.PERIODO_MAT = @PERIODOPROCESO
--	                      AND A.ANO = A.ANO_MAT
--	                      AND A.PERIODO = A.PERIODO_MAT
--	                      AND A.TIPOSITU IN(37,22)
--	                      AND A.CODCARPR = AMC.CODCARR
--	           ),
--	           0
--	           --MATRICULADOS = (
--	           --    SELECT COUNT(*)
--	           --    FROM   MT_ALUMNO A
--	           --           INNER JOIN MT_POSCAR P
--	           --                ON  P.CODPOSTUL = A.RUT
--	           --                AND P.CODCARR = A.CODCARPR
--	           --                AND P.ANO = A.ANO
--	           --                AND P.PERIODO = A.PERIODO
--	           --    WHERE  A.ANO_MAT = @ANOPROCESO
--	           --           AND A.PERIODO_MAT = @PERIODOPROCESO
--	           --           AND A.ANO = A.ANO_MAT
--	           --           AND A.PERIODO = A.PERIODO_MAT
--	           --           AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
--	           --           AND A.CODCARPR = AMC.CODCARR
--	           --) -- ES CONSTANTE EN TODOS LOS AÑOS, YA QUE, ES EL CONTEO PROCESO ACTUAL, HISTORICO MATRICULADO SE REALIZA SOLAMENTE EN REPORTE RECTOR
--	    FROM   ADM_MAE_CARRERA     amc
--	    WHERE  AMC.VIGENTE = 1
--	           AND amc.CODCARR <> 'GLOBAL'
--	    ORDER BY
--	           amc.CODSEDE,
--	           amc.CODCARR

--	    SET @CONTADOR = @CONTADOR + 1
--	END

--	--update y guardamos cantidad de matriculados del proceso
--	UPDATE TR2
--	SET    TR2.MATRICULADOS = P.CUENTA
--	FROM   (
--	           SELECT A.CODCARPR,
--	                  COALESCE(COUNT(A.RUT), 0) AS CUENTA
--	           FROM   MT_ALUMNO A
--	                  INNER JOIN MT_POSCAR P
--	                       ON  P.CODPOSTUL = A.RUT
--	                       AND P.CODCARR = A.CODCARPR
--	                       AND P.ANO = A.ANO
--	                       AND P.PERIODO = A.PERIODO
--	           WHERE  A.ANO_MAT = @ANOPROCESO
--	                  AND A.PERIODO_MAT = @PERIODOPROCESO
--	                  AND A.ANO = A.ANO_MAT
--	                  AND A.PERIODO = A.PERIODO_MAT
--	                  AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
--	           GROUP BY
--	                  A.CODCARPR
--	       ) P
--	       INNER JOIN @TMP TR2
--	            ON  P.CODCARPR = TR2.CODCARR
--	WHERE TR2.ANO = @ANOPROCESO


--	--SELECT TR.ANO,
--	--       @PERIODOPROCESO AS PERIODO,
--	--       TR.SEDE,
--	--       TR.CODCARR,
--	--       TR.COD_DEMRE,
--	--       TR.NOMBRECARR,
--	--       TR.RETRACTADOS,
--	--       TR.RENUNCIADOS,
--	--       TR.MATRICULADOS
--	--FROM   @TMP TR
--	--WHERE  (TR.CODCARR = @CODCARR OR @CODCARR IS NULL)
--	--       AND (TR.SEDE = @CODSEDE OR @CODSEDE IS NULL)
--	--       AND TR.CODCARR IN (SELECT AUAC.CODCARR
--	--                          FROM   ADM_USUARIO_ASIGNACION_CARRERA AUAC
--	--                          WHERE  AUAC.CODCARR = TR.CODCARR
--	--                                 AND AUAC.ID_USUARIO = @USUARIO
--	--                                 OR  @USUARIO IS NULL)
--	--ORDER BY
--	--       TR.SEDE,
--	--       TR.CODCARR,
--	--       TR.ANO


--SELECT @ANOPROCESO AS ANO,
--       @PERIODOPROCESO AS PERIODO,
--       t.SEDE,
--       t.CODCARR,
--       t.COD_DEMRE,
--       t.NOMBRECARR,
--       MIN(CASE WHEN T.ANO = @ANOPROCESO THEN T.RETRACTADOS END) RANOACTUAL,
--       MIN(CASE WHEN T.ANO = @ANOPROCESO - 1 THEN T.RETRACTADOS END) RETRACANO2,
--       MIN(CASE WHEN T.ANO = @ANOPROCESO - 2 THEN T.RETRACTADOS END) RETRACANO3,
--       MIN(CASE WHEN T.ANO = @ANOPROCESO - 3 THEN T.RETRACTADOS END) RETRACANO4,
--       MIN(CASE WHEN T.ANO = @ANOPROCESO - 4 THEN T.RETRACTADOS END) RETRACANO5,
--       MIN(CASE WHEN T.ANO = @ANOPROCESO THEN T.RENUNCIADOS END) RENUACTUAL,
--       MIN(CASE WHEN T.ANO = @ANOPROCESO - 1 THEN T.RENUNCIADOS END) RENUANO2,
--       MIN(CASE WHEN T.ANO = @ANOPROCESO - 2 THEN T.RENUNCIADOS END) RENUANO3,
--       MIN(CASE WHEN T.ANO = @ANOPROCESO - 3 THEN T.RENUNCIADOS END) RENUANO4,
--       MIN(CASE WHEN T.ANO = @ANOPROCESO - 4 THEN T.RENUNCIADOS END) RENUANO5,
--       SUM(t.MATRICULADOS)     MATRICULADOS
--FROM   @TMP                 AS t
--GROUP BY
--       t.SEDE,
--       t.CODCARR,
--       t.COD_DEMRE,
--       t.NOMBRECARR
--END


