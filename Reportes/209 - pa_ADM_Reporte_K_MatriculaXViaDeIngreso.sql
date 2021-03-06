USE [matricula]
GO
/****** Object:  StoredProcedure [matricula].[pa_ADM_Reporte_K_MatriculaXViaDeIngreso]    Script Date: 07-12-2016 17:04:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/************************************************************
 * ROBERTO LARRONDE RYBERTT
 * Fecha: 17-12-2012 10:34:38
 ************************************************************/

--EXEC PA_ADM_REPORTE_K_MATRICULAXVIADEINGRESO NULL,NULL,NULL
--EXEC PA_ADM_REPORTE_K_MATRICULAXVIADEINGRESO 'CONCEPCION','1200C',NULL

/* modificaciones:
* autor			: Alexanders Gutierrez
* fecha			: 08/09/2014
* descripcion	: optimización completa de consulta para reducción de tiempo de respuesta.
*
* autor			: Alexanders Gutierrez
* fecha			: 11/11/2014
* descripcion	: se agregan nuevas vias de admision proceso 2015, cod_via 44 y 45, que corresponden al admsion especial 15%
*/

ALTER PROCEDURE [matricula].[pa_ADM_Reporte_K_MatriculaXViaDeIngreso](
    @SEDE     VARCHAR(30) = NULL,
    @CODCARR  VARCHAR(30) = NULL,
    @USUARIO  VARCHAR(50) = NULL
)
AS
BEGIN
	DECLARE @ANOPROCESO      INT,
	        @PERIODOPROCESO  INT
	
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
            PJE_ULT_MATRICULADO_ANO_ANT DECIMAL(5, 2),
            TRASLADO_SEDE INT,
            CAMBIO_CARRERA INT,
            ESTUDIOS_EXTRANJERO INT,
            NORMAL_CON_PSU INT,
            BACHILLERATO_INTERNACIONAL_IB INT,
            BACHILLERATO_FRANCES INT,
            GRADUADO_BACH_UDD INT,
            GRADUADO_BACH_OTRAU INT,
            TRASLADO_UNIVERSIDAD INT,
            PROFESIONALES INT,
            PSU_ANTERIOR INT,
            FFAA_CARAB INT,
            EXPERIENCIA_LABORAL INT,
            SEGUNDA_CARRERA INT,
            REPOSTULACION_INT INT,
            REPOSTULACION_PSU INT,
            PSU_BEA_SUPERNUMERARIO INT,
            PSU_POR_OFICIO INT,
            PSU_MATRICULA_HONOR INT,
            LIDER_ADM_ESP INT,
            BACHILLERATO_ITALIANO INT,
            PSU_NORMAL INT,
            AUTORIZACION_ESPECIAL INT,
            MATRICULA_CON_ACUERDO2 INT,
            BACHILLERATO_ALEMAN INT,
            BACHILLERATO_INTERNACIONAL_ECS_ABITUR_BAC_IB INT,
            RETRACTADOS INT,
            RETRACTADOS_ANO_ANT INT,
            RENUNCIADOS INT,
            RENUNCIADOS_ANO_ANT INT,
            MATRICULADOS INT,
            DEPORTISTAS_DESTACADOS INT,
            HIJOS_FUNCIONARIOS INT,
            ALUMNOS_EMPRENDEDORES INT, --2016
            ALUMNOS_DEST_ACAD INT, --2016
            ALUMNOS_CAL INT --2016
        )


INSERT INTO @TMP
SELECT MC.SEDE,
       MC.CODCARR,
       amc.COD_DEMRE,
       amc.NOMBRE,
       MP.VACANTE_REGULAR,
       MP.VACANTE_SOBRECUPO,
       MP.VACANTE_ESPECIAL,
       (
           MP.VACANTE_REGULAR + MP.VACANTE_SOBRECUPO + MP.VACANTE_ESPECIAL
       ) AS META_UDD,
       0,
       0,
       MP.META_OFICIAL,
       MP.META_ADMESP,
       MP.META_CARRERA,
       0,
       0,
       NULL,
       NULL,
       0,
       NULL,
       NULL,
       0,
       NULL,
       NULL,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       NULL,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0,
       0
FROM MT_CARRER_CLASIFICACION AS mcc
	 INNER JOIN [db_Admision].DB_ADMISION.DBO.ADM_MAE_CARRERA AMC 
				ON MCC.CODCARR=AMC.CODCARR
	   INNER JOIN MT_CARRER AS mc 
				ON MC.CODCARR=MCC.CODCARR   
       LEFT JOIN MT_PJECORTEPONDERADOCARRERA MP
            ON  MP.CODCARR = AMC.CODCARR
            AND MP.ANO = @ANOPROCESO
            AND MP.PERIODO = @PERIODOPROCESO
