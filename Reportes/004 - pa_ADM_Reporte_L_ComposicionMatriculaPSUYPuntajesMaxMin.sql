USE [matricula]
GO
/****** Object:  StoredProcedure [matricula].[pa_ADM_Reporte_L_ComposicionMatriculaPSUYPuntajesMaxMin]    Script Date: 09-11-2016 15:08:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/************************************************************
 * ROBERTO LARRONDE RYBERTT
 * Fecha: 12-12-2012 11:02:49
 ************************************************************/

--EXEC pa_ADM_Reporte_L_ComposicionMatriculaPSUYPuntajesMaxMin 'CONCEPCION','1200C',NULL

ALTER PROCEDURE [matricula].[pa_ADM_Reporte_L_ComposicionMatriculaPSUYPuntajesMaxMin](
    @CODSEDE     VARCHAR(30) = NULL,
    @CARRERA     VARCHAR(30) = NULL,
    @USUARIO     VARCHAR(50) = NULL
)
AS
BEGIN
	DECLARE @ANOPROCESO         INT,
	        @ANOPROCESOANT      INT,
	        @PERIODOPROCESO     INT
	
	SELECT @ANOPROCESO = MATRICULA.FN_OBTIENEANOPERIODO('A', 'M'),
	       @PERIODOPROCESO = 1
	       	
	DECLARE @TMP TABLE (
	            SEDE VARCHAR(30),
	            CODCARR VARCHAR(30),
	            COD_DEMRE VARCHAR(30),
	            NOMBRE VARCHAR(100),
	            CUPO_OFICIAL INT,
	            CUPO_SOBRECUPO INT,
	            CUPO_ADM_ESP_TOTAL INT,
	            CUPOS_UDD INT,
	            CONVOCADOS INT,
	            ACEPTADOS_ADM_ESP INT,
	            META_CUPO_OFICIAL INT,
	            META_ADM_ESP_TOT INT,
	            META_UDD INT,
	            MAT_PSU_TOT INT,
	            MAT_CO INT,
	            MAX_PJE_CUPO_OFICIAL DECIMAL(5, 2),
	            MIN_PJE_CUPO_OFICIAL DECIMAL(5, 2),
	            MAT_SOBRECUPO INT,
	            MAX_PJE_SOBRECUPO DECIMAL(5, 2),
	            MIN_PJE_SOBRECUPO DECIMAL(5, 2),
	            MAT_LE INT,
	            MAX_PJE_LISTA_ESPERA DECIMAL(5, 2),
	            MIN_PJE_LISTA_ESPERA DECIMAL(5, 2),
	            MAT_AE_10 INT,
	            MAT_AE INT,
	            MAT_AE_TOT INT,
	            TOTAL_UDD INT,
	            MAT_SEGUNDACARR INT,
	            MAT_BEA INT,
	            MATR_CO_SC_LE_BEA INT,
	            MATR_REPOSTULACION INT,
	            MATR_EN_PROCESO INT,
	            MATRICULA_CON_ACUERDO INT,
	            PJE_ULT_MATRICULADO_ANO_ANT DECIMAL(5, 2)
	        )
	
	
	INSERT INTO @TMP
	SELECT mc.SEDE
	      ,mc.CODCARR
	      ,amc.COD_DEMRE
	      ,mc.NOMBRE_C
	      ,MP.VACANTE_REGULAR
	      ,MP.VACANTE_SOBRECUPO
	      ,MP.VACANTE_ESPECIAL
	      ,(
	           MP.VACANTE_REGULAR + MP.VACANTE_SOBRECUPO + MP.VACANTE_ESPECIAL
	       )          AS META_UDD
	      ,0
	      ,0
	      ,MP.META_OFICIAL
	      ,MP.META_ADMESP
	      ,MP.META_CARRERA
	      ,0
	      ,0
	      ,NULL
	      ,NULL
	      ,0
	      ,NULL
	      ,NULL
	      ,0
	      ,NULL
	      ,NULL
	      ,0
	      ,0
	      ,0
	      ,0
	      ,0
	      ,0
	      ,0
	      ,0
	      ,0
	      ,0
	      ,NULL
	FROM   MT_CARRER  AS MC
	       INNER JOIN MT_CARRER_CLASIFICACION AS MCC
	            ON  MCC.CODCARR = MC.CODCARR
	                AND MCC.CODTIPO = 2
	                AND @ANOPROCESO BETWEEN MCC.ANO_INI AND MCC.ANO_FIN
	       LEFT JOIN db_admision.dbo.ADM_MAE_CARRERA AS amc
	            ON  amc.CODCARR = MCC.CODCARR
	       LEFT JOIN MT_PJECORTEPONDERADOCARRERA AS mp
	            ON  mp.CODCARR = MC.CODCARR
	                AND mp.ANO = @ANOPROCESO
	                AND mp.PERIODO = @PERIODOPROCESO		
		   
	
	--DB_ADMISION.DBO.ADM_MAE_CARRERA AMC
	--       INNER JOIN ADM_MAE_SEDE AMS
	--            ON  AMS.CODSEDE = AMC.CODSEDE
	--        INNER JOIN MT_CARRER_CLASIFICACION AS mcc 
	--			ON mcc.CODCARR = AMC.CODCARR
	--				AND mcc.CODTIPO=2
	--				AND @ANOPROCESO BETWEEN mcc.ANO_INI AND mcc.ANO_FIN    
	--       LEFT JOIN MT_PJECORTEPONDERADOCARRERA MP
	--            ON  MP.CODCARR = AMC.CODCARR
	--            AND MP.ANO = @ANOPROCESO
	--            AND MP.PERIODO = @PERIODOPROCESO
	--WHERE  AMC.CODCARR <> 'GLOBAL'
	--       AND AMC.VIGENTE = 1
	
	
	--- TOTAL CONVOCADOS ---
	UPDATE TR2
	SET    TR2.CONVOCADOS = P.CUENTA
	FROM   (
	           SELECT COUNT(CODCLI) AS CUENTA,
	                  ADP.CODCARR
	           FROM   ADM_DATOS_POSTULANTES ADP
	           WHERE  ESTADO = 'A'
	           GROUP BY
	                  ADP.CODCARR
	       ) P
	       INNER JOIN @TMP TR2
	            ON  P.CODCARR = TR2.CODCARR
	
	
	---- CUPO OFICIAL ----
	UPDATE TR2
	SET    TR2.MAT_CO = P.CUENTA
	FROM   (
	           SELECT COUNT(A.RUT) AS CUENTA,
	                  A.CODCARPR
	           FROM   MT_ALUMNO A
	                  INNER JOIN MT_POSCAR P
	                       ON  P.CODPOSTUL = A.RUT
	                       AND P.CODCARR = A.CODCARPR
	                       AND P.ANO = A.ANO
	                       AND P.PERIODO = A.PERIODO
	                       AND COALESCE(P.LUGARENLISTA, 0) <= (
	                               SELECT J.VACANTE_REGULAR
	                               FROM   MT_PJECORTEPONDERADOCARRERA J
	                               WHERE  J.CODCARR = A.CODCARPR
	                                      AND J.ANO = A.ANO
	                                      AND J.PERIODO = A.PERIODO
	                           )
	                  INNER JOIN MT_VIADMISION V
	                       ON  V.COD_VIA = A.COD_VIA
	                       AND V.CODTIPOADMISION = 1
	                       AND V.COD_VIA <> '30'
	           WHERE  A.ANO_MAT = @ANOPROCESO
	                  AND A.PERIODO_MAT = @PERIODOPROCESO
	                  AND A.ANO = A.ANO_MAT
	                  AND A.PERIODO = A.PERIODO_MAT
	                  AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           GROUP BY
	                  A.CODCARPR
	       ) P
	       INNER JOIN @TMP TR2
	            ON  TR2.CODCARR = P.CODCARPR
	
	--- MIN PTJE CO ---
	
	UPDATE TR2
	SET    TR2.MAX_PJE_CUPO_OFICIAL = MAXIMO,
	       TR2.MIN_PJE_CUPO_OFICIAL = MINIMO
	FROM   (
	           SELECT MAX(X.PJEPOND)  AS MAXIMO,
	                  MIN(X.PJEPOND)  AS MINIMO,
	                  X.CODCARR
	           FROM   (
	                      SELECT P.POND AS PJEPOND,
	                             A.CODCARPR AS CODCARR
	                      FROM   MT_ALUMNO A
	                             INNER JOIN MT_POSCAR P
	                                  ON  P.CODPOSTUL = A.RUT
	                                  AND P.CODCARR = A.CODCARPR
	                                  AND P.ANO = A.ANO
	                                  AND P.PERIODO = A.PERIODO
	                                  AND P.LUGARENLISTA <= (
	                                          SELECT J.VACANTE_REGULAR
	                                          FROM   MT_PJECORTEPONDERADOCARRERA 
	                                                 J
	                                          WHERE  J.CODCARR = A.CODCARPR
	                                                 AND J.ANO = A.ANO
	                                                 AND J.PERIODO = A.PERIODO
	                                      )
	                             INNER JOIN MT_VIADMISION V
	                                  ON  V.COD_VIA = A.COD_VIA
	                                  AND V.CODTIPOADMISION = 1
	                                  AND V.COD_VIA <> '30'
	                      WHERE  A.ANO_MAT = @ANOPROCESO
	                             AND A.PERIODO_MAT = @PERIODOPROCESO
	                             AND A.ANO = A.ANO_MAT
	                             AND A.PERIODO = A.PERIODO_MAT
	                             AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	                  )                  X
	           GROUP BY
	                  X.CODCARR
	       ) P
	       INNER JOIN @TMP tR2
	            ON  TR2.CODCARR = P.CODCARR 
	
	--- SOBRECUPO ---
	UPDATE TR2
	SET    TR2.MAT_SOBRECUPO = P.CUENTA
	FROM   (
	           SELECT COUNT(A.RUT) AS CUENTA,
	                  A.CODCARPR
	           FROM   MT_ALUMNO A
	                  INNER JOIN MT_POSCAR P
	                       ON  P.CODPOSTUL = A.RUT
	                       AND P.CODCARR = A.CODCARPR
	                       AND P.ANO = A.ANO
	                       AND P.PERIODO = A.PERIODO
	                       AND COALESCE(P.LUGARENLISTA, 0) > /*BETWEEN*/(
	                               SELECT J.VACANTE_REGULAR --+ 1
	                               FROM   MT_PJECORTEPONDERADOCARRERA J
	                               WHERE  J.CODCARR = A.CODCARPR
	                                      AND J.ANO = A.ANO
	                                      AND J.PERIODO = A.PERIODO
	                           ) 
	                           --AND (
	                           --    SELECT J.VACANTE_REGULAR + J.VACANTE_SOBRECUPO
	                           --    FROM   MT_PJECORTEPONDERADOCARRERA J
	                           --    WHERE  J.CODCARR = A.CODCARPR
	                           --           AND J.ANO = A.ANO
	                           --           AND J.PERIODO = A.PERIODO
	                           --)
	                          AND a.RUT IN (
									SELECT pp.num_doc 
									FROM db_admision.dbo.adm_postulaciones_udd pp 
											INNER JOIN db_admision.dbo.adm_mae_carrera pc 
											ON   pp.COD_CARRERA = pc.COD_DEMRE 
									WHERE pp.ano_proceso=p.ANO 
									AND pc.codcarr=p.CODCARR	
									AND pp.estado_post=24
								)
	                  INNER JOIN MT_VIADMISION V
	                       ON  V.COD_VIA = A.COD_VIA
	                       AND V.CODTIPOADMISION = 1
	                       AND V.COD_VIA <> '30'
	           WHERE  A.ANO_MAT = @ANOPROCESO
	                  AND A.PERIODO_MAT = @PERIODOPROCESO
	                  AND A.ANO = A.ANO_MAT
	                  AND A.PERIODO = A.PERIODO_MAT
	                  AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           GROUP BY
	                  A.CODCARPR
	       ) AS P
	       INNER JOIN @TMP tR2
	            ON  TR2.CODCARR = P.CODCARPR 
	
	
	--- MIN PTJE SC ---
	
	UPDATE TR2
	SET    TR2.MAX_PJE_SOBRECUPO = MAXIMO,
	       TR2.MIN_PJE_SOBRECUPO = MINIMO
	FROM   (
	           SELECT MAX(X.PJEPOND)  AS MAXIMO,
	                  MIN(X.PJEPOND)  AS MINIMO,
	                  X.CODCARR
	           FROM   (
	                      SELECT P.POND AS PJEPOND,
	                             A.CODCARPR AS CODCARR
	                      FROM   MT_ALUMNO A
	                             INNER JOIN MT_POSCAR P
	                                  ON  P.CODPOSTUL = A.RUT
	                                  AND P.CODCARR = A.CODCARPR
	                                  AND P.ANO = A.ANO
	                                  AND P.PERIODO = A.PERIODO
	                                  AND P.LUGARENLISTA> /*BETWEEN*/ (
	                                          SELECT J.VACANTE_REGULAR --+ 1
	                                          FROM   MT_PJECORTEPONDERADOCARRERA 
	                                                 J
	                                          WHERE  J.CODCARR = A.CODCARPR
	                                                 AND J.ANO = A.ANO
	                                                 AND J.PERIODO = A.PERIODO
	                                      ) 
	                                      --AND (
	                                      --    SELECT J.VACANTE_REGULAR + J.VACANTE_SOBRECUPO
	                                      --    FROM   MT_PJECORTEPONDERADOCARRERA 
	                                      --           J
	                                      --    WHERE  J.CODCARR = A.CODCARPR
	                                      --           AND J.ANO = A.ANO
	                                      --           AND J.PERIODO = A.PERIODO
	                                      --)
	                                      AND a.RUT IN (
														SELECT pp.num_doc 
														FROM db_admision.dbo.adm_postulaciones_udd pp 
																INNER JOIN db_admision.dbo.adm_mae_carrera pc 
																ON   pp.COD_CARRERA = pc.COD_DEMRE 
														WHERE pp.ano_proceso=p.ANO 
															AND pc.codcarr=p.CODCARR	
															AND pp.estado_post=24
														)
	                             INNER JOIN MT_VIADMISION V
	                                  ON  V.COD_VIA = A.COD_VIA
	                                  AND V.CODTIPOADMISION = 1
	                                  AND V.COD_VIA <> '30'
	                      WHERE  A.ANO_MAT = @ANOPROCESO
	                             AND A.PERIODO_MAT = @PERIODOPROCESO
	                             AND A.ANO = A.ANO_MAT
	                             AND A.PERIODO = A.PERIODO_MAT
	                             AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	                  )                  X
	           GROUP BY
	                  X.CODCARR
	       ) P
	       INNER JOIN @TMP tR2
	            ON  TR2.CODCARR = P.CODCARR 
	
	
	
	--- LISTA ESPERA ---
	
	UPDATE TR2
	SET    TR2.MAT_LE = P.CUENTA
	FROM   (
	           SELECT COUNT(A.RUT) AS CUENTA,
	                  A.CODCARPR
	           FROM   MT_ALUMNO A
	                  INNER JOIN MT_POSCAR P
	                       ON  P.CODPOSTUL = A.RUT
	                       AND P.CODCARR = A.CODCARPR
	                       AND P.ANO = A.ANO
	                       AND P.PERIODO = A.PERIODO
	                       --AND COALESCE(P.LUGARENLISTA, 0) > (
	                       --        SELECT J.VACANTE_REGULAR + J.VACANTE_SOBRECUPO
	                       --        FROM   MT_PJECORTEPONDERADOCARRERA J
	                       --        WHERE  J.CODCARR = A.CODCARPR
	                       --               AND J.ANO = A.ANO
	                       --               AND J.PERIODO = A.PERIODO
	                       --    )
	                       AND a.RUT IN (
										SELECT pp.num_doc 
										FROM db_admision.dbo.adm_postulaciones_udd pp 
												INNER JOIN db_admision.dbo.adm_mae_carrera pc 
												ON   pp.COD_CARRERA = pc.COD_DEMRE 
										WHERE pp.ano_proceso=p.ANO 
											AND pc.codcarr=p.CODCARR	
											AND pp.estado_post=25
										)
	                  INNER JOIN MT_VIADMISION V
	                       ON  V.COD_VIA = A.COD_VIA
	                       AND V.CODTIPOADMISION = 1
	                       AND V.COD_VIA <> '30'
	           WHERE  A.ANO_MAT = @ANOPROCESO
	                  AND A.PERIODO_MAT = @PERIODOPROCESO
	                  AND A.ANO = A.ANO_MAT
	                  AND A.PERIODO = A.PERIODO_MAT
	                  AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           GROUP BY
	                  A.CODCARPR
	       ) P
	       INNER JOIN @TMP tR2
	            ON  TR2.CODCARR = P.CODCARPR
	
	
	--- MIN PTJE LE ---
	
	UPDATE TR2
	SET    TR2.MAX_PJE_LISTA_ESPERA = MAXIMO,
	       TR2.MIN_PJE_LISTA_ESPERA = MINIMO
	FROM   (
	           SELECT MAX(X.PJEPOND)  AS MAXIMO,
	                  MIN(X.PJEPOND)  AS MINIMO,
	                  X.CODCARR
	           FROM   (
	                      SELECT P.POND AS PJEPOND,
	                             A.CODCARPR AS CODCARR
	                      FROM   MT_ALUMNO A
	                             INNER JOIN MT_POSCAR P
	                                  ON  P.CODPOSTUL = A.RUT
	                                  AND P.CODCARR = A.CODCARPR
	                                  AND P.ANO = A.ANO
	                                  AND P.PERIODO = A.PERIODO
	                                  --AND P.LUGARENLISTA > (
	                                  --        SELECT J.VACANTE_REGULAR + J.VACANTE_SOBRECUPO
	                                  --        FROM   MT_PJECORTEPONDERADOCARRERA 
	                                  --               J
	                                  --        WHERE  J.CODCARR = A.CODCARPR
	                                  --               AND J.ANO = A.ANO
	                                  --               AND J.PERIODO = A.PERIODO
	                                  --    )
	                                  
	                                  AND a.RUT IN (
													SELECT pp.num_doc 
													FROM db_admision.dbo.adm_postulaciones_udd pp 
															INNER JOIN db_admision.dbo.adm_mae_carrera pc 
															ON   pp.COD_CARRERA = pc.COD_DEMRE 
													WHERE pp.ano_proceso=p.ANO 
														AND pc.codcarr=p.CODCARR	
														AND pp.estado_post=25
														)
	                             INNER JOIN MT_VIADMISION V
	                                  ON  V.COD_VIA = A.COD_VIA
	                                  AND V.CODTIPOADMISION = 1
	                                  AND V.COD_VIA <> '30'
	                      WHERE  A.ANO_MAT = @ANOPROCESO
	                             AND A.PERIODO_MAT = @PERIODOPROCESO
	                             AND A.ANO = A.ANO_MAT
	                             AND A.PERIODO = A.PERIODO_MAT
	                             AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	                             AND A.RUT IN (SELECT D.CODCLI
	                                           FROM   ADM_DATOS_POSTULANTES D
	                                           WHERE  D.CODCLI = A.RUT
	                                                  AND D.CODCARR = A.CODCARPR
	                                                  AND D.ESTADO = 'P')
	                  )                  X
	           GROUP BY
	                  X.CODCARR
	       ) P
	       INNER JOIN @TMP tR2
	            ON  TR2.CODCARR = P.CODCARR 
	
	
	--- TOTAL MAT PSU ---
	
	UPDATE @TMP
	SET    MAT_PSU_TOT = (MAT_CO + MAT_SOBRECUPO + MAT_LE)
	
	
	--- ADMISION ESPECIAL 15% ---
	
	UPDATE TR2
	SET    TR2.MAT_AE_10 = P.CUENTA
	FROM   (
	           SELECT COUNT(A.RUT) AS CUENTA,
	                  A.CODCARPR
	           FROM   MATRICULA.MT_ALUMNO A
	                  INNER JOIN MATRICULA.MT_VIADMISION V
	                       ON  V.COD_VIA = COALESCE(A.COD_VIA, A.COD_VIA)
	                       AND V.COD_VIA IN ('10', '15', '16', '24', '33', '34', '38', '35', '41')
	                  INNER JOIN MATRICULA.MT_POSCAR P
	                       ON  P.CODPOSTUL = A.RUT
	                       AND P.CODCARR = A.CODCARPR
	                       AND P.ANO = A.ANO
	                       AND P.PERIODO = A.PERIODO
	           WHERE  A.ANO_MAT = @ANOPROCESO
	                  AND A.PERIODO_MAT = @PERIODOPROCESO
	                  AND A.ANO = A.ANO_MAT
	                  AND A.PERIODO = A.PERIODO_MAT
	                  AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           GROUP BY
	                  A.CODCARPR
	       ) P
	       INNER JOIN @TMP tR2
	            ON  TR2.CODCARR = P.CODCARPR
	
	--- ADMISION ESPECIAL ---
	UPDATE TR2
	SET    TR2.MAT_AE = P.CUENTA
	FROM   (
	           SELECT COUNT(A.RUT) AS CUENTA,
	                  A.CODCARPR
	           FROM   MATRICULA.MT_ALUMNO A
	                  INNER JOIN MATRICULA.MT_VIADMISION V
	                       ON  V.COD_VIA = COALESCE(A.COD_VIA, A.COD_VIA)
	                       AND V.COD_VIA IN ('36', '20', '22', '23', '25', '26', 
	                                        '28', '2', '8', '27', '30')
	                  INNER JOIN MATRICULA.MT_POSCAR P
	                       ON  P.CODPOSTUL = A.RUT
	                       AND P.CODCARR = A.CODCARPR
	                       AND P.ANO = A.ANO
	                       AND P.PERIODO = A.PERIODO
	           WHERE  A.ANO_MAT = @ANOPROCESO
	                  AND A.PERIODO_MAT = @PERIODOPROCESO
	                  AND A.ANO = A.ANO_MAT
	                  AND A.PERIODO = A.PERIODO_MAT
	                  AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           GROUP BY
	                  A.CODCARPR
	       ) P
	       INNER JOIN @TMP tR2
	            ON  TR2.CODCARR = P.CODCARPR 
	
	
	--- TOTAL MATRICULA ADM. ESPECIAL ----
	
	UPDATE @TMP
	SET    MAT_AE_TOT = MAT_AE_10 + MAT_AE
	
	-- TOTAL MATRICULAS UDD --	
	UPDATE @TMP
	SET    TOTAL_UDD = MAT_PSU_TOT + MAT_AE_TOT
	
	--- SEGUNDA CARRERA ---
	
	UPDATE TR2
	SET    TR2.MAT_SEGUNDACARR = P.CUENTA
	FROM   (
	           SELECT COUNT(CODCLI) AS CUENTA,
	                  A.CODCARPR
	           FROM   MT_ALUMNO A
	                  INNER JOIN ADM_MAE_CARRERA C
	                       ON  C.CODCARR = A.CODCARPR
	                       AND C.VIGENTE = 1
	           WHERE  A.ESTACAD NOT IN ('ELIMINADO', 'RETRACTADO')
	                  AND A.ANO = @ANOPROCESO
	                  AND A.PERIODO = @PERIODOPROCESO
	                  AND A.ANO_MAT = A.ANO
	                  AND A.PERIODO_MAT = A.PERIODO
	                  AND A.COD_VIA = 27
	           GROUP BY
	                  A.CODCARPR
	       ) P
	       INNER JOIN @TMP tR2
	            ON  tR2.CODCARR = P.CODCARPR 
	--- MAT BEA ---
	
	UPDATE TR2
	SET    TR2.MAT_BEA = P.CUENTA
	FROM   (
	           SELECT COUNT(A.RUT) AS CUENTA,
	                  A.CODCARPR
	           FROM   MATRICULA.MT_ALUMNO A
	                  INNER JOIN MATRICULA.MT_POSCAR P
	                       ON  P.CODPOSTUL = A.RUT
	                       AND P.CODCARR = A.CODCARPR
	                       AND P.ANO = A.ANO
	                       AND P.PERIODO = A.PERIODO
	                  INNER JOIN ADM_DATOS_POSTULANTES ADP
	                       ON  p.CODPOSTUL = adp.CODCLI
	                       AND adp.CODCARR = p.CODCARR
	           WHERE  A.ANO_MAT = @ANOPROCESO
	                  AND A.PERIODO_MAT = @PERIODOPROCESO
	                  AND A.ANO = A.ANO_MAT
	                  AND A.PERIODO = A.PERIODO_MAT
	                  AND (LTRIM(RTRIM(A.COD_VIA)) = '30')
	                      --AND (LTRIM(RTRIM(A.COD_VIA)) = '30' OR ADP.TIENE_BEA = 1) -- OLD
	                  AND ADP.ESTADO = 'P'
	           GROUP BY
	                  A.CODCARPR
	       ) P
	       INNER JOIN @TMP tR2
	            ON  TR2.CODCARR = P.CODCARPR 
	
	-- TOTAL CO,SC,LE,BEA
	
	UPDATE @TMP
	SET    MATR_CO_SC_LE_BEA = MAT_PSU_TOT + MAT_BEA
	
	--- MAT. REPOSTULACION
	UPDATE TR2
	SET    TR2.MATR_REPOSTULACION = P.CUENTA
	FROM   (
	           SELECT COUNT(A.RUT) AS CUENTA,
	                  A.CODCARPR
	           FROM   MATRICULA.MT_ALUMNO A	                 
	                  INNER JOIN MATRICULA.ADM_MAE_CARRERA C
	                       ON  A.CODCARPR = C.CODCARR	                 
	           WHERE  A.ANO_MAT = @ANOPROCESO
	                  AND A.PERIODO_MAT = @PERIODOPROCESO
	                  AND A.ANO = A.ANO_MAT
	                  AND A.PERIODO = A.PERIODO_MAT
	                  AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	                  AND A.COD_VIA  IN (29) --Via 9: RepostulaciónGROUP BY A.CODCARPR
	           GROUP BY
	                  A.CODCARPR
	       ) P
	       INNER JOIN @TMP tR2
	            ON  TR2.CODCARR = P.CODCARPR 
	
	
	
	---	MATRICULA EN PROCESO
	UPDATE TR2
	SET    TR2.MATR_EN_PROCESO = P.CUENTA
	FROM   (
			 --MODIFICACION PARA MATRICULA EN LINEA
			 
			  SELECT COUNT(*) CUENTA, mpa.CODCARR
	                      FROM   MATRICULA.ML_PROCESO_ALUMNO mpa
	                      WHERE  MPA.ANNO = @ANOPROCESO
	                             AND MPA.PERIODO = @PERIODOPROCESO	                               
	                             AND (MPA.CODCARR = @CARRERA OR @CARRERA IS NULL)
	                             AND MPA.TIPO = 'Nuevo'
	                             AND mpa.RUT_ALUMNO NOT IN (SELECT a.RUT
	                                                        FROM   MATRICULA.MT_ALUMNO 
	                                                               a
	                                                        WHERE  a.ANO_MAT = @ANOPROCESO
	                                                               AND a.PERIODO_MAT = 
	                                                                @PERIODOPROCESO
	                                                               AND a.ESTACAD 
	                                                                   IN ('VIGENTE', 'SUSPENDIDO')
	                                                               AND A.CODCARPR = 
	                                                                   MPA.CODCARR )
	                                                                   --@CARRERA OR @CARRERA IS NULL)
			 
			 
			 GROUP BY MPA.CODCARR
				 
				 --SELECT COUNT(*) CUENTA, mpa.CODCARR 
	    --                  FROM   MATRICULA.ML_PROCESO_ALUMNO mpa
	    --                  WHERE  MPA.ANNO = @ANOPROCESO
	    --                         AND MPA.PERIODO = @PERIODOPROCESO
	    --                         AND MPA.CODCARR = @CARRERA
	    --                         AND MPA.TIPO = 'Nuevo'
	    --                         AND mpa.RUT_ALUMNO NOT IN (SELECT a.RUT
	    --                                                    FROM   MATRICULA.MT_ALUMNO 
	    --                                                           a
	    --                                                    WHERE  a.ANO_MAT = @ANOPROCESO
	    --                                                           AND a.PERIODO_MAT = 
	    --                                                           @PERIODOPROCESO
	    --                                                           AND a.ESTACAD 
	    --                                                               IN ('VIGENTE', 'SUSPENDIDO')
	    --                                                           AND A.CODCARPR = 
	    --                                                               @CARRERA)
				 --GROUP BY MPA.CODCARR
	       ) P
	       INNER JOIN @TMP tR2
	            ON  TR2.CODCARR = P.CODCARR 	 
	--- MATRICULA CON ACUERDO
	UPDATE TR2
	SET    TR2.MATRICULA_CON_ACUERDO = P.CUENTA
	FROM   (
	           SELECT COUNT(CODCLI)  AS CUENTA,
	                  A.CODCARPR
	           FROM   MT_ALUMNO         A
	           WHERE  A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	                  AND A.ANO = @ANOPROCESO
	                  AND A.PERIODO = @PERIODOPROCESO
	                  AND A.ANO_MAT = A.ANO
	                  AND A.PERIODO_MAT = A.PERIODO
	                  AND LTRIM(RTRIM(COD_VIA)) = 37
	           GROUP BY
	                  A.CODCARPR
	       ) P
	       INNER JOIN @TMP tR2
	            ON  TR2.CODCARR = P.CODCARPR 
	
	--- POND ULTIMO MATRICULADO AÑO ANTERIOR
	
	UPDATE TR2
	SET    TR2.PJE_ULT_MATRICULADO_ANO_ANT = P.PTJEPONDANTERIOR
	FROM   (
	           SELECT CASE 
	                       WHEN MP2.PTJEPONDANTERIOR > 0 THEN MP2.PTJEPONDANTERIOR
	                       ELSE NULL
	                  END AS PTJEPONDANTERIOR,
	                  MP2.CODCARR
	           FROM   MT_PJECORTEPONDERADOCARRERA MP2
	           WHERE  MP2.ANO = @ANOPROCESO
	                  AND MP2.PERIODO = @PERIODOPROCESO
	           GROUP BY
	                  MP2.CODCARR,
	                  MP2.PTJEPONDANTERIOR
	       ) P
	       INNER JOIN @TMP tR2
	            ON  TR2.CODCARR = P.CODCARR
	
	
	SELECT T.SEDE,
	       T.CODCARR,
	       T.COD_DEMRE,
	       T.NOMBRE,
	       T.CUPO_OFICIAL,
	       T.CUPO_SOBRECUPO  AS SOBRECUPO,
	       T.CUPO_ADM_ESP_TOTAL,
	       T.CUPOS_UDD,
	       T.CONVOCADOS,
	       T.ACEPTADOS_ADM_ESP,
	       T.META_CUPO_OFICIAL,
	       T.META_ADM_ESP_TOT,
	       T.META_UDD,
	       T.MAT_PSU_TOT     AS 'MATR_CO_SC_LE',
	       T.MAT_CO          AS 'MATR_CUPO_OFICIAL',
	       T.MAX_PJE_CUPO_OFICIAL,
	       T.MIN_PJE_CUPO_OFICIAL,
	       T.MAT_SOBRECUPO   AS 'MATR_SOBRECUPO',
	       T.MAX_PJE_SOBRECUPO,
	       T.MIN_PJE_SOBRECUPO,
	       T.MAT_LE          AS 'MATR_LISTA_ESPERA',
	       T.MAX_PJE_LISTA_ESPERA,
	       T.MIN_PJE_LISTA_ESPERA,
	       T.MAT_AE_10,
	       T.MAT_AE,
	       T.MAT_AE_TOT,
	       T.TOTAL_UDD,
	       T.MAT_SEGUNDACARR,
	       T.MAT_BEA         AS 'MATR_BEA',
	       T.MATR_CO_SC_LE_BEA,
	       T.MATR_REPOSTULACION,
	       T.MATR_EN_PROCESO,
	       T.MATRICULA_CON_ACUERDO,
	       T.PJE_ULT_MATRICULADO_ANO_ANT
	FROM   @TMP T
	WHERE  (T.CODCARR = @CARRERA OR @CARRERA IS NULL)
	       AND (T.SEDE = @CODSEDE OR @CODSEDE IS NULL)
	       AND T.CODCARR IN (SELECT AUAC.CODCARR
	                         FROM   ADM_USUARIO_ASIGNACION_CARRERA AUAC
	                         WHERE  AUAC.CODCARR = T.CODCARR
	                                AND AUAC.ID_USUARIO = @USUARIO
	                                OR  @USUARIO IS NULL)
	ORDER BY
	       T.SEDE,
	       T.CODCARR
END




