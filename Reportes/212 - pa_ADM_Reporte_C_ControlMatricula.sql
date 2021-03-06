USE [matricula]
GO
/****** Object:  StoredProcedure [matricula].[pa_ADM_Reporte_C_ControlMatricula]    Script Date: 12-12-2016 15:22:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/************************************************************
 * ROBERTO LARRONDE RYBERTT
 * Fecha: 17-01-2013 18:58:16
 ************************************************************/

--EXEC pa_ADM_Reporte_C_ControlMatricula 'SANTIAGO',0,NULL
--EXEC pa_ADM_Reporte_C_ControlMatricula 'SANTIAGO',1,NULL

/*
* modificaciones:
* autor			: Alexanders Gutierrez
* fecha			: 05/09/2014
* descripcion	: optimización completa de consulta para reducción de tiempo de respuesta.
* 
* autor			: Alexanders Gutierrez
* fecha			: 11/11/2014
* descripcion	: se agregan nuevas vias de admision proceso 2015, cod_via 44 y 45, que corresponden al admsion especial 15%
* 
* autor			: Alexanders Gutierrez
* fecha			: 11/11/2015
* descripción	: se agrega campo total matriculado Bach proceso 2016
* 
* exec [matricula].[pa_ADM_Reporte_C_ControlMatricula] 'santiago'
*/

ALTER PROCEDURE [matricula].[pa_ADM_Reporte_C_ControlMatricula](
    @CODSEDE     VARCHAR(30) = NULL,
    @RESUMEN     BIT = 1,
    @USUARIO     VARCHAR(50) = NULL
)
AS
BEGIN
	DECLARE @ANOPROCESO         INT,
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
	            MAT_SOBRECUPO INT,
	            MAT_LE INT,
	            MAT_AE_10 INT,
	            MAT_AE INT,
	            MAT_AE_TOT INT,
	            TOTAL_UDD INT,
	            MAT_SEGUNDACARR INT,
	            MAT_BACH INT --2016
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
	       )                        AS META_UDD
	      ,0
	      ,0
	      ,MP.META_OFICIAL
	      ,MP.META_ADMESP
	      ,MP.META_CARRERA
	      ,0
	      ,0
	      ,0
	      ,0
	      ,0
	      ,0
	      ,0
	      ,0
	      ,0
	      ,0 --2016
	FROM   MT_CARRER_CLASIFICACION  AS mcc
	       INNER JOIN MT_CARRER     AS mc
	            ON  mc.CODCARR = mcc.CODCARR
	       LEFT JOIN ADM_MAE_CARRERA AS amc ON amc.CODCARR = mc.CODCARR     
	       LEFT JOIN MT_PJECORTEPONDERADOCARRERA AS mp
	            ON  mp.CODCARR = mc.CODCARR
	                AND mp.ANO = @ANOPROCESO
	                AND mp.PERIODO = @PERIODOPROCESO
	WHERE  mcc.CODTIPO = 2
	       AND @ANOPROCESO BETWEEN mcc.ANO_INI AND mcc.ANO_FIN    
			
--case mc.CODCARR WHEN '1633S' THEN '1632S' WHEN '1635S' THEN '1631S' ELSE mc.CODCARR END
--SELECT * FROM MT_PJECORTEPONDERADOCARRERA AS mp WHERE mp.CODCARR='1505s' AND mp.ANO=2017