WHERE  
	MCC.CODTIPO=2
	AND @ANOPROCESO BETWEEN MCC.ANO_INI AND MCC.ANO_FIN


--- TOTAL CONVOCADOS ---
UPDATE TR2
SET    TR2.CONVOCADOS = P.CUENTA
FROM   (
           SELECT COUNT(CODCLI)          AS CUENTA,
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
                      SELECT P.POND      AS PJEPOND,
                             A.CODCARPR  AS CODCARR
                      FROM   MT_ALUMNO A
                             INNER JOIN MT_POSCAR P
                                  ON  P.CODPOSTUL = A.RUT
                                  AND P.CODCARR = A.CODCARPR
                                  AND P.ANO = A.ANO
                                  AND P.PERIODO = A.PERIODO
                                  AND P.LUGARENLISTA <= (
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
           SELECT MAX(X.PJEPOND) AS MAXIMO,
                  MIN(X.PJEPOND)  AS MINIMO,
                  X.CODCARR
           FROM   (
                      SELECT P.POND      AS PJEPOND,
                             A.CODCARPR  AS CODCARR
                      FROM   MT_ALUMNO A
                             INNER JOIN MT_POSCAR P
                                  ON  P.CODPOSTUL = A.RUT
                                  AND P.CODCARR = A.CODCARPR
                                  AND P.ANO = A.ANO
                                  AND P.PERIODO = A.PERIODO
                                  AND P.LUGARENLISTA BETWEEN (
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
           SELECT MAX(X.PJEPOND) AS MAXIMO,
                  MIN(X.PJEPOND)  AS MINIMO,
                  X.CODCARR
           FROM   (
                      SELECT P.POND      AS PJEPOND,
                             A.CODCARPR  AS CODCARR
                      FROM   MT_ALUMNO A
                             INNER JOIN MT_POSCAR P
                                  ON  P.CODPOSTUL = A.RUT
                                  AND P.CODCARR = A.CODCARPR
                                  AND P.ANO = A.ANO
                                  AND P.PERIODO = A.PERIODO
                                  AND P.LUGARENLISTA > (
                                          SELECT J.VACANTE_REGULAR + J.VACANTE_SOBRECUPO
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
                       AND V.COD_VIA IN ('10', '24', '33', '41','44','45','46','47','51')
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
                       AND V.COD_VIA IN ('36', '20', '22', '23', '25', '26')
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
                  INNER JOIN ADM_DATOS_POSTULANTES adp
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
                  INNER JOIN MATRICULA.MT_CARRER C
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
           SELECT COUNT(A.RUT) AS CUENTA,
                  A.CODCARPR
           FROM   MATRICULA.MT_ALUMNO A
                  INNER JOIN MATRICULA.MT_VIADMISION V
                       ON  V.COD_VIA = COALESCE(A.COD_VIA, A.COD_VIA)
                       AND COALESCE(V.CODTIPOVACANTE, V.CODTIPOVACANTE) = 1
                  INNER JOIN MATRICULA.MT_POSCAR P
                       ON  P.CODPOSTUL = A.RUT
                       AND P.CODCARR = A.CODCARPR
                       AND P.ANO = A.ANO
                       AND P.PERIODO = A.PERIODO
           WHERE  A.ANO_MAT = @ANOPROCESO
                  AND A.PERIODO_MAT = @PERIODOPROCESO
                  AND A.ANO = @ANOPROCESO
                  AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
                  AND A.ESTADO_ARANCEL = 'PENDIENTE'
                  AND A.RUT IN (SELECT P.CODCLI
                                FROM   ADM_DATOS_POSTULANTES P
                                WHERE  P.CODCLI = A.RUT)
           GROUP BY
                  A.CODCARPR
       ) P
       INNER JOIN @TMP tR2
            ON  TR2.CODCARR = P.CODCARPR 

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


---VIAS DE ADMISIÓN PROCESO	            
DECLARE @vias TABLE (COD_VIA INT, NOMBRE_VIA VARCHAR(100))
INSERT INTO @vias VALUES  (13,'NORMAL_CON_PSU')
INSERT INTO @vias VALUES  (29,'REPOSTULACION_PSU')
INSERT INTO @vias VALUES  (30,'PSU_BEA_SUPERNUMERARIO')
INSERT INTO @vias VALUES  (31,'PSU_POR_OFICIO')
INSERT INTO @vias VALUES  (37,'MATRICULA_CON_ACUERDO')
INSERT INTO @vias VALUES  (32,'PSU_MATRICULA_HONOR')
INSERT INTO @vias VALUES  (10,'ESTUDIOS_EXTRANJERO')
INSERT INTO @vias VALUES  (15,'BACHILLERATO_INTERNACIONAL_IB')
INSERT INTO @vias VALUES  (16,'BACHILLERATO_FRANCES')
INSERT INTO @vias VALUES  (34,'BACHILLERATO_ITALIANO')
INSERT INTO @vias VALUES  (38,'BACHILLERATO_ALEMAN')
INSERT INTO @vias VALUES  (23,'PROFESIONALES')
INSERT INTO @vias VALUES  (24,'PSU_ANTERIOR')
INSERT INTO @vias VALUES  (26,'EXPERIENCIA_LABORAL')
INSERT INTO @vias VALUES  (33,'LIDER_ADM_ESP')
INSERT INTO @vias VALUES  (35,'PSU_NORMAL')
INSERT INTO @vias VALUES  (36,'AUTORIZACION_ESPECIAL')
INSERT INTO @vias VALUES  (19,'GRADUADO_BACH_UDD')
INSERT INTO @vias VALUES  (20,'GRADUADO_BACH_OTRAU')
INSERT INTO @vias VALUES  (22,'TRASLADO_UNIVERSIDAD')
INSERT INTO @vias VALUES  (25,'FFAA_CARAB')
INSERT INTO @vias VALUES  (27,'SEGUNDA_CARRERA')
INSERT INTO @vias VALUES  (28,'REPOSTULACION_INT')
INSERT INTO @vias VALUES  (8,'CAMBIO_CARRERA')
INSERT INTO @vias VALUES  (2,'TRASLADO_SEDE')
INSERT INTO @vias VALUES  (41,'BACHILLERATO_INTERNACIONAL_ECS_ABITUR_BAC_IB')
INSERT INTO @vias VALUES  (44,'DEPORTISTAS_DESTACADOS')
INSERT INTO @vias VALUES  (45,'HIJOS_FUNCIONARIOS')
INSERT INTO @vias VALUES  (46,'ALUMNOS_EMPRENDEDORES')--2016
INSERT INTO @vias VALUES  (47,'ALUMNOS_DEST_ACAD')--2016
INSERT INTO @vias VALUES  (51,'ALUMNOS_CAL')--2016

--- TABLA PARA GUARDAR CONTEO POR VIAS									 
DECLARE @TMP_VIA_ADMISION TABLE (
            CODCARR VARCHAR(30),
            COD_DEMRE VARCHAR(10),
            NOMBRE VARCHAR(100),
            COD_VIA INT,
            NOMBRE_VIA VARCHAR(100),
            CANTIDAD INT
        )

INSERT INTO @TMP_VIA_ADMISION
SELECT AMC.CODCARR,
       AMC.COD_DEMRE,
       AMC.NOMBRE,
       P.COD_VIA,
       P.NOMBRE_VIA,
       0
FROM   (
           SELECT V.COD_VIA,
                  V.NOMBRE_VIA
           FROM   @VIAS V
       )                   P,
       ADM_MAE_CARRERA     AMC
ORDER BY
       AMC.CODCARR,
       P.COD_VIA


UPDATE TVA
SET    TVA.CANTIDAD = P.CUENTA
FROM   (
           SELECT AMC.CODCARR,
                  A.COD_VIA,
                  COUNT(A.CODCLI) AS CUENTA
           FROM   MT_ALUMNO A
                  INNER JOIN ADM_MAE_CARRERA AMC
                       ON  AMC.CODCARR = A.CODCARPR
                  INNER JOIN ADM_MAE_SEDE AMS
                       ON  AMS.CODSEDE = AMC.CODSEDE
           WHERE  A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
                  AND A.ANO = @ANOPROCESO
                  AND A.PERIODO = @PERIODOPROCESO
                  AND A.ANO_MAT = A.ANO
                  AND A.PERIODO_MAT = A.PERIODO
                  AND AMC.VIGENTE = 1
                  AND AMC.CODCARR <> 'GLOBAL'
           GROUP BY
                  AMS.NOMBRE,
                  AMC.CODCARR,
                  AMC.COD_DEMRE,
                  AMC.NOMBRE,
                  A.COD_VIA
       ) p
       INNER JOIN @TMP_VIA_ADMISION TVA
            ON  TVA.CODCARR = P.CODCARR
            AND TVA.COD_VIA = P.COD_VIA


--- GUARDAMOS CONTEO POR VIAS EN TABLA PADRE @TMP
UPDATE TR2
SET    TR2.TRASLADO_SEDE = T.TRASLADO_SEDE,
       TR2.CAMBIO_CARRERA = T.CAMBIO_CARRERA,
       TR2.ESTUDIOS_EXTRANJERO = T.ESTUDIOS_EXTRANJERO,
       TR2.NORMAL_CON_PSU = T.NORMAL_CON_PSU,
       TR2.BACHILLERATO_INTERNACIONAL_IB = T.BACHILLERATO_INTERNACIONAL_IB,
       TR2.BACHILLERATO_FRANCES = T.BACHILLERATO_FRANCES,
       TR2.GRADUADO_BACH_UDD = T.GRADUADO_BACH_UDD,
       TR2.GRADUADO_BACH_OTRAU = T.GRADUADO_BACH_OTRAU,
       TR2.TRASLADO_UNIVERSIDAD = T.TRASLADO_UNIVERSIDAD,
       TR2.PROFESIONALES = T.PROFESIONALES,
       TR2.PSU_ANTERIOR = T.PSU_ANTERIOR,
       TR2.FFAA_CARAB = T.FFAA_CARAB,
       TR2.EXPERIENCIA_LABORAL = T.EXPERIENCIA_LABORAL,
       TR2.SEGUNDA_CARRERA = T.SEGUNDA_CARRERA,
       TR2.REPOSTULACION_INT = T.REPOSTULACION_INT,
       TR2.REPOSTULACION_PSU = T.REPOSTULACION_PSU,
       TR2.PSU_BEA_SUPERNUMERARIO = T.PSU_BEA_SUPERNUMERARIO,
       TR2.PSU_POR_OFICIO = T.PSU_POR_OFICIO,
       TR2.PSU_MATRICULA_HONOR = T.PSU_MATRICULA_HONOR,
       TR2.LIDER_ADM_ESP = T.LIDER_ADM_ESP,
       TR2.BACHILLERATO_ITALIANO = T.BACHILLERATO_ITALIANO,
       TR2.PSU_NORMAL = T.PSU_NORMAL,
       TR2.AUTORIZACION_ESPECIAL = T.AUTORIZACION_ESPECIAL,
       TR2.MATRICULA_CON_ACUERDO2 = T.MATRICULA_CON_ACUERDO,
       TR2.BACHILLERATO_ALEMAN = T.BACHILLERATO_ALEMAN,
       TR2.BACHILLERATO_INTERNACIONAL_ECS_ABITUR_BAC_IB = T.BACHILLERATO_INTERNACIONAL_ECS_ABITUR_BAC_IB,
       tR2.DEPORTISTAS_DESTACADOS = T.DEPORTISTAS_DESTACADOS,
       tR2.HIJOS_FUNCIONARIOS = T.HIJOS_FUNCIONARIOS,
       TR2.ALUMNOS_EMPRENDEDORES = T.ALUMNOS_EMPRENDEDORES,--2016
       TR2.ALUMNOS_DEST_ACAD = T.ALUMNOS_DEST_ACAD,--2016
       TR2.ALUMNOS_CAL = T.ALUMNOS_CAL--2016
FROM   (
           --HACEMOS tipo "PIVOTE" para SQL2000
           SELECT tva.CODCARR,
                  tva.COD_DEMRE,
                  tva.NOMBRE,
                  MIN(CASE tva.NOMBRE_VIA WHEN 'TRASLADO_SEDE' THEN TVA.CANTIDAD END)  AS 'TRASLADO_SEDE',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'CAMBIO_CARRERA' THEN TVA.CANTIDAD END)  AS 'CAMBIO_CARRERA',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'ESTUDIOS_EXTRANJERO' THEN TVA.CANTIDAD END)  AS 'ESTUDIOS_EXTRANJERO',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'NORMAL_CON_PSU' THEN TVA.CANTIDAD END)  AS 'NORMAL_CON_PSU',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'BACHILLERATO_INTERNACIONAL_IB' THEN TVA.CANTIDAD END)  AS 'BACHILLERATO_INTERNACIONAL_IB',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'BACHILLERATO_FRANCES' THEN TVA.CANTIDAD END)  AS 'BACHILLERATO_FRANCES',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'GRADUADO_BACH_UDD' THEN TVA.CANTIDAD END)  AS 'GRADUADO_BACH_UDD',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'GRADUADO_BACH_OTRAU' THEN TVA.CANTIDAD END)  AS 'GRADUADO_BACH_OTRAU',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'TRASLADO_UNIVERSIDAD' THEN TVA.CANTIDAD END)  AS 'TRASLADO_UNIVERSIDAD',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'PROFESIONALES' THEN TVA.CANTIDAD END)  AS 'PROFESIONALES',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'PSU_ANTERIOR' THEN TVA.CANTIDAD END)  AS 'PSU_ANTERIOR',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'FFAA_CARAB' THEN TVA.CANTIDAD END)  AS 'FFAA_CARAB',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'EXPERIENCIA_LABORAL' THEN TVA.CANTIDAD END)  AS 'EXPERIENCIA_LABORAL',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'SEGUNDA_CARRERA' THEN TVA.CANTIDAD END)  AS 'SEGUNDA_CARRERA',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'REPOSTULACION_INT' THEN TVA.CANTIDAD END)  AS 'REPOSTULACION_INT',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'REPOSTULACION_PSU' THEN TVA.CANTIDAD END)  AS 'REPOSTULACION_PSU',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'PSU_BEA_SUPERNUMERARIO' THEN TVA.CANTIDAD END)  AS 'PSU_BEA_SUPERNUMERARIO',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'PSU_POR_OFICIO' THEN TVA.CANTIDAD END)  AS 'PSU_POR_OFICIO',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'PSU_MATRICULA_HONOR' THEN TVA.CANTIDAD END)  AS 'PSU_MATRICULA_HONOR',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'LIDER_ADM_ESP' THEN TVA.CANTIDAD END)  AS 'LIDER_ADM_ESP',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'BACHILLERATO_ITALIANO' THEN TVA.CANTIDAD END)  AS 'BACHILLERATO_ITALIANO',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'PSU_NORMAL' THEN TVA.CANTIDAD END)  AS 'PSU_NORMAL',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'AUTORIZACION_ESPECIAL' THEN TVA.CANTIDAD END)  AS 'AUTORIZACION_ESPECIAL',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'MATRICULA_CON_ACUERDO' THEN TVA.CANTIDAD END)  AS 'MATRICULA_CON_ACUERDO',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'BACHILLERATO_ALEMAN' THEN TVA.CANTIDAD END)  AS 'BACHILLERATO_ALEMAN',
                  MIN(CASE tva.NOMBRE_VIA WHEN 'BACHILLERATO_INTERNACIONAL_ECS_ABITUR_BAC_IB' THEN TVA.CANTIDAD END)  AS 'BACHILLERATO_INTERNACIONAL_ECS_ABITUR_BAC_IB',
                  MIN(CASE TVA.NOMBRE_VIA WHEN 'DEPORTISTAS_DESTACADOS' THEN TVA.CANTIDAD END) AS 'DEPORTISTAS_DESTACADOS',
                  MIN(CASE TVA.NOMBRE_VIA WHEN 'HIJOS_FUNCIONARIOS' THEN TVA.CANTIDAD END) AS 'HIJOS_FUNCIONARIOS',
                  MIN(CASE TVA.NOMBRE_VIA WHEN 'ALUMNOS_EMPRENDEDORES' THEN TVA.CANTIDAD END) AS 'ALUMNOS_EMPRENDEDORES',--2016
                  MIN(CASE TVA.NOMBRE_VIA WHEN 'ALUMNOS_DEST_ACAD' THEN TVA.CANTIDAD END) AS 'ALUMNOS_DEST_ACAD',--2016
                  MIN(CASE TVA.NOMBRE_VIA WHEN 'ALUMNOS_CAL' THEN TVA.CANTIDAD END) AS 'ALUMNOS_CAL'--2016
           FROM   @TMP_VIA_ADMISION tva
           GROUP BY
                  tva.CODCARR,
                  tva.COD_DEMRE,
                  tva.NOMBRE
       ) AS T
       INNER JOIN @TMP tR2
            ON  tR2.CODCARR = T.CODCARR


--GUARDAMOS CANTIDAD DE RETRACTADOS DEL PROCESO
UPDATE TR2
SET    TR2.RETRACTADOS = P.CUENTA
FROM   (
           SELECT A.CODCARPR,
                  COALESCE(COUNT(A.RUT), 0) AS CUENTA
           FROM   MATRICULA.MT_ALUMNO A
                  INNER JOIN MATRICULA.MT_VIADMISION V
                       ON  V.COD_VIA = COALESCE(A.COD_VIA, A.COD_VIA)
           WHERE  A.ANO_MAT = @ANOPROCESO
                  AND A.PERIODO_MAT = @PERIODOPROCESO
                  AND A.ANO = A.ANO_MAT
                  AND A.PERIODO = A.PERIODO_MAT
                  AND A.TIPOSITU = 35
           GROUP BY
                  A.CODCARPR
       ) P
       INNER JOIN @TMP TR2
            ON  P.CODCARPR = TR2.CODCARR


-- GUARDAMOS CANTIDAD DE RETRACTADOS DEL PROCESO ANTERIOR
	UPDATE TR2
	SET    TR2.RETRACTADOS_ANO_ANT = P.CUENTA
	FROM   (
	           SELECT A.CODCARPR,
	                  COALESCE(COUNT(A.RUT), 0) AS CUENTA
	           FROM   MATRICULA.MT_ALUMNO A
	                  INNER JOIN MATRICULA.MT_VIADMISION V
	                       ON  V.COD_VIA = COALESCE(A.COD_VIA, A.COD_VIA)
	           WHERE  A.ANO_MAT = @ANOPROCESO - 1
	                  AND A.PERIODO_MAT = @PERIODOPROCESO
	                  AND A.ANO = A.ANO_MAT
	                  AND A.PERIODO = A.PERIODO_MAT
	                  AND A.TIPOSITU = 35
	           GROUP BY
	                  A.CODCARPR
	       ) P
	       INNER JOIN @TMP TR2
	            ON  P.CODCARPR = TR2.CODCARR
	
	-- GUARDAMOS CANTIDAD DE RENUNCIADOS DEL PROCESO
	UPDATE TR2
	SET    TR2.RENUNCIADOS = P.CUENTA
	FROM   (
	           SELECT A.CODCARPR,
	                  COALESCE(COUNT(A.RUT), 0) AS CUENTA
	           FROM   MATRICULA.MT_ALUMNO A
	                  INNER JOIN MATRICULA.MT_VIADMISION V
	                       ON  V.COD_VIA = COALESCE(A.COD_VIA, A.COD_VIA)
	           WHERE  A.ANO_MAT = @ANOPROCESO
	                  AND A.PERIODO_MAT = @PERIODOPROCESO
	                  AND A.ANO = A.ANO_MAT
	                  AND A.PERIODO = A.PERIODO_MAT
	                  AND A.TIPOSITU = 37
	           GROUP BY
	                  A.CODCARPR
	       ) P
	       INNER JOIN @TMP TR2
	            ON  P.CODCARPR = TR2.CODCARR
	
	-- GUARDAMOS CANTIDAD DE RENUNCIADOS DEL PROCESO ANTERIOR
	UPDATE TR2
	SET    TR2.RENUNCIADOS_ANO_ANT = P.CUENTA
	FROM   (
	           SELECT A.CODCARPR,
	                  COALESCE(COUNT(A.RUT), 0) AS CUENTA
	           FROM   MATRICULA.MT_ALUMNO A
	                  INNER JOIN MATRICULA.MT_VIADMISION V
	                       ON  V.COD_VIA = COALESCE(A.COD_VIA, A.COD_VIA)
	           WHERE  A.ANO_MAT = @ANOPROCESO - 1
	                  AND A.PERIODO_MAT = @PERIODOPROCESO
	                  AND A.ANO = A.ANO_MAT
	                  AND A.PERIODO = A.PERIODO_MAT
	                  AND A.TIPOSITU = 37
	           GROUP BY
	                  A.CODCARPR
	       ) P
	       INNER JOIN @TMP TR2
	            ON  P.CODCARPR = TR2.CODCARR
	
	--GUARDAMOS CANTIDAD DE MATRICULADOS DEL PROCESO
	UPDATE TR2
	SET    TR2.MATRICULADOS = P.CUENTA
	FROM   (
	           SELECT A.CODCARPR,
	                  COALESCE(COUNT(A.RUT), 0) AS CUENTA
	           FROM   MT_ALUMNO A
	                  INNER JOIN MT_POSCAR P
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
	       INNER JOIN @TMP TR2
	            ON  P.CODCARPR = TR2.CODCARR            

--- FINAL, PARA SER USADO EN CUALQUIER INFORME DE ESTADISTICAS DE ADMISION
SELECT X.SEDE,
       X.CODCARR,
       X.COD_DEMRE,
       X.NOMBRE,
       X.TOTAL_PSU + X.TOTAL_10_ADM_ESP + X.TOTAL_ADM_ESPECIAL AS 
       MATRICULA_TOTAL,
       X.TOTAL_PSU,
       X.NORMAL_CON_PSU,
       X.REPOSTULACION_PSU,
       X.PSU_BEA_SUPERNUMERARIO,
       X.PSU_POR_OFICIO,
       X.MATRICULA_CON_ACUERDO,
       X.PSU_MATRICULA_HONOR,
       X.TOTAL_10_ADM_ESP + X.TOTAL_ADM_ESPECIAL AS TOTAL_ADMISION_ESPECIAL,
       X.TOTAL_10_ADM_ESP,
       X.ESTUDIOS_EXTRANJERO,
       X.BACHILLERATO_INTERNACIONAL_IB,
       X.BACHILLERATO_FRANCES,
       X.BACHILLERATO_ITALIANO,
       X.BACHILLERATO_ALEMAN,
       X.PROFESIONALES,
       X.PSU_ANTERIOR,
       X.EXPERIENCIA_LABORAL,
       X.LIDER_ADM_ESP,
       X.PSU_NORMAL,
       X.TOTAL_ADM_ESPECIAL,
       X.AUTORIZACION_ESPECIAL,
       X.GRADUADO_BACH_UDD,
       X.GRADUADO_BACH_OTRAU,
       X.TRASLADO_UNIVERSIDAD,
       X.FFAA_CARAB,
       X.SEGUNDA_CARRERA,
       X.REPOSTULACION_INT,
       X.CAMBIO_CARRERA,
       X.TRASLADO_SEDE,
       X.TOTAL_PSU + X.TOTAL_10_ADM_ESP + X.TOTAL_ADM_ESPECIAL + X.SEGUNDA_CARRERA 
	   + X.CAMBIO_CARRERA + X.GRADUADO_BACH_UDD + X.REPOSTULACION_INT AS TOTAL_MATRICULADOS_UDD,
       X.BACHILLERATO_INTERNACIONAL_ECS_ABITUR_BAC_IB,
       X.DEPORTISTAS_DESTACADOS,
       X.HIJOS_FUNCIONARIOS,
       X.ALUMNOS_EMPRENDEDORES,--2016
       X.ALUMNOS_DEST_ACAD,--2016
       X.ALUMNOS_CAL--2016
FROM   (
           SELECT Z.SEDE,
                  Z.CODCARR,
                  Z.COD_DEMRE,
                  Z.NOMBRE,
                  Z.NORMAL_CON_PSU + Z.REPOSTULACION_PSU + Z.PSU_BEA_SUPERNUMERARIO 
                  + Z.PSU_POR_OFICIO + Z.MATRICULA_CON_ACUERDO AS TOTAL_PSU,
                  Z.NORMAL_CON_PSU,
                  Z.REPOSTULACION_PSU,
                  Z.PSU_BEA_SUPERNUMERARIO,
                  Z.PSU_POR_OFICIO,
                  Z.MATRICULA_CON_ACUERDO,
                  Z.PSU_MATRICULA_HONOR,
                  Z.ESTUDIOS_EXTRANJERO + Z.PSU_ANTERIOR + Z.LIDER_ADM_ESP + Z.BACHILLERATO_INTERNACIONAL_ECS_ABITUR_BAC_IB + Z.DEPORTISTAS_DESTACADOS +
                  Z.HIJOS_FUNCIONARIOS + Z.ALUMNOS_EMPRENDEDORES + Z.ALUMNOS_DEST_ACAD + Z.ALUMNOS_CAL AS TOTAL_10_ADM_ESP,
                  Z.ESTUDIOS_EXTRANJERO,
                  Z.BACHILLERATO_INTERNACIONAL_IB,
                  Z.BACHILLERATO_FRANCES,
                  Z.BACHILLERATO_ITALIANO,
                  Z.BACHILLERATO_ALEMAN,
                  Z.PROFESIONALES,
                  Z.PSU_ANTERIOR,
                  Z.EXPERIENCIA_LABORAL,
                  Z.LIDER_ADM_ESP,
                  Z.PSU_NORMAL,
                  Z.AUTORIZACION_ESPECIAL + Z.GRADUADO_BACH_OTRAU + Z.TRASLADO_UNIVERSIDAD 
                  + Z.FFAA_CARAB + Z.PROFESIONALES + Z.EXPERIENCIA_LABORAL AS TOTAL_ADM_ESPECIAL,
                  Z.AUTORIZACION_ESPECIAL,
                  Z.GRADUADO_BACH_UDD,
                  Z.GRADUADO_BACH_OTRAU,
                  Z.TRASLADO_UNIVERSIDAD,
                  Z.FFAA_CARAB,
                  Z.SEGUNDA_CARRERA,
                  Z.REPOSTULACION_INT,
                  Z.CAMBIO_CARRERA,
                  Z.TRASLADO_SEDE,
                  Z.BACHILLERATO_INTERNACIONAL_ECS_ABITUR_BAC_IB,
                  Z.DEPORTISTAS_DESTACADOS,
                  Z.HIJOS_FUNCIONARIOS,
                  Z.ALUMNOS_EMPRENDEDORES,--2016
                  Z.ALUMNOS_DEST_ACAD,--2016
                  Z.ALUMNOS_CAL--2016
           FROM   (
                      SELECT T.SEDE,
                             T.CODCARR,
                             T.COD_DEMRE,
                             T.NOMBRE,
                             T.CUPO_OFICIAL,
                             T.CUPO_SOBRECUPO AS SOBRECUPO,
                             T.CUPO_ADM_ESP_TOTAL,
                             T.CUPOS_UDD,
                             T.CONVOCADOS,
                             T.ACEPTADOS_ADM_ESP,
                             T.META_CUPO_OFICIAL,
                             T.META_ADM_ESP_TOT,
                             T.META_UDD,
                             T.MAT_PSU_TOT,
                             T.MAT_CO,
                             T.MAX_PJE_CUPO_OFICIAL,
                             T.MIN_PJE_CUPO_OFICIAL,
                             T.MAT_SOBRECUPO,
                             T.MAX_PJE_SOBRECUPO,
                             T.MIN_PJE_SOBRECUPO,
                             T.MAT_LE,
                             T.MAX_PJE_LISTA_ESPERA,
                             T.MIN_PJE_LISTA_ESPERA,
                             T.MAT_AE_10,
                             T.MAT_AE,
                             T.MAT_AE_TOT,
                             T.TOTAL_UDD,
                             T.MAT_SEGUNDACARR,
                             T.MAT_BEA,
                             T.MATR_CO_SC_LE_BEA,
                             T.MATR_REPOSTULACION,
                             T.MATR_EN_PROCESO,
                             T.MATRICULA_CON_ACUERDO,
                             T.PJE_ULT_MATRICULADO_ANO_ANT,
                             T.TRASLADO_SEDE,
                             T.CAMBIO_CARRERA,
                             T.ESTUDIOS_EXTRANJERO,
                             T.NORMAL_CON_PSU,
                             T.BACHILLERATO_INTERNACIONAL_IB,
                             T.BACHILLERATO_FRANCES,
                             T.GRADUADO_BACH_UDD,
                             T.GRADUADO_BACH_OTRAU,
                             T.TRASLADO_UNIVERSIDAD,
                             T.PROFESIONALES,
                             T.PSU_ANTERIOR,
                             T.FFAA_CARAB,
                             T.EXPERIENCIA_LABORAL,
                             T.SEGUNDA_CARRERA,
                             T.REPOSTULACION_INT,
                             T.REPOSTULACION_PSU,
                             T.PSU_BEA_SUPERNUMERARIO,
                             T.PSU_POR_OFICIO,
                             T.PSU_MATRICULA_HONOR,
                             T.LIDER_ADM_ESP,
                             T.BACHILLERATO_ITALIANO,
                             T.PSU_NORMAL,
                             T.AUTORIZACION_ESPECIAL,
                             T.MATRICULA_CON_ACUERDO2,
                             T.BACHILLERATO_ALEMAN,
                             T.BACHILLERATO_INTERNACIONAL_ECS_ABITUR_BAC_IB,
                             T.RETRACTADOS,
                             T.RETRACTADOS_ANO_ANT,
                             T.RENUNCIADOS,
                             T.RENUNCIADOS_ANO_ANT,
                             T.MATRICULADOS,
                             T.DEPORTISTAS_DESTACADOS,
                             T.HIJOS_FUNCIONARIOS,
                             T.ALUMNOS_EMPRENDEDORES,--2016
                             T.ALUMNOS_DEST_ACAD,--2016
                             T.ALUMNOS_CAL--2016
                      FROM   @TMP T
                  ) Z
       ) X
WHERE (X.SEDE = @SEDE OR @SEDE IS NULL)
AND (X.CODCARR = @CODCARR OR @CODCARR IS NULL)
AND X.CODCARR IN (SELECT AUAC.CODCARR
	                         FROM   ADM_USUARIO_ASIGNACION_CARRERA AUAC
	                         WHERE  AUAC.CODCARR = X.CODCARR
	                                AND AUAC.ID_USUARIO = @USUARIO
	                                OR  @USUARIO IS NULL)
ORDER BY
       X.SEDE,
       X.CODCARR
END