--- CONVOCADOS ---	
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
	                       --AND V.COD_VIA <> '30'
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
	                       AND COALESCE(P.LUGARENLISTA, 0) BETWEEN (
	                               SELECT J.VACANTE_REGULAR + 1
	                               FROM   MT_PJECORTEPONDERADOCARRERA J
	                               WHERE  J.CODCARR = A.CODCARPR
	                                      AND J.ANO = A.ANO
	                                      AND J.PERIODO = A.PERIODO
	                           ) AND (
	                               SELECT J.VACANTE_REGULAR + J.VACANTE_SOBRECUPO
	                               FROM   MT_PJECORTEPONDERADOCARRERA J
	                               WHERE  J.CODCARR = A.CODCARPR
	                                      AND J.ANO = A.ANO
	                                      AND J.PERIODO = A.PERIODO
	                           )
	                  INNER JOIN MT_VIADMISION V
	                       ON  V.COD_VIA = A.COD_VIA
	                       AND V.CODTIPOADMISION = 1
	                       --AND V.COD_VIA <> '30'
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
	                       AND COALESCE(P.LUGARENLISTA, 0) > (
	                               SELECT J.VACANTE_REGULAR + J.VACANTE_SOBRECUPO
	                               FROM   MT_PJECORTEPONDERADOCARRERA J
	                               WHERE  J.CODCARR = A.CODCARPR
	                                      AND J.ANO = A.ANO
	                                      AND J.PERIODO = A.PERIODO
	                           )
	                  INNER JOIN MT_VIADMISION V
	                       ON  V.COD_VIA = A.COD_VIA
	                       AND V.CODTIPOADMISION = 1
	                       --AND V.COD_VIA <> '30'
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
	                       AND V.COD_VIA IN (10,24,33,41,44,45,46,47,51)
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
	                       AND V.COD_VIA IN (36,20,22,23,25,26,8,28)
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
	
	---- MATRICULAS BACH --- 2016
	UPDATE TR2
	SET    TR2.MAT_BACH = P.CUENTA
	FROM   (
	           SELECT COUNT(CODCLI) AS CUENTA,
	                  A.CODCARPR
	           FROM   MT_ALUMNO A
	                  INNER JOIN MT_CARRER AS MC
	                       ON  MC.CODCARR = A.CODCARPR
	           WHERE  A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	                  AND A.ANO = @ANOPROCESO
	                  AND A.PERIODO = @PERIODOPROCESO
	                  AND A.ANO_MAT = A.ANO
	                  AND A.PERIODO_MAT = A.PERIODO
	                  AND LTRIM(RTRIM(A.COD_VIA)) IN (19)
	                  AND MC.TIPOCARR = 1
	           GROUP BY
	                  A.CODCARPR
	       ) P
	       INNER JOIN @TMP tR2
	            ON  tR2.CODCARR = P.CODCARPR
	
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
	
	
DECLARE @TMP_METAS_BACH TABLE (CODCARR VARCHAR(30),META INT)

INSERT INTO @TMP_METAS_BACH VALUES ('1100S',174)
INSERT INTO @TMP_METAS_BACH VALUES ('1200S',37)
INSERT INTO @TMP_METAS_BACH VALUES ('1300S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1301S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1304S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1400S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1401S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1500S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1501S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1502S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1504S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1603S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1631S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1632S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1634S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1700S',40)
INSERT INTO @TMP_METAS_BACH VALUES ('1800S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1801S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1900S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1901S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1902S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1903S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1904S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('2500S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('2501S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1633S',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1635S',0)

INSERT INTO @TMP_METAS_BACH VALUES ('1100C',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1200C',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1300C',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1400C',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1401C',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1500C',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1502C',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1603C',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1700C',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1801C',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1900C',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1901C',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1902C',0)
INSERT INTO @TMP_METAS_BACH VALUES ('1903C',0)
	
	SELECT T.SEDE,
	       T.CODCARR,
	       T.COD_DEMRE,
	       T.NOMBRE,
	       T.CUPO_OFICIAL,
	       T.CUPO_SOBRECUPO,
	       T.CUPO_ADM_ESP_TOTAL,
	       T.CUPOS_UDD,
	       T.CONVOCADOS,
	       T.ACEPTADOS_ADM_ESP,
	       T.META_CUPO_OFICIAL,
	       T.META_ADM_ESP_TOT,
	       T.META_UDD - ISNULL((SELECT tmb2.META FROM @TMP_METAS_BACH AS tmb2 WHERE tmb2.CODCARR = T.CODCARR),0) AS META_UDD,
	       T.MAT_PSU_TOT,
	       T.MAT_CO,
	       T.MAT_SOBRECUPO,
	       T.MAT_LE,
	       T.MAT_AE_10 AS 'MAT_AE_10%',
	       T.MAT_AE,
	       T.MAT_AE_TOT,
	       T.TOTAL_UDD,
	       T.MAT_SEGUNDACARR,
	       COALESCE(T.MAT_BACH,0) AS MAT_BACH,
	       META_BACH = ISNULL((SELECT tmb2.META FROM @TMP_METAS_BACH AS tmb2 WHERE tmb2.CODCARR = T.CODCARR),0)
	FROM   @TMP AS T
	WHERE  T.CODCARR IN (SELECT AUAC.CODCARR
	                     FROM   ADM_USUARIO_ASIGNACION_CARRERA AUAC
	                     WHERE  AUAC.CODCARR = T.CODCARR
	                            AND AUAC.ID_USUARIO = @USUARIO
	                            OR  @USUARIO IS NULL)
	       AND (T.SEDE = @CODSEDE OR @CODSEDE IS NULL)
	ORDER BY
	       SEDE,
	       CODCARR
END	        

