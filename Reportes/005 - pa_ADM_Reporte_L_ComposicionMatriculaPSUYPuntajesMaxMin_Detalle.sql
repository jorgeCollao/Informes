USE [matricula]
GO
/****** Object:  StoredProcedure [matricula].[pa_ADM_Reporte_L_ComposicionMatriculaPSUYPuntajesMaxMin_Detalle]    Script Date: 10-11-2016 9:30:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/************************************************************
 * ROBERTO LARRONDE RYBERTT
 * Fecha: 18-01-2013 11:25:21
 ************************************************************/

-- EXEC pa_ADM_Reporte_L_ComposicionMatriculaPSUYPuntajesMaxMin_Detalle NULL,NULL,1,'alexandergutierrez'
--EXEC pa_ADM_Reporte_L_ComposicionMatriculaPSUYPuntajesMaxMin_Detalle 'TODAS','',11

ALTER PROCEDURE [matricula].[pa_ADM_Reporte_L_ComposicionMatriculaPSUYPuntajesMaxMin_Detalle](
    @CODSEDE     VARCHAR(30) = NULL,
    @CODCARR     VARCHAR(30) = NULL,
    @NOMINA      INT,
    @USUARIO     VARCHAR(30) = NULL
)
AS
BEGIN
	DECLARE @ANOPROCESO         INT,
	        @PERIODOPROCESO     INT
	
	SELECT @ANOPROCESO = MATRICULA.FN_OBTIENEANOPERIODO('A', 'M'),
	       @PERIODOPROCESO = 1 
	

	
	--/////-----------------------------------------------------------------------------------------------------------------------------------/////--
	IF @NOMINA = 1 --CONVOCADOS PSU
	BEGIN
	    --*********************--
	    --- PRECARGA BASE DE BENEFICIOS---
	    DECLARE @TMP_BENEFICIOS TABLE (CANTIDAD INT, NUM_DOC VARCHAR(30), CODCARR VARCHAR(30))
	    INSERT INTO @TMP_BENEFICIOS
	    SELECT COUNT(BS.CODBEN),
	           AI.NUM_DOC,
	           BS.CODCARR
	    FROM   DB_ADMISION.DBO.ADM_BENEFICIOS_SIMULACION BS
	           INNER JOIN DB_ADMISION.DBO.ADM_SIMULACARRERABENEFICIO SC
	                ON  SC.NUM_DOC = BS.NUM_DOC
	                AND SC.TIPO_DOC = BS.TIPO_DOC
	                AND SC.NUM_DOC = BS.NUM_DOC
	                AND SC.PTJE_ANO_ACAD = BS.PTJE_ANO_ACAD
	                AND SC.CODCARR = BS.CODCARR
	                AND SC.CODAREA = BS.CODAREA
	           INNER JOIN DB_ADMISION.DBO.ADM_MAE_BECAS BE
	                ON  BE.CODBEN = BS.CODBEN
	           INNER JOIN DB_ADMISION.DBO.ADM_BECAS_CARRERA BC
	                ON  BC.CODBEN = BS.CODBEN
	                AND BC.CODCARR = SC.CODCARR
	                AND BC.ANOPROCESO = @ANOPROCESO
	           INNER JOIN DB_ADMISION.DBO.ADM_DETALLE_BECAS_CARRERA DB
	                ON  DB.CODCARR = BS.CODCARR
	                AND DB.CODBEN = BS.CODBEN
	                AND DB.ANOPROCESO = BC.ANOPROCESO
	           INNER JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	                ON  AI.NUM_DOC = BS.NUM_DOC
	           INNER JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS AUE
	                ON  AUE.LOC_CODIGO = AI.LOC_CODIGO
	                AND AUE.UED_CODIGO = AI.UED_CODIGO
	           LEFT JOIN DB_ADMISION.DBO.ADM_BENEFICIADOS_ESPECIALES LIDER
	                ON  LIDER.NUM_DOC = BS.NUM_DOC
	                AND LIDER.CODBEN = 456--409
	           LEFT JOIN DB_ADMISION.DBO.ADM_BENEFICIADOS_ESPECIALES CAE
	                ON  CAE.NUM_DOC = BS.NUM_DOC
	                AND CAE.CODBEN = 348
	    WHERE  CASE 
	                WHEN BC.APLICA = 'PONDERADO' THEN SC.PJE_POND
	                WHEN BC.APLICA = 'PROMEDIO' THEN SC.PROM_PSU
	           END + ISNULL(LIDER.VALOR, 0) BETWEEN DB.VALORINICIAL
	           AND DB.VALORFINAL
	           AND ISNULL(CAE.VALOR, 0) = CASE 
	                                           WHEN DB.EXIGE_CAE = 0 THEN ISNULL(CAE.VALOR, 0)
	                                           ELSE DB.EXIGE_CAE
	                                      END
	           AND (DB.GRUPODEPENDENCIA = AUE.GRUPO OR DB.GRUPODEPENDENCIA = 0)
	    GROUP BY
	           ai.NUM_DOC,
	           BS.CODCARR
	    ORDER BY
	           AI.NUM_DOC
	    --********************--
	    
	    
	    
	    SELECT P.SEDE,
	           P.CODCARR,
	           P.COD_DEMRE,
	           P.[NOMBRE CARRERA],
	           P.RUN,
	           P.DV,
	           P.PATERNO,
	           P.MATERNO,
	           P.NOMBRE,
	           P.DIRECCION,
	           P.COMUNA,
	           P.REGION,
	           P.EMAILPOSTULANTE,
	           P.TELEFONO,
	           P.CELULARPOSTULANTE,
	           P.LUGAR               AS 'LUGAR EN LISTA',
	           P.PREFERENCIA,
	           CASE 
	                WHEN COALESCE(MA.CODCLI, '') = '' THEN 'NO'
	                ELSE 'SI'
	           END                   AS MATRICULADO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 348
	                   AND VALOR = 1 THEN 'SI'
	                       ELSE 'NO'
	                       END AS PRUEBA
	                       FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                       BE
	                       WHERE BE.NUM_DOC = P.RUN
	                   AND BE.CODBEN = 348
	               ),
	               'NO'
	           )                     AS 'CRAE',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456/*409*/ THEN 'SI'
	                               ELSE 'NO'
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.RUN
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.RUN
	                          AND BE.CODBEN = 456--409
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               'NO'
	           )                     AS 'LIDER',
	           CASE (
	                    SELECT 1
	                    FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                    WHERE  B.NUM_DOC = P.RUN
	                           AND B.SIGLA = 'UDD'
	                           AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                           AND B.CARRERA = P.COD_DEMRE
	                           AND P.TIENE_BEA = 1
	                )
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END                   AS 'BEA',
	           P.[PONDERADO CARRERA],
	           P.[PROMEDIO PSU],
	           'POST_EFECT_CARR' = ISNULL(
	               (
	                   SELECT COUNT(ADP2.CODCLI)
	                   FROM   ADM_DATOS_POSTULANTES ADP2
	                   WHERE  ADP2.CODCARR = P.CODCARR
	               ),
	               0
	           ),
	           'POST_EFECT_SEDE' = ISNULL(
	               (
	                   SELECT COUNT(ADP2.CODCLI)
	                   FROM   ADM_DATOS_POSTULANTES ADP2
	                          INNER JOIN MT_CARRER MC
	                               ON  MC.CODCARR = ADP2.CODCARR
	                               AND MC.SEDE = P.SEDE
	               ),
	               0
	           ),
	           'POST_EFECT_UDD' = ISNULL(
	               (
	                   SELECT COUNT(ADP2.CODCLI)
	                   FROM   ADM_DATOS_POSTULANTES ADP2
	               ),
	               0
	           ),
	           @ANOPROCESO           AS ANO,
	           @PERIODOPROCESO       AS PERIODO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456/*409*/ THEN VALOR
	                               ELSE 0
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.RUN
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.RUN
	                          AND BE.CODBEN = 456/*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               0
	           )                     AS 'VALOR_LIDER',
	           'PRESELEC_CAE_INGRESA' = ISNULL(
	               (
	                   SELECT DISTINCT('SI')
	                   FROM   MT_CRAE_CARGATMP 
	                          MCC
	                   WHERE  MCC.RUT = P.RUN
	                          AND MCC.TIPO = 'N'
	               ),
	               'NO'
	           ),
	           CASE 
	                WHEN COALESCE(TB.NUM_DOC, '') = '' THEN 'NO'
	                ELSE 'SI'
	           END                   AS BECAS,
	           MC3.CODCOL            AS RBD,
	           MC3.NOMBRE            AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS 
	           DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	           P.PAAVERBAL,
	           P.PAAMATEMAT,
	           P.PAAHISGEO,
	           P.PCEBIO,
	           P.PONDEM,
	           P.PTJE_RANKING,
	           CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = MA.CODCLI
                                       AND MM.ANO = MA.ANO
                            ) THEN CONVERT(VARCHAR(10), MA.FEC_MAT, 103)
                       ELSE (
                                SELECT TOP 1 CONVERT(VARCHAR(10), MM.FECHA_REGISTRO, 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = MA.CODCLI
                                       AND mm.ANO = MA.ANO
                                       AND MM.PERIODO=MA.PERIODO
                                       AND mm.REMATRICULA IS NULL
                                ORDER BY
                                       MM.FECHA_REGISTRO DESC
                            )
                  END        AS FEC_MAT,
	           --CONVERT(VARCHAR(10), MA.FEC_MAT, 103) AS FEC_MAT,
	           MA.TIPO_MATRICULA,
	           P.NACIONALIDAD
	    FROM   (
	               SELECT S.NOMBRE        AS SEDE,
	                      C.CODCARR,
	                      C.COD_DEMRE,
	                      C.NOMBRE        AS [NOMBRE CARRERA],
	                      MC.CODCLI       AS RUN,
	                      MC.DIG          AS DV,
	                      MC.PATERNO,
	                      MC.MATERNO,
	                      MC.NOMBRE,
	                      MC.DIRPROC      AS DIRECCION,
	                      MC.COMUNAPRO    AS COMUNA,
	                      MCOM.CODREGION  AS REGION,
	                      MC.EMAILPOSTULANTE,
	                      MC.FONOPROC     AS TELEFONO,
	                      MC.CELULARPOSTULANTE,
	                      MP.LUGARENLISTA AS LUGAR,
	                      MP.PRIORIDAD    AS PREFERENCIA,
	                      MP.POND         AS 'PONDERADO CARRERA',
	                      MC.COLEGIO,
	                      CONVERT(DECIMAL(5, 2), ((MP2.PAAVERBAL + MP2.PAAMATEMAT) / 2)) AS 
	                      'PROMEDIO PSU',
	                      MP2.PAAVERBAL,
	                      MP2.PAAMATEMAT,
	                      MP2.PAAHISGEO,
	                      MP2.PCEBIO,
	                      MC.NACIONALIDAD,
	                      MP2.NOTAEM      AS PONDEM,
	                      MP2.PTJE_RANKING,
	                      ADP.TIENE_BEA
	               FROM   ADM_DATOS_POSTULANTES ADP
	                      INNER JOIN MT_CLIENT MC
	                           ON  MC.CODCLI = ADP.CODCLI
	                      INNER JOIN MT_POSCAR AS mp
	                           ON  MP.CODPOSTUL = ADP.CODCLI
	                           AND mp.CODCARR = ADP.CODCARR
	                      LEFT JOIN MT_PAA AS mp2
	                           ON  MP2.CODCLI = ADP.CODCLI
	                           AND MP.ANOPSU = MP2.ANO
	                      INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA C
	                           ON  C.CODCARR = ADP.CODCARR
	                      INNER JOIN DB_ADMISION.DBO.ADM_MAE_SEDE S
	                           ON  S.CODSEDE = C.CODSEDE
	                      INNER JOIN MT_COMUNA MCOM
	                           ON  ADP.COMUNA = MCOM.CODCOM
	               WHERE  ADP.ESTADO = 'A'
	                      AND MP.ANO = @ANOPROCESO
	           ) P
	           LEFT JOIN MT_ALUMNO MA
	                ON  MA.RUT = P.RUN
	                AND MA.CODCARPR = P.CODCARR
	                AND MA.ANO = @ANOPROCESO
	                AND MA.PERIODO = @PERIODOPROCESO
	                AND MA.ANO_MAT = MA.ANO
	                AND MA.PERIODO_MAT = MA.PERIODO
	                AND MA.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = P.COLEGIO
	           LEFT JOIN @TMP_BENEFICIOS TB
	                ON  TB.CODCARR = P.CODCARR
	                AND TB.NUM_DOC = P.RUN
	    WHERE  (P.CODCARR = @CODCARR OR @CODCARR IS NULL)
	           AND (P.SEDE = @CODSEDE OR @CODSEDE IS NULL)
	           AND P.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	    ORDER BY
	           P.CODCARR,
	           P.LUGAR,
	           P.RUN
	END
	--/////-----------------------------------------------------------------------------------------------------------------------------------/////--
	IF @NOMINA = 2 --CUPO OFICIAL + SOBRECUPO + LISTA ESPERA
	BEGIN
	    SELECT A.CODSEDE        AS 'SEDE',
	           A.CODCARPR       AS 'CODCARR',
	           MC.COD_DEMRE,
	           MC.NOMBRE        AS 'NOMBRE CARRERA',
	           A.RUT            AS 'RUN',
	           C.DIG            AS 'DV',
	           C.PATERNO,
	           C.MATERNO,
	           C.NOMBRE,
	           C.DIRPROC        AS DIRECCION,
	           C.COMUNA,
	           MC2.CODREGION    AS REGION,
	           C.EMAILPOSTULANTE,
	           C.FONOACT        AS 'TELEFONO',
	           C.CELULARPOSTULANTE,
	           COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR EN LISTA',
			   COALESCE(P.PRIORIDAD,0) AS PREFERENCIA,
	           --PREFERENCIA = COALESCE(
	           --    (
	           --        SELECT ADP.PREFERENCIA
	           --        FROM   ADM_DATOS_POSTULANTES ADP
	           --        WHERE  ADP.CODCLI = A.RUT
	           --               AND ADP.CODCARR = A.CODCARPR
	           --    ),
	           --    0
	           --),
	           'SI' AS 'MATRICULADO',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 348
	                   AND VALOR = 1 THEN 'SI'
	                       ELSE 'NO'
	                       END AS PRUEBA
	                       FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES BE
	                       WHERE BE.NUM_DOC = A.RUT
	                   AND CODBEN = 348
	               ),
	               'NO'
	           )                AS 'CRAE',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456/*409*/ THEN 'SI'
	                               ELSE 'NO'
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456/*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               'NO'
	           )                AS 'LIDER',
	           CASE (
	                    SELECT 1
	                    FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                    WHERE  B.NUM_DOC = P.CODPOSTUL
	                           AND B.SIGLA = 'UDD'
	                           AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                           AND B.CARRERA = MC.COD_DEMRE
	                )
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END              AS 'BEA',
	           P.POND           AS 'PONDERADO CARRERA',
	           CASE COALESCE(P.ANOPSU, 0)
	                WHEN 0 THEN 0
	                ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', A.RUT, P.ANOPSU)
	           END              AS 'PROMEDIO PSU',
	           0                AS 'POST_EFECT_CARR',
	           0                AS 'POST_EFECT_SEDE',
	           0                AS 'POST_EFECT_UDD',
	           @ANOPROCESO      AS ANO,
	           @PERIODOPROCESO  AS PERIODO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456/*409*/ THEN VALOR
	                               ELSE 0
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456/*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               0
	           )                AS 'VALOR_LIDER',
	           'PRESELEC_CAE_INGRESA' = ISNULL(
	               (
	                   SELECT DISTINCT('SI')
	                   FROM   MT_CRAE_CARGATMP 
	                          MCC
	                   WHERE  MCC.RUT = P.CODPOSTUL
	                          AND MCC.TIPO = 'N'
	               ),
	               'NO'
	           ),
	           MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 'BECAS',
	           MC3.CODCOL        AS RBD,
	           MC3.NOMBRE    AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	           --CASE COALESCE(UET.[TARGET], 0)
	           --     WHEN 1 THEN 'SI'
	           --     ELSE 'NO'
	           --END              AS [TARGET],
	           MP.PAAVERBAL,
	           MP.PAAMATEMAT,
	           MP.PAAHISGEO,
	           MP.PCEBIO,
	           MP.PTJE_RANKING,
	           MP.NOTAEM        AS PONDEM,
	           CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT TOP 1 CONVERT(VARCHAR(10), MAX(MM.FECHA_REGISTRO), 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       AND MM.REMATRICULA IS NULL
                                --ORDER BY
                                --       MM.FECHA_REGISTRO DESC
                            )
                  END        AS FEC_MAT,
	           --CONVERT(VARCHAR(10), MA.FEC_MAT, 103) AS FEC_MAT,
	           A.TIPO_MATRICULA,
	           C.NACIONALIDAD
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
	           INNER JOIN MT_CLIENT C
	                ON  C.CODCLI = A.RUT
	           INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA MC
	                ON  MC.CODCARR = A.CODCARPR
	           INNER JOIN MT_COMUNA mc2
	                ON  MC2.CODCOM = C.COMUNAPRO
	           INNER JOIN MT_PAA MP
	                ON  MP.CODCLI = P.CODPOSTUL --.RUT
	                AND MP.ANO = P.ANOPSU
	                 LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = C.COLEGIO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	           --     ON  AI.NUM_DOC = A.RUT
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	           --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	           --     AND UE.UED_CODIGO = AI.UED_CODIGO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	           --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	           --     AND UET.UED_CODIGO = UE.UED_CODIGO
	    WHERE  (A.CODCARPR = @CODCARR OR @CODCARR IS NULL)
	           AND (A.CODSEDE = @CODSEDE OR @CODSEDE IS NULL)
	           AND A.ANO_MAT = @ANOPROCESO
	           AND A.PERIODO_MAT = @PERIODOPROCESO
	           AND A.ANO = A.ANO_MAT
	           AND A.PERIODO = A.PERIODO_MAT
	           AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           AND MC.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	    UNION
	    SELECT A.CODSEDE        AS 'SEDE',
	           A.CODCARPR       AS 'CODCARR',
	           MC.COD_DEMRE,
	           MC.NOMBRE        AS 'NOMBRE CARRERA',
	           A.RUT            AS 'RUN',
	           C.DIG            AS 'DV',
	           C.PATERNO,
	           C.MATERNO,
	           C.NOMBRE,
	           C.DIRPROC        AS DIRECCION,
	           C.COMUNA,
	           MC2.CODREGION    AS REGION,
	           C.EMAILPOSTULANTE,
	           C.FONOACT        AS 'TELEFONO',
	           C.CELULARPOSTULANTE,
	           COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR EN LISTA',
	           COALESCE(P.prioridad,0) AS PREFERENCIA,
	           --PREFERENCIA = ISNULL(
	           --    (
	           --        SELECT ADP.PREFERENCIA
	           --        FROM   ADM_DATOS_POSTULANTES ADP
	           --        WHERE  ADP.CODCLI = A.RUT
	           --               AND ADP.CODCARR = A.CODCARPR
	           --    ),
	           --    0
	           --),
	           'SI' AS 'MATRICULADO',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 348
	                   AND VALOR = 1 THEN 'SI'
	                       ELSE 'NO'
	                       END AS PRUEBA
	                       FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                       BE
	                       WHERE BE.NUM_DOC = A.RUT
	                   AND CODBEN = 348
	               ),
	               'NO'
	           )                AS 'CRAE',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456/*409*/ THEN 'SI'
	                               ELSE 'NO'
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456/*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               'NO'
	           )                AS 'LIDER',
	           CASE (
	                    SELECT 1
	                    FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                    WHERE  B.NUM_DOC = P.CODPOSTUL
	                           AND B.SIGLA = 'UDD'
	                           AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                           AND B.CARRERA = MC.COD_DEMRE
	                )
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END              AS 'BEA',
	           P.POND           AS 'PONDERADO CARRERA',
	           CASE COALESCE(P.ANOPSU, 0)
	                WHEN 0 THEN 0
	                ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', A.RUT, P.ANOPSU)
	           END              AS 'PROMEDIO PSU',
	           0                AS 'POST_EFECT_CARR',
	           0                AS 'POST_EFECT_SEDE',
	           0                AS 'POST_EFECT_UDD',
	           @ANOPROCESO      AS ANO,
	           @PERIODOPROCESO  AS PERIODO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456/*409*/ THEN VALOR
	                               ELSE 0
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456/*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               0
	           )                AS 'VALOR_LIDER',
	           'PRESELEC_CAE_INGRESA' = ISNULL(
	               (
	                   SELECT DISTINCT('SI')
	                   FROM   MT_CRAE_CARGATMP 
	                          MCC
	                   WHERE  MCC.RUT = P.CODPOSTUL
	                          AND MCC.TIPO = 'N'
	               ),
	               'NO'
	           ),
	           MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 'BECAS',
	           MC3.CODCOL        AS RBD,
	           MC3.NOMBRE    AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	           --CASE COALESCE(UET.[TARGET], 0)
	           --     WHEN 1 THEN 'SI'
	           --     ELSE 'NO'
	           --END              AS [TARGET],
	           MP.PAAVERBAL,
	           MP.PAAMATEMAT,
	           MP.PAAHISGEO,
	           MP.PCEBIO,
	           MP.PTJE_RANKING,
	           MP.NOTAEM        AS PONDEM,
	           CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT CONVERT(VARCHAR(10), MAX(MM.FECHA_REGISTRO), 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       	AND MM.REMATRICULA IS NULL
                                --ORDER BY
                                --       MM.FECHA_REGISTRO ASC
                            )
                  END        AS FEC_MAT,
	           A.TIPO_MATRICULA,
	           C.NACIONALIDAD
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
	           INNER JOIN MT_CLIENT C
	                ON  C.CODCLI = A.RUT
	           INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA MC
	                ON  MC.CODCARR = A.CODCARPR
	           INNER JOIN MT_COMUNA mc2
	                ON  MC2.CODCOM = C.COMUNAPRO
	           LEFT JOIN MT_PAA MP
	                ON  MP.CODCLI = P.CODPOSTUL
	                AND MP.ANO = P.ANOPSU
	           LEFT JOIN ADM_DATOS_POSTULANTES ADP
	                ON  ADP.CODCLI = A.RUT
	                AND ADP.CODCARR = A.CODCARPR
	                LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = C.COLEGIO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	           --     ON  AI.NUM_DOC = A.RUT
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	           --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	           --     AND UE.UED_CODIGO = AI.UED_CODIGO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	           --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	           --     AND UET.UED_CODIGO = UE.UED_CODIGO
	    WHERE  (A.CODCARPR = @CODCARR OR @CODCARR IS NULL)
	           AND (A.CODSEDE = @CODSEDE OR @CODSEDE IS NULL)
	           AND A.ANO_MAT = @ANOPROCESO
	           AND A.PERIODO_MAT = @PERIODOPROCESO
	           AND A.ANO = A.ANO_MAT
	           AND A.PERIODO = A.PERIODO_MAT
	           AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           AND MC.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	    UNION
	    SELECT A.CODSEDE        AS 'SEDE',
	           A.CODCARPR       AS 'CODCARR',
	           MC.COD_DEMRE,
	           MC.NOMBRE        AS 'NOMBRE CARRERA',
	           A.RUT            AS 'RUN',
	           C.DIG            AS 'DV',
	           C.PATERNO,
	           C.MATERNO,
	           C.NOMBRE,
	           C.DIRPROC        AS DIRECCION,
	           C.COMUNA,
	           MC2.CODREGION    AS REGION,
	           C.EMAILPOSTULANTE,
	           C.FONOACT        AS 'TELEFONO',
	           C.CELULARPOSTULANTE,
	           COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR EN LISTA',
	           COALESCE(P.prioridad,0) AS PREFERENCIA,
	           --PREFERENCIA = ISNULL(
	           --    (
	           --        SELECT ADP.PREFERENCIA
	           --        FROM   ADM_DATOS_POSTULANTES ADP
	           --        WHERE  ADP.CODCLI = A.RUT
	           --               AND ADP.CODCARR = A.CODCARPR
	           --    ),
	           --    0
	           --),
	           'SI' AS 'MATRICULADO',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 348
	                   AND VALOR = 1 THEN 'SI'
	                       ELSE 'NO'
	                       END AS PRUEBA
	                       FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                       BE
	                       WHERE BE.NUM_DOC = A.RUT
	                   AND CODBEN = 348
	               ),
	               'NO'
	           )                AS 'CRAE',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                               ELSE 'NO'
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               'NO'
	           )                AS 'LIDER',
	           CASE (
	                    SELECT 1
	                    FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                    WHERE  B.NUM_DOC = P.CODPOSTUL
	                           AND B.SIGLA = 'UDD'
	                           AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                           AND B.CARRERA = MC.COD_DEMRE
	                )
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END              AS 'BEA',
	           P.POND           AS 'PONDERADO CARRERA',
	           CASE COALESCE(P.ANOPSU, 0)
	                WHEN 0 THEN 0
	                ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', A.RUT, P.ANOPSU)
	           END              AS 'PROMEDIO PSU',
	           0                AS 'POST_EFECT_CARR',
	           0                AS 'POST_EFECT_SEDE',
	           0                AS 'POST_EFECT_UDD',
	           @ANOPROCESO      AS ANO,
	           @PERIODOPROCESO  AS PERIODO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN VALOR
	                               ELSE 0
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               0
	           )                AS 'VALOR_LIDER',
	           'PRESELEC_CAE_INGRESA' = ISNULL(
	               (
	                   SELECT DISTINCT('SI')
	                   FROM   MT_CRAE_CARGATMP
	                          MCC
	                   WHERE  MCC.RUT = P.CODPOSTUL
	                          AND MCC.TIPO = 'N'
	               ),
	               'NO'
	           ),
	           MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 'BECAS',
	           MC3.CODCOL        AS RBD,
	           MC3.NOMBRE    AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	           --CASE COALESCE(UET.[TARGET], 0)
	           --     WHEN 1 THEN 'SI'
	           --     ELSE 'NO'
	           --END              AS [TARGET],
	           MP.PAAVERBAL,
	           MP.PAAMATEMAT,
	           MP.PAAHISGEO,
	           MP.PCEBIO,
	           MP.PTJE_RANKING,
	           MP.NOTAEM        AS PONDEM,
	           CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT CONVERT(VARCHAR(10), MAX(MM.FECHA_REGISTRO), 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       	AND MM.REMATRICULA IS NULL
                                --ORDER BY
                                --       MM.FECHA_REGISTRO ASC
                            )
                  END        AS FEC_MAT,
	           A.TIPO_MATRICULA,
	           C.NACIONALIDAD
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
	                AND V.CODTIPOVACANTE = 1
	                AND V.COD_VIA <> '30'
	           INNER JOIN MT_CLIENT C
	                ON  C.CODCLI = A.RUT
	           INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA MC
	                ON  MC.CODCARR = A.CODCARPR
	           INNER JOIN MT_COMUNA mc2
	                ON  MC2.CODCOM = C.COMUNAPRO
	           LEFT JOIN MT_PAA MP
	                ON  MP.CODCLI = P.CODPOSTUL
	                AND MP.ANO = P.ANOPSU
	                 LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = C.COLEGIO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	           --     ON  AI.NUM_DOC = A.RUT
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	           --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	           --     AND UE.UED_CODIGO = AI.UED_CODIGO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	           --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	           --     AND UET.UED_CODIGO = UE.UED_CODIGO
	    WHERE  (A.CODCARPR = @CODCARR OR @CODCARR IS NULL)
	           AND (A.CODSEDE = @CODSEDE OR @CODSEDE IS NULL)
	           AND A.ANO_MAT = @ANOPROCESO
	           AND A.PERIODO_MAT = @PERIODOPROCESO
	           AND A.ANO = A.ANO_MAT
	           AND A.PERIODO = A.PERIODO_MAT
	           AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           AND MC.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	END
	--/////-----------------------------------------------------------------------------------------------------------------------------------/////--
	IF @NOMINA = 3 --CUPO OFICIAL
	BEGIN
	    SELECT A.CODSEDE        AS 'SEDE',
	           A.CODCARPR       AS 'CODCARR',
	           MC.COD_DEMRE,
	           MC.NOMBRE        AS 'NOMBRE CARRERA',
	           A.RUT            AS 'RUN',
	           C.DIG            AS 'DV',
	           C.PATERNO,
	           C.MATERNO,
	           C.NOMBRE,
	           C.DIRPROC        AS DIRECCION,
	           C.COMUNA,
	           MC2.CODREGION    AS REGION,
	           C.EMAILPOSTULANTE,
	           C.FONOACT        AS 'TELEFONO',
	           C.CELULARPOSTULANTE,
	           COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR EN LISTA',
	           COALESCE(P.prioridad,0) AS PREFERENCIA,
	           --PREFERENCIA = COALESCE(
	           --    (
	           --        SELECT ADP.PREFERENCIA
	           --        FROM   ADM_DATOS_POSTULANTES ADP
	           --        WHERE  ADP.CODCLI = A.RUT
	           --               AND ADP.CODCARR = A.CODCARPR
	           --    ),
	           --    0
	           --),
	           'SI' AS 'MATRICULADO',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 348
	                   AND VALOR = 1 THEN 'SI'
	                       ELSE 'NO'
	                       END AS PRUEBA
	                       FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES BE
	                       WHERE BE.NUM_DOC = A.RUT
	                   AND CODBEN = 348
	               ),
	               'NO'
	           )                AS 'CRAE',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                               ELSE 'NO'
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               'NO'
	           )                AS 'LIDER',
	           CASE (
	                    SELECT 1
	                    FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                    WHERE  B.NUM_DOC = P.CODPOSTUL
	                           AND B.SIGLA = 'UDD'
	                           AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                           AND B.CARRERA = MC.COD_DEMRE
	                )
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END              AS 'BEA',
	           P.POND           AS 'PONDERADO CARRERA',
	           CASE COALESCE(P.ANOPSU, 0)
	                WHEN 0 THEN 0
	                ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', A.RUT, P.ANOPSU)
	           END              AS 'PROMEDIO PSU',
	           0                AS 'POST_EFECT_CARR',
	           0                AS 'POST_EFECT_SEDE',
	           0                AS 'POST_EFECT_UDD',
	           @ANOPROCESO      AS ANO,
	           @PERIODOPROCESO  AS PERIODO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN VALOR
	                               ELSE 0
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               0
	           )                AS 'VALOR_LIDER',
	           'PRESELEC_CAE_INGRESA' = ISNULL(
	               (
	                   SELECT DISTINCT('SI')
	                   FROM   MT_CRAE_CARGATMP 
	                          MCC
	                   WHERE  MCC.RUT = P.CODPOSTUL
	                          AND MCC.TIPO = 'N'
	               ),
	               'NO'
	           ),
	           MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 'BECAS',
	           MC3.CODCOL            AS RBD,
	           MC3.NOMBRE            AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS 
	           DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	           MP.PAAVERBAL,
	           MP.PAAMATEMAT,
	           MP.PAAHISGEO,
	           MP.PCEBIO,
	           MP.PTJE_RANKING,
	           MP.NOTAEM        AS PONDEM,
	           CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT TOP 1 CONVERT(VARCHAR(10), MM.FECHA_REGISTRO, 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       AND MM.REMATRICULA IS NULL
                                ORDER BY
                                       MM.FECHA_REGISTRO DESC
                            )
                  END        AS FEC_MAT,
	           --CONVERT(VARCHAR(10), MA.FEC_MAT, 103) AS FEC_MAT,
	           A.TIPO_MATRICULA,
	           C.NACIONALIDAD
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
	                AND V.CODTIPOVACANTE = 1
	                AND V.COD_VIA <> '30'
	           INNER JOIN MT_CLIENT C
	                ON  C.CODCLI = A.RUT
	           INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA MC
	                ON  MC.CODCARR = A.CODCARPR
	           INNER JOIN MT_COMUNA mc2
	                ON  MC2.CODCOM = C.COMUNAPRO
	           INNER JOIN MT_PAA MP
	                ON  MP.CODCLI = P.CODPOSTUL --.RUT
	                AND MP.ANO = P.ANOPSU
	                  LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = c.COLEGIO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	           --     ON  AI.NUM_DOC = A.RUT
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	           --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	           --     AND UE.UED_CODIGO = AI.UED_CODIGO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	           --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	           --     AND UET.UED_CODIGO = UE.UED_CODIGO
	    WHERE  (A.CODCARPR = @CODCARR OR @CODCARR IS NULL)
	           AND (A.CODSEDE = @CODSEDE OR @CODSEDE IS NULL)
	           AND A.ANO_MAT = @ANOPROCESO
	           AND A.PERIODO_MAT = @PERIODOPROCESO
	           AND A.ANO = A.ANO_MAT
	           AND A.PERIODO = A.PERIODO_MAT
	           AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           AND MC.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	    ORDER BY
	           P.LUGARENLISTA
	END
	--/////-----------------------------------------------------------------------------------------------------------------------------------/////--
	IF @NOMINA = 4 --SOBRECUPO
	BEGIN
	    SELECT A.CODSEDE        AS 'SEDE',
	           A.CODCARPR       AS 'CODCARR',
	           MC.COD_DEMRE,
	           MC.NOMBRE        AS 'NOMBRE CARRERA',
	           A.RUT            AS 'RUN',
	           C.DIG            AS 'DV',
	           C.PATERNO,
	           C.MATERNO,
	           C.NOMBRE,
	           C.DIRPROC        AS DIRECCION,
	           C.COMUNA,
	           MC2.CODREGION    AS REGION,
	           C.EMAILPOSTULANTE,
	           C.FONOACT        AS 'TELEFONO',
	           C.CELULARPOSTULANTE,
	           COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR EN LISTA',
	           COALESCE(P.prioridad,0) AS PREFERENCIA,
	           --PREFERENCIA = ISNULL(
	           --    (
	           --        SELECT ADP.PREFERENCIA
	           --        FROM   ADM_DATOS_POSTULANTES ADP
	           --        WHERE  ADP.CODCLI = A.RUT
	           --               AND ADP.CODCARR = A.CODCARPR
	           --    ),
	           --    0
	           --),
	           'SI' AS 'MATRICULADO',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 348
	                   AND VALOR = 1 THEN 'SI'
	                       ELSE 'NO'
	                       END AS PRUEBA
	                       FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                       BE
	                       WHERE BE.NUM_DOC = A.RUT
	                   AND CODBEN = 348
	               ),
	               'NO'
	           )                AS 'CRAE',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                               ELSE 'NO'
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               'NO'
	           )                AS 'LIDER',
	           CASE (
	                    SELECT 1
	                    FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                    WHERE  B.NUM_DOC = P.CODPOSTUL
	                           AND B.SIGLA = 'UDD'
	                           AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                           AND B.CARRERA = MC.COD_DEMRE
	                )
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END              AS 'BEA',
	           P.POND           AS 'PONDERADO CARRERA',
	           CASE COALESCE(P.ANOPSU, 0)
	                WHEN 0 THEN 0
	                ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', A.RUT, P.ANOPSU)
	           END              AS 'PROMEDIO PSU',
	           0                AS 'POST_EFECT_CARR',
	           0                AS 'POST_EFECT_SEDE',
	           0                AS 'POST_EFECT_UDD',
	           @ANOPROCESO      AS ANO,
	           @PERIODOPROCESO  AS PERIODO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN VALOR
	                               ELSE 0
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               0
	           )                AS 'VALOR_LIDER',
	           'PRESELEC_CAE_INGRESA' = ISNULL(
	               (
	                   SELECT DISTINCT('SI')
	                   FROM   MT_CRAE_CARGATMP 
	                          MCC
	                   WHERE  MCC.RUT = P.CODPOSTUL
	                          AND MCC.TIPO = 'N'
	               ),
	               'NO'
	           ),
	           MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 'BECAS',
	           MC3.CODCOL            AS RBD,
	           MC3.NOMBRE            AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS 
	           DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	           MP.PAAVERBAL,
	           MP.PAAMATEMAT,
	           MP.PAAHISGEO,
	           MP.PCEBIO,
	           MP.PTJE_RANKING,
	           MP.NOTAEM        AS PONDEM,
	           CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT TOP 1 CONVERT(VARCHAR(10), MM.FECHA_REGISTRO, 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       	AND MM.REMATRICULA IS NULL
                                ORDER BY
                                       MM.FECHA_REGISTRO DESC
                            )
                  END        AS FEC_MAT,
	           A.TIPO_MATRICULA,
	           C.NACIONALIDAD
	    FROM   MT_ALUMNO A
	           INNER JOIN MT_POSCAR P
	                ON  P.CODPOSTUL = A.RUT
	                AND P.CODCARR = A.CODCARPR
	                AND P.ANO = A.ANO
	                AND P.PERIODO = A.PERIODO
	                AND COALESCE(P.LUGARENLISTA, 0)> /*BETWEEN*/ (
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
	                AND V.CODTIPOVACANTE = 1
	                AND V.COD_VIA <> '30'
	           INNER JOIN MT_CLIENT C
	                ON  C.CODCLI = A.RUT
	           INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA MC
	                ON  MC.CODCARR = A.CODCARPR
	           INNER JOIN MT_COMUNA mc2
	                ON  MC2.CODCOM = C.COMUNAPRO
	           LEFT JOIN MT_PAA MP
	                ON  MP.CODCLI = P.CODPOSTUL
	                AND MP.ANO = P.ANOPSU
	           LEFT JOIN ADM_DATOS_POSTULANTES ADP
	                ON  ADP.CODCLI = A.RUT
	                AND ADP.CODCARR = A.CODCARPR
	                LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = C.COLEGIO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	           --     ON  AI.NUM_DOC = A.RUT
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	           --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	           --     AND UE.UED_CODIGO = AI.UED_CODIGO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	           --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	           --     AND UET.UED_CODIGO = UE.UED_CODIGO
	    WHERE  (A.CODCARPR = @CODCARR OR @CODCARR IS NULL)
	           AND (A.CODSEDE = @CODSEDE OR @CODSEDE IS NULL)
	           AND A.ANO_MAT = @ANOPROCESO
	           AND A.PERIODO_MAT = @PERIODOPROCESO
	           AND A.ANO = A.ANO_MAT
	           AND A.PERIODO = A.PERIODO_MAT
	           AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           AND MC.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	    ORDER BY
	           P.LUGARENLISTA
	END
	--/////-----------------------------------------------------------------------------------------------------------------------------------/////--
	IF @NOMINA = 5 --LISTA ESPERA
	BEGIN
	    SELECT A.CODSEDE        AS 'SEDE',
	           A.CODCARPR       AS 'CODCARR',
	           MC.COD_DEMRE,
	           MC.NOMBRE        AS 'NOMBRE CARRERA',
	           A.RUT            AS 'RUN',
	           C.DIG            AS 'DV',
	           C.PATERNO,
	           C.MATERNO,
	           C.NOMBRE,
	           C.DIRPROC        AS DIRECCION,
	           C.COMUNA,
	           MC2.CODREGION    AS REGION,
	           C.EMAILPOSTULANTE,
	           C.FONOACT        AS 'TELEFONO',
	           C.CELULARPOSTULANTE,
	           COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR EN LISTA',
	           COALESCE(P.prioridad,0) AS PREFERENCIA,
	           --PREFERENCIA = ISNULL(
	           --    (
	           --        SELECT ADP.PREFERENCIA
	           --        FROM   ADM_DATOS_POSTULANTES ADP
	           --        WHERE  ADP.CODCLI = A.RUT
	           --               AND ADP.CODCARR = A.CODCARPR
	           --    ),
	           --    0
	           --),
	           'SI' AS 'MATRICULADO',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 348
	                   AND VALOR = 1 THEN 'SI'
	                       ELSE 'NO'
	                       END AS PRUEBA
	                       FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                       BE
	                       WHERE BE.NUM_DOC = A.RUT
	                   AND CODBEN = 348
	               ),
	               'NO'
	           )                AS 'CRAE',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                               ELSE 'NO'
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               'NO'
	           )                AS 'LIDER',
	           CASE (
	                    SELECT 1
	                    FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                    WHERE  B.NUM_DOC = P.CODPOSTUL
	                           AND B.SIGLA = 'UDD'
	                           AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                           AND B.CARRERA = MC.COD_DEMRE
	                )
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END              AS 'BEA',
	           P.POND           AS 'PONDERADO CARRERA',
	           CASE COALESCE(P.ANOPSU, 0)
	                WHEN 0 THEN 0
	                ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', A.RUT, P.ANOPSU)
	           END              AS 'PROMEDIO PSU',
	           0                AS 'POST_EFECT_CARR',
	           0                AS 'POST_EFECT_SEDE',
	           0                AS 'POST_EFECT_UDD',
	           @ANOPROCESO      AS ANO,
	           @PERIODOPROCESO  AS PERIODO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN VALOR
	                               ELSE 0
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               0
	           )                AS 'VALOR_LIDER',
	           'PRESELEC_CAE_INGRESA' = ISNULL(
	               (
	                   SELECT DISTINCT('SI')
	                   FROM   MT_CRAE_CARGATMP
	                          MCC
	                   WHERE  MCC.RUT = P.CODPOSTUL
	                          AND MCC.TIPO = 'N'
	               ),
	               'NO'
	           ),
	           MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 'BECAS',
	           MC3.CODCOL            AS RBD,
	           MC3.NOMBRE            AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS 
	           DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	           MP.PAAVERBAL,
	           MP.PAAMATEMAT,
	           MP.PAAHISGEO,
	           MP.PCEBIO,
	           MP.PTJE_RANKING,
	           MP.NOTAEM        AS PONDEM,
	           CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT TOP 1 CONVERT(VARCHAR(10), MM.FECHA_REGISTRO, 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       	AND MM.REMATRICULA IS NULL
                                ORDER BY
                                       MM.FECHA_REGISTRO DESC
                            )
                  END        AS FEC_MAT,
	           A.TIPO_MATRICULA,
	           C.NACIONALIDAD
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
	                AND V.CODTIPOVACANTE = 1
	                AND V.COD_VIA <> '30'
	           INNER JOIN MT_CLIENT C
	                ON  C.CODCLI = A.RUT
	           INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA MC
	                ON  MC.CODCARR = A.CODCARPR
	           INNER JOIN MT_COMUNA mc2
	                ON  MC2.CODCOM = C.COMUNAPRO
	           LEFT JOIN MT_PAA MP
	                ON  MP.CODCLI = P.CODPOSTUL
	                AND MP.ANO = P.ANOPSU
	                LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = C.COLEGIO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	           --     ON  AI.NUM_DOC = A.RUT
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	           --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	           --     AND UE.UED_CODIGO = AI.UED_CODIGO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	           --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	           --     AND UET.UED_CODIGO = UE.UED_CODIGO
	    WHERE  (A.CODCARPR = @CODCARR OR @CODCARR IS NULL)
	           AND (A.CODSEDE = @CODSEDE OR @CODSEDE IS NULL)
	           AND A.ANO_MAT = @ANOPROCESO
	           AND A.PERIODO_MAT = @PERIODOPROCESO
	           AND A.ANO = A.ANO_MAT
	           AND A.PERIODO = A.PERIODO_MAT
	           AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           AND MC.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	    ORDER BY
	           P.LUGARENLISTA
	END
	--/////-----------------------------------------------------------------------------------------------------------------------------------/////--
	IF @NOMINA = 6 --BEA
	BEGIN
	    SELECT A.CODSEDE        AS 'SEDE',
	           A.CODCARPR       AS 'CODCARR',
	           MC.COD_DEMRE,
	           MC.NOMBRE        AS 'NOMBRE CARRERA',
	           A.RUT            AS 'RUN',
	           C.DIG            AS 'DV',
	           C.PATERNO,
	           C.MATERNO,
	           C.NOMBRE,
	           C.DIRPROC AS DIRECCION,
	           C.COMUNAPRO AS COMUNA,
	           MC2.CODREGION AS REGION,
	           C.EMAILPOSTULANTE,
	           C.FONOACT        AS 'TELEFONO',
	           C.CELULARPOSTULANTE,
	           PC.LUGARENLISTA AS  'LUGAR EN LISTA',
	           PC.PRIORIDAD AS PREFERENCIA,
	           'SI' AS             MATRICULADO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 348
	                   AND VALOR = 1 THEN 'SI'
	                       ELSE 'NO'
	                       END AS PRUEBA
	                       FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                       BE
	                       WHERE BE.NUM_DOC = A.RUT
	                   AND CODBEN = 348
	               ),
	               'NO'
	           )                AS 'CRAE',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                               ELSE 'NO'
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = PC.CODPOSTUL
	                               AND MP.CODCARR = PC.CODCARR
	                   WHERE  BE.NUM_DOC = PC.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               'NO'
	           )                AS 'LIDER',
	           CASE (
	                    SELECT 1
	                    FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                    WHERE  B.NUM_DOC = PC.CODPOSTUL
	                           AND B.SIGLA = 'UDD'
	                           AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                           AND B.CARRERA = MC.COD_DEMRE
	                )
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END              AS 'BEA',
	           ADP.POND         AS 'PONDERADO CARRERA',
	           CASE COALESCE(PC.ANOPSU, 0)
	                WHEN 0 THEN 0
	                ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', ADP.CODCLI, PC.ANOPSU)
	           END              AS 'PROMEDIO PSU',
	           0                AS 'POST_EFECT_CARR',
	           0                AS 'POST_EFECT_SEDE',
	           0                AS 'POST_EFECT_UDD',
	           @ANOPROCESO      AS ANO,
	           @PERIODOPROCESO  AS PERIODO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN VALOR
	                               ELSE 0
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = PC.CODPOSTUL
	                               AND MP.CODCARR = PC.CODCARR
	                   WHERE  BE.NUM_DOC = PC.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               0
	           )                AS 'VALOR_LIDER',
	           'PRESELEC_CAE_INGRESA' = ISNULL(
	               (
	                   SELECT DISTINCT('SI')
	                   FROM   MT_CRAE_CARGATMP 
	                          MCC
	                   WHERE  MCC.RUT = PC.CODPOSTUL
	                          AND MCC.TIPO = 'N'
	               ),
	               'NO'
	           ),
	           MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 'BECAS',
	           MC3.CODCOL            AS RBD,
	           MC3.NOMBRE            AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS 
	           DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	           MP.PAAVERBAL,
	           MP.PAAMATEMAT,
	           MP.PAAHISGEO,
	           MP.PCEBIO,
	           MP.PTJE_RANKING,
	           MP.NOTAEM AS PONDEM,
	           CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT TOP 1 CONVERT(VARCHAR(10), MM.FECHA_REGISTRO, 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       	AND MM.REMATRICULA IS NULL
                                ORDER BY
                                       MM.FECHA_REGISTRO DESC
                            )
                  END        AS FEC_MAT,
	           TIPO_MATRICULA = (
	               SELECT A.TIPO_MATRICULA
	               FROM   MATRICULA.MT_ALUMNO A
	               WHERE  A.RUT = ADP.CODCLI
	                      AND A.CODCARPR = ADP.CODCARR
	                      AND A.ANO_MAT = @ANOPROCESO
	                      AND A.PERIODO_MAT = @PERIODOPROCESO
	                      AND A.ANO = @ANOPROCESO
	                      AND A.PERIODO = @PERIODOPROCESO
	           ),
	           C.NACIONALIDAD
	    FROM   MT_ALUMNO A
	           INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA MC
	                ON  MC.CODCARR = A.CODCARPR
	           INNER JOIN MT_CLIENT C
	                ON  C.CODCLI = A.RUT
	           INNER JOIN ADM_DATOS_POSTULANTES ADP
	                ON  ADP.CODCLI = A.RUT
	                AND ADP.CODCARR = A.CODCARPR
	                AND (LTRIM(RTRIM(A.COD_VIA)) = '30')
	                    --AND (LTRIM(RTRIM(A.COD_VIA)) = '30' OR ADP.TIENE_BEA = 1)
	                AND ADP.ESTADO = 'P'
	           INNER JOIN MT_POSCAR PC
	                ON  ADP.CODCLI = PC.CODPOSTUL
	                AND ADP.CODCARR = PC.CODCARR
	                AND PC.ANO = @ANOPROCESO
	                AND PC.PERIODO = @PERIODOPROCESO
	                LEFT JOIN MT_PAA AS mp 
	                ON mp.CODCLI = a.RUT AND mp.ANO = PC.ANOPSU
	                LEFT JOIN MT_COMUNA AS mc2 
	                ON C.COMUNAPRO = MC2.CODCOM
	                LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = C.COLEGIO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	           --     ON  AI.NUM_DOC = A.RUT
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	           --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	           --     AND UE.UED_CODIGO = AI.UED_CODIGO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	           --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	           --     AND UET.UED_CODIGO = UE.UED_CODIGO
	    WHERE  (A.CODSEDE = @CODSEDE OR @CODSEDE IS NULL)
	           AND (A.CODCARPR = @CODCARR OR @CODCARR IS NULL)
	           AND A.ANO = @ANOPROCESO
	           AND A.PERIODO = @PERIODOPROCESO
	           AND A.ANO_MAT = A.ANO
	           AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           AND MC.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	    ORDER BY
	           A.RUT
	END
	--/////-----------------------------------------------------------------------------------------------------------------------------------/////--
	IF @NOMINA = 7 --CUPO OFICIAL + SOBRECUPO + LISTA ESPERA + BEA
	BEGIN
	    SELECT A.CODSEDE        AS 'SEDE',
	           A.CODCARPR       AS 'CODCARR',
	           MC.COD_DEMRE,
	           MC.NOMBRE        AS 'NOMBRE CARRERA',
	           A.RUT            AS 'RUN',
	           C.DIG            AS 'DV',
	           C.PATERNO,
	           C.MATERNO,
	           C.NOMBRE,
	           C.DIRPROC        AS DIRECCION,
	           C.COMUNA,
	           MC2.CODREGION    AS REGION,
	           C.EMAILPOSTULANTE,
	           C.FONOPROC AS 'TELEFONO',
	           C.CELULARPOSTULANTE,
	           COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR EN LISTA',
	           COALESCE(P.PRIORIDAD,0) AS PREFERENCIA,
	           --PREFERENCIA = COALESCE(
	           --    (
	           --        SELECT ADP.PREFERENCIA
	           --        FROM   ADM_DATOS_POSTULANTES ADP
	           --        WHERE  ADP.CODCLI = A.RUT
	           --               AND ADP.CODCARR = A.CODCARPR
	           --    ),
	           --    0
	           --),
	           'SI' AS 'MATRICULADO',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 348
	                   AND VALOR = 1 THEN 'SI'
	                       ELSE 'NO'
	                       END AS PRUEBA
	                       FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES BE
	                       WHERE BE.NUM_DOC = A.RUT
	                   AND CODBEN = 348
	               ),
	               'NO'
	           )                AS 'CRAE',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                               ELSE 'NO'
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               'NO'
	           )                AS 'LIDER',
	           CASE (
	                    SELECT 1
	                    FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                    WHERE  B.NUM_DOC = P.CODPOSTUL
	                           AND B.SIGLA = 'UDD'
	                           AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                           AND B.CARRERA = MC.COD_DEMRE
	                )
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END              AS 'BEA',
	           P.POND           AS 'PONDERADO CARRERA',
	           CASE COALESCE(P.ANOPSU, 0)
	                WHEN 0 THEN 0
	                ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', A.RUT, P.ANOPSU)
	           END              AS 'PROMEDIO PSU',
	           0                AS 'POST_EFECT_CARR',
	           0                AS 'POST_EFECT_SEDE',
	           0                AS 'POST_EFECT_UDD',
	           @ANOPROCESO      AS ANO,
	           @PERIODOPROCESO  AS PERIODO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN VALOR
	                               ELSE 0
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               0
	           )                AS 'VALOR_LIDER',
	           'PRESELEC_CAE_INGRESA' = ISNULL(
	               (
	                   SELECT DISTINCT('SI')
	                   FROM   MT_CRAE_CARGATMP 
	                          MCC
	                   WHERE  MCC.RUT = P.CODPOSTUL
	                          AND MCC.TIPO = 'N'
	               ),
	               'NO'
	           ),
	           MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 'BECAS',
	           MC3.CODCOL            AS RBD,
	           MC3.NOMBRE            AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS 
	           DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	           MP.PAAVERBAL,
	           MP.PAAMATEMAT,
	           MP.PAAHISGEO,
	           MP.PCEBIO,
	           MP.PTJE_RANKING,
	           MP.NOTAEM        AS PONDEM,
	           CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT CONVERT(VARCHAR(10), MAX(MM.FECHA_REGISTRO), 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       	AND MM.REMATRICULA IS NULL
                                --ORDER BY
                                --       MM.FECHA_REGISTRO ASC
                            )
                  END        AS FEC_MAT,
	           A.TIPO_MATRICULA,
	           C.NACIONALIDAD
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
	           INNER JOIN MT_CLIENT C
	                ON  C.CODCLI = A.RUT
	           INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA MC
	                ON  MC.CODCARR = A.CODCARPR
	           INNER JOIN MT_COMUNA mc2
	                ON  MC2.CODCOM = C.COMUNAPRO
	           INNER JOIN MT_PAA MP
	                ON  MP.CODCLI = P.CODPOSTUL --.RUT
	                AND MP.ANO = P.ANOPSU
	                 LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = C.COLEGIO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	           --     ON  AI.NUM_DOC = A.RUT
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	           --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	           --     AND UE.UED_CODIGO = AI.UED_CODIGO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	           --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	           --     AND UET.UED_CODIGO = UE.UED_CODIGO
	    WHERE  (A.CODCARPR = @CODCARR OR @CODCARR IS NULL)
	           AND (A.CODSEDE = @CODSEDE OR @CODSEDE IS NULL)
	           AND A.ANO_MAT = @ANOPROCESO
	           AND A.PERIODO_MAT = @PERIODOPROCESO
	           AND A.ANO = A.ANO_MAT
	           AND A.PERIODO = A.PERIODO_MAT
	           AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           AND MC.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	    UNION
	    SELECT A.CODSEDE        AS 'SEDE',
	           A.CODCARPR       AS 'CODCARR',
	           MC.COD_DEMRE,
	           MC.NOMBRE        AS 'NOMBRE CARRERA',
	           A.RUT            AS 'RUN',
	           C.DIG            AS 'DV',
	           C.PATERNO,
	           C.MATERNO,
	           C.NOMBRE,
	           C.DIRPROC        AS DIRECCION,
	           C.COMUNA,
	           MC2.CODREGION    AS REGION,
	           C.EMAILPOSTULANTE,
	           C.FONOACT        AS 'TELEFONO',
	           C.CELULARPOSTULANTE,
	           COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR EN LISTA',
	           COALESCE(P.PRIORIDAD,0) AS PREFERENCIA,
	           --PREFERENCIA = ISNULL(
	           --    (
	           --        SELECT ADP.PREFERENCIA
	           --        FROM   ADM_DATOS_POSTULANTES ADP
	           --        WHERE  ADP.CODCLI = A.RUT
	           --               AND ADP.CODCARR = A.CODCARPR
	           --    ),
	           --    0
	           --),
	           'SI' AS 'MATRICULADO',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 348
	                   AND VALOR = 1 THEN 'SI'
	                       ELSE 'NO'
	                       END AS PRUEBA
	                       FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                       BE
	                       WHERE BE.NUM_DOC = A.RUT
	                   AND CODBEN = 348
	               ),
	               'NO'
	           )                AS 'CRAE',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                               ELSE 'NO'
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               'NO'
	           )                AS 'LIDER',
	           CASE (
	                    SELECT 1
	                    FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                    WHERE  B.NUM_DOC = P.CODPOSTUL
	                           AND B.SIGLA = 'UDD'
	                           AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                           AND B.CARRERA = MC.COD_DEMRE
	                )
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END              AS 'BEA',
	           P.POND           AS 'PONDERADO CARRERA',
	           CASE COALESCE(P.ANOPSU, 0)
	                WHEN 0 THEN 0
	                ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', A.RUT, P.ANOPSU)
	           END              AS 'PROMEDIO PSU',
	           0                AS 'POST_EFECT_CARR',
	           0                AS 'POST_EFECT_SEDE',
	           0                AS 'POST_EFECT_UDD',
	           @ANOPROCESO      AS ANO,
	           @PERIODOPROCESO  AS PERIODO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN VALOR
	                               ELSE 0
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               0
	           )                AS 'VALOR_LIDER',
	           'PRESELEC_CAE_INGRESA' = ISNULL(
	               (
	                   SELECT DISTINCT('SI')
	                   FROM   MT_CRAE_CARGATMP 
	                          MCC
	                   WHERE  MCC.RUT = P.CODPOSTUL
	                          AND MCC.TIPO = 'N'
	               ),
	               'NO'
	           ),
	           MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 'BECAS',
	           MC3.CODCOL            AS RBD,
	           MC3.NOMBRE            AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS 
	           DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	           MP.PAAVERBAL,
	           MP.PAAMATEMAT,
	           MP.PAAHISGEO,
	           MP.PCEBIO,
	           MP.PTJE_RANKING,
	           MP.NOTAEM        AS PONDEM,
	           CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT CONVERT(VARCHAR(10), MAX(MM.FECHA_REGISTRO), 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       	AND MM.REMATRICULA IS NULL
                                --ORDER BY
                                --       MM.FECHA_REGISTRO ASC
                            )
                  END        AS FEC_MAT,
	           A.TIPO_MATRICULA,
	           C.NACIONALIDAD
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
	                AND V.CODTIPOVACANTE = 1
	                AND V.COD_VIA <> '30'
	           INNER JOIN MT_CLIENT C
	                ON  C.CODCLI = A.RUT
	           INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA MC
	                ON  MC.CODCARR = A.CODCARPR
	           INNER JOIN MT_COMUNA mc2
	                ON  MC2.CODCOM = C.COMUNAPRO
	           LEFT JOIN MT_PAA MP
	                ON  MP.CODCLI = P.CODPOSTUL
	                AND MP.ANO = P.ANOPSU
	           LEFT JOIN ADM_DATOS_POSTULANTES ADP
	                ON  ADP.CODCLI = A.RUT
	                AND ADP.CODCARR = A.CODCARPR
	           LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = C.COLEGIO    
	           --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	           --     ON  AI.NUM_DOC = A.RUT
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	           --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	           --     AND UE.UED_CODIGO = AI.UED_CODIGO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	           --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	           --     AND UET.UED_CODIGO = UE.UED_CODIGO
	    WHERE  (A.CODCARPR = @CODCARR OR @CODCARR IS NULL)
	           AND (A.CODSEDE = @CODSEDE OR @CODSEDE IS NULL)
	           AND A.ANO_MAT = @ANOPROCESO
	           AND A.PERIODO_MAT = @PERIODOPROCESO
	           AND A.ANO = A.ANO_MAT
	           AND A.PERIODO = A.PERIODO_MAT
	           AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           AND MC.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	    UNION
	    SELECT A.CODSEDE        AS 'SEDE',
	           A.CODCARPR       AS 'CODCARR',
	           MC.COD_DEMRE,
	           MC.NOMBRE        AS 'NOMBRE CARRERA',
	           A.RUT            AS 'RUN',
	           C.DIG            AS 'DV',
	           C.PATERNO,
	           C.MATERNO,
	           C.NOMBRE,
	           C.DIRPROC        AS DIRECCION,
	           C.COMUNA,
	           MC2.CODREGION    AS REGION,
	           C.EMAILPOSTULANTE,
	           C.FONOACT        AS 'TELEFONO',
	           C.CELULARPOSTULANTE,
	           COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR EN LISTA',
	           COALESCE(P.PRIORIDAD,0) AS PREFERENCIA,
	           --PREFERENCIA = ISNULL(
	           --    (
	           --        SELECT ADP.PREFERENCIA
	           --        FROM   ADM_DATOS_POSTULANTES ADP
	           --        WHERE  ADP.CODCLI = A.RUT
	           --               AND ADP.CODCARR = A.CODCARPR
	           --    ),
	           --    0
	           --),
	           'SI' AS 'MATRICULADO',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 348
	                   AND VALOR = 1 THEN 'SI'
	                       ELSE 'NO'
	                       END AS PRUEBA
	                       FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                       BE
	                       WHERE BE.NUM_DOC = A.RUT
	                   AND CODBEN = 348
	               ),
	               'NO'
	           )                AS 'CRAE',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                               ELSE 'NO'
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               'NO'
	           )                AS 'LIDER',
	           CASE (
	                    SELECT 1
	                    FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                    WHERE  B.NUM_DOC = P.CODPOSTUL
	                           AND B.SIGLA = 'UDD'
	                           AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                           AND B.CARRERA = MC.COD_DEMRE
	                )
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END              AS 'BEA',
	           P.POND           AS 'PONDERADO CARRERA',
	           CASE COALESCE(P.ANOPSU, 0)
	                WHEN 0 THEN 0
	                ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', A.RUT, P.ANOPSU)
	           END              AS 'PROMEDIO PSU',
	           0                AS 'POST_EFECT_CARR',
	           0                AS 'POST_EFECT_SEDE',
	           0                AS 'POST_EFECT_UDD',
	           @ANOPROCESO      AS ANO,
	           @PERIODOPROCESO  AS PERIODO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN VALOR
	                               ELSE 0
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               0
	           )                AS 'VALOR_LIDER',
	           'PRESELEC_CAE_INGRESA' = ISNULL(
	               (
	                   SELECT DISTINCT('SI')
	                   FROM   MT_CRAE_CARGATMP
	                          MCC
	                   WHERE  MCC.RUT = P.CODPOSTUL
	                          AND MCC.TIPO = 'N'
	               ),
	               'NO'
	           ),
	           MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 'BECAS',
	           MC3.CODCOL            AS RBD,
	           MC3.NOMBRE            AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS 
	           DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	           MP.PAAVERBAL,
	           MP.PAAMATEMAT,
	           MP.PAAHISGEO,
	           MP.PCEBIO,
	           MP.PTJE_RANKING,
	           MP.NOTAEM        AS PONDEM,
	           CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT CONVERT(VARCHAR(10), MAX(MM.FECHA_REGISTRO), 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       	AND MM.REMATRICULA IS NULL
                                --ORDER BY
                                --       MM.FECHA_REGISTRO ASC
                            )
                  END        AS FEC_MAT,
	           A.TIPO_MATRICULA,
	           C.NACIONALIDAD
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
	           INNER JOIN MT_CLIENT C
	                ON  C.CODCLI = A.RUT
	           INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA MC
	                ON  MC.CODCARR = A.CODCARPR
	           LEFT JOIN MT_COMUNA mc2
	                ON  MC2.CODCOM = C.COMUNAPRO
	           LEFT JOIN MT_PAA MP
	                ON  MP.CODCLI = P.CODPOSTUL
	                AND MP.ANO = P.ANOPSU
	           LEFT JOIN MT_COLEGIO  AS MC3
	                ON  MC3.CODCOL = C.COLEGIO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	           --     ON  AI.NUM_DOC = A.RUT
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	           --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	           --     AND UE.UED_CODIGO = AI.UED_CODIGO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	           --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	           --     AND UET.UED_CODIGO = UE.UED_CODIGO
	    WHERE  (A.CODCARPR = @CODCARR OR @CODCARR IS NULL)
	           AND (A.CODSEDE = @CODSEDE OR @CODSEDE IS NULL)
	           AND A.ANO_MAT = @ANOPROCESO
	           AND A.PERIODO_MAT = @PERIODOPROCESO
	           AND A.ANO = A.ANO_MAT
	           AND A.PERIODO = A.PERIODO_MAT
	           AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           AND MC.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	    UNION 
	    SELECT A.CODSEDE        AS 'SEDE',
	           A.CODCARPR       AS 'CODCARR',
	           MC.COD_DEMRE,
	           MC.NOMBRE        AS 'NOMBRE CARRERA',
	           A.RUT            AS 'RUN',
	           C.DIG            AS 'DV',
	           C.PATERNO,
	           C.MATERNO,
	           C.NOMBRE,
	           C.DIRPROC AS DIRECCION,
	           C.COMUNAPRO AS COMUNA,
	           MC2.CODREGION AS REGION,
	           C.EMAILPOSTULANTE,
	           C.FONOACT        AS 'TELEFONO',
	           C.CELULARPOSTULANTE,
	           PC.LUGARENLISTA AS 'LUGAR EN LISTA',
	           PC.PRIORIDAD AS PREFERENCIA,
	           --ADP.LUGAR AS 'LUGAR ORIGINAL',
	           'SI' AS             MATRICULADO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 348
	                   AND VALOR = 1 THEN 'SI'
	                       ELSE 'NO'
	                       END AS PRUEBA
	                       FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                       BE
	                       WHERE BE.NUM_DOC = A.RUT
	                   AND CODBEN = 348
	               ),
	               'NO'
	           )                AS 'CRAE',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                               ELSE 'NO'
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = PC.CODPOSTUL
	                               AND MP.CODCARR = PC.CODCARR
	                   WHERE  BE.NUM_DOC = PC.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               'NO'
	           )                AS 'LIDER',
	           CASE (
	                    SELECT 1
	                    FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                    WHERE  B.NUM_DOC = PC.CODPOSTUL
	                           AND B.SIGLA = 'UDD'
	                           AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                           AND B.CARRERA = MC.COD_DEMRE
	                )
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END              AS 'BEA',
	           ADP.POND         AS 'PONDERADO CARRERA',
	           CASE COALESCE(PC.ANOPSU, 0)
	                WHEN 0 THEN 0
	                ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', ADP.CODCLI, PC.ANOPSU)
	           END              AS 'PROMEDIO PSU',
	           0                AS 'POST_EFECT_CARR',
	           0                AS 'POST_EFECT_SEDE',
	           0                AS 'POST_EFECT_UDD',
	           @ANOPROCESO      AS ANO,
	           @PERIODOPROCESO  AS PERIODO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN VALOR
	                               ELSE 0
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = PC.CODPOSTUL
	                               AND MP.CODCARR = PC.CODCARR
	                   WHERE  BE.NUM_DOC = PC.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               0
	           )                AS 'VALOR_LIDER',
	           'PRESELEC_CAE_INGRESA' = ISNULL(
	               (
	                   SELECT DISTINCT('SI')
	                   FROM   MT_CRAE_CARGATMP 
	                          MCC
	                   WHERE  MCC.RUT = PC.CODPOSTUL
	                          AND MCC.TIPO = 'N'
	               ),
	               'NO'
	           ),
	           MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 'BECAS',
	           MC3.CODCOL            AS RBD,
	           MC3.NOMBRE            AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS 
	           DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	           MP.PAAVERBAL,
	           MP.PAAMATEMAT,
	           MP.PAAHISGEO,
	           MP.PCEBIO,
	           MP.PTJE_RANKING,
	           MP.NOTAEM AS PONDEM,
	           CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT CONVERT(VARCHAR(10), MAX(MM.FECHA_REGISTRO), 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       	AND MM.REMATRICULA IS NULL
                                --ORDER BY
                                --       MM.FECHA_REGISTRO ASC
                            )
                  END        AS FEC_MAT,
	           TIPO_MATRICULA = (
	               SELECT A.TIPO_MATRICULA
	               FROM   MATRICULA.MT_ALUMNO A
	               WHERE  A.RUT = ADP.CODCLI
	                      AND A.CODCARPR = ADP.CODCARR
	                      AND A.ANO_MAT = @ANOPROCESO
	                      AND A.PERIODO_MAT = @PERIODOPROCESO
	                      AND A.ANO = @ANOPROCESO
	                      AND A.PERIODO = @PERIODOPROCESO
	           ),
	           ADP.NACIONALIDAD
	    FROM   MT_ALUMNO A
	           INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA MC
	                ON  MC.CODCARR = A.CODCARPR
	           INNER JOIN MT_CLIENT C
	                ON  C.CODCLI = A.RUT
	           INNER JOIN ADM_DATOS_POSTULANTES ADP
	                ON  ADP.CODCLI = A.RUT
	                AND ADP.CODCARR = A.CODCARPR
	                AND (LTRIM(RTRIM(A.COD_VIA)) = '30')
	                    --AND (LTRIM(RTRIM(A.COD_VIA)) = '30' OR ADP.TIENE_BEA = 1)
	                AND ADP.ESTADO = 'P'
	           INNER JOIN MT_POSCAR PC
	                ON  ADP.CODCLI = PC.CODPOSTUL
	                AND ADP.CODCARR = PC.CODCARR
	                AND PC.ANO = @ANOPROCESO
	                AND PC.PERIODO = @PERIODOPROCESO
	                LEFT JOIN MT_PAA AS mp 
	                ON MP.CODCLI = A.RUT 
	                AND MP.ANO = PC.ANOPSU
	                LEFT JOIN MT_COMUNA mc2
	                ON  MC2.CODCOM = C.COMUNAPRO
	                LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = C.COLEGIO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	           --     ON  AI.NUM_DOC = A.RUT
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	           --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	           --     AND UE.UED_CODIGO = AI.UED_CODIGO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	           --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	           --     AND UET.UED_CODIGO = UE.UED_CODIGO
	    WHERE  (A.CODSEDE = @CODSEDE OR @CODSEDE IS NULL)
	           AND (A.CODCARPR = @CODCARR OR @CODCARR IS NULL)
	           AND A.ANO = @ANOPROCESO
	           AND A.PERIODO = @PERIODOPROCESO
	           AND A.ANO_MAT = A.ANO
	           AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           AND MC.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	END
	--/////-----------------------------------------------------------------------------------------------------------------------------------/////--
	IF @NOMINA = 8 --REPOSTULACION
	BEGIN
	    SELECT C.SEDE,
	           C.CODCARR,
	           AMC.COD_DEMRE,
	           C.NOMBRE_C       AS 'NOMBRE CARRERA',
	           A.RUT            AS 'RUN',
	           CC.DIG           AS 'DV',
	           CC.PATERNO,
	           CC.MATERNO,
	           CC.NOMBRE,
	           CC.DIRPROC       AS DIRECCION,
	           CC.COMUNA,
	           MC2.CODREGION    AS REGION,
	           CC.EMAILPOSTULANTE,
	           CC.FONOPROC      AS 'TELEFONO',
	           CC.CELULARPOSTULANTE,
	           COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR EN LISTA',
	           COALESCE(P.PRIORIDAD,0) AS PREFERENCIA, 
	           --PREFERENCIA = ISNULL(
	           --    (
	           --        SELECT ADP.PREFERENCIA
	           --        FROM   ADM_DATOS_POSTULANTES ADP
	           --        WHERE  ADP.CODCLI = A.RUT
	           --               AND ADP.CODCARR = A.CODCARPR
	           --    ),
	           --    0
	           --),
	           --COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR ORIGINAL',
	           'SI' AS 'MATRICULADO',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 348
	                   AND VALOR = 1 THEN 'SI'
	                       ELSE 'NO'
	                       END AS PRUEBA
	                       FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                       BE
	                       WHERE BE.NUM_DOC = A.RUT
	                   AND CODBEN = 348
	               ),
	               'NO'
	           )                AS 'CRAE',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                               ELSE 'NO'
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               'NO'
	           )                AS 'LIDER',
	           CASE (
	                    SELECT 1
	                    FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                    WHERE  B.NUM_DOC = P.CODPOSTUL
	                           AND B.SIGLA = 'UDD'
	                           AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                           AND B.CARRERA = AMC.COD_DEMRE
	                )
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END              AS 'BEA',
	           P.POND           AS 'PONDERADO CARRERA',
	           CASE COALESCE(P.ANOPSU, 0)
	                WHEN 0 THEN 0
	                ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', A.RUT, P.ANOPSU)
	           END              AS 'PROMEDIO PSU',
	           'POST_EFECT_CARR' = ISNULL(
	               (
	                   SELECT COUNT(ADP.CODCLI)
	                   FROM   ADM_DATOS_POSTULANTES ADP
	                   WHERE  ADP.ESTADO = 'A'
	                          AND ADP.CODCARR = A.CODCARPR
	               ),
	               0
	           ),
	           'POST_EFECT_SEDE' = ISNULL(
	               (
	                   SELECT COUNT(ADP.CODCLI)
	                   FROM   ADM_DATOS_POSTULANTES ADP
	                          INNER JOIN MT_CARRER MC
	                               ON  MC.CODCARR = ADP.CODCARR
	                               AND MC.SEDE = A.CODSEDE
	                   WHERE  ADP.ESTADO = 'A'
	               ),
	               0
	           ),
	           'POST_EFECT_UDD' = ISNULL(
	               (
	                   SELECT COUNT(ADP.CODCLI)
	                   FROM   ADM_DATOS_POSTULANTES ADP
	                   WHERE  ADP.ESTADO = 'A'
	               ),
	               0
	           ),
	           @ANOPROCESO      AS ANO,
	           @PERIODOPROCESO  AS PERIODO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN VALOR
	                               ELSE 0
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               0
	           )                AS 'VALOR_LIDER',
	           'PRESELEC_CAE_INGRESA' = ISNULL(
	               (
	                   SELECT DISTINCT('SI')
	                   FROM   MT_CRAE_CARGATMP 
	                          MCC
	                   WHERE  MCC.RUT = P.CODPOSTUL
	                          AND MCC.TIPO = 'N'
	               ),
	               'NO'
	           ),
	           MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 'BECAS',
	           MC3.CODCOL            AS RBD,
	           MC3.NOMBRE            AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS 
	           DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	           MP.PAAVERBAL,
	           MP.PAAMATEMAT,
	           MP.PAAHISGEO,
	           MP.PCEBIO,
	           MP.PTJE_RANKING,
	           MP.NOTAEM        AS PONDEM,
	           CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT TOP 1 CONVERT(VARCHAR(10), MM.FECHA_REGISTRO, 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       	AND MM.REMATRICULA IS NULL
                                ORDER BY
                                       MM.FECHA_REGISTRO DESC
                            )
                  END        AS FEC_MAT,
	           A.TIPO_MATRICULA,
	           CC.NACIONALIDAD
	    FROM   MATRICULA.MT_ALUMNO A
	           INNER JOIN MATRICULA.MT_POSCAR P
	                ON  A.RUT = P.CODPOSTUL
	                AND A.CODCARPR = P.CODCARR
	                AND P.ANO = @ANOPROCESO
	                AND P.PERIODO = @PERIODOPROCESO
	           INNER JOIN MATRICULA.MT_CARRER C
	                ON  A.CODCARPR = C.CODCARR
	                AND (C.CODCARR = @CODCARR OR @CODCARR IS NULL)
	                AND (C.SEDE = @CODSEDE OR @CODSEDE IS NULL)
	           INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA AMC
	                ON  AMC.CODCARR = C.CODCARR
	           INNER JOIN MATRICULA.MT_CLIENT CC
	                ON  CC.CODCLI = A.RUT
	           LEFT JOIN MT_COMUNA mc2
	                ON  MC2.CODCOM = CC.COMUNAPRO
	           LEFT JOIN MT_PAA MP
	                ON  MP.CODCLI = P.CODPOSTUL --.RUT
	                AND MP.ANO = P.ANOPSU
	           LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = CC.COLEGIO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	           --     ON  AI.NUM_DOC = A.RUT
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	           --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	           --     AND UE.UED_CODIGO = AI.UED_CODIGO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	           --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	           --     AND UET.UED_CODIGO = UE.UED_CODIGO
	    WHERE  A.ANO = @ANOPROCESO
	           AND A.ANO_MAT = @ANOPROCESO
	           AND A.PERIODO_MAT = @PERIODOPROCESO
	           AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           AND A.COD_VIA  IN (29, 9)
	           AND C.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	    ORDER BY
	           P.LUGARENLISTA
	END
	--/////-----------------------------------------------------------------------------------------------------------------------------------/////--
	IF @NOMINA = 9 --MATRICULA EN PROCESO
	BEGIN
	    SELECT *
	    FROM   (
	               SELECT CASE MC.CODSEDE
	                           WHEN 1 THEN 'CONCEPCION'
	                           ELSE 'SANTIAGO'
	                      END            AS 'SEDE',
	                      X.CODCARR      AS 'CODCARR',
	                      MC.COD_DEMRE,
	                      MC.NOMBRE      AS 'NOMBRE CARRERA',
	                      C.CODCLI       AS 'RUN',
	                      C.DIG          AS 'DV',
	                      C.PATERNO,
	                      C.MATERNO,
	                      C.NOMBRE,
	                      C.DIRPROC AS DIRECCION,
	                      C.COMUNAPRO AS COMUNA,
	                      AI.REGION,
	                      C.EMAILPOSTULANTE,
	                      C.FONOACT      AS 'TELEFONO',
	                      C.CELULARPOSTULANTE,
	                      ADP.LUGAR      AS 'LUGAR EN LISTA',
	                      PREFERENCIA = ISNULL(
	                          (
	                              SELECT TOP 1 ADP.PREFERENCIA
	                              FROM   ADM_DATOS_POSTULANTES ADP
	                              WHERE  ADP.CODCLI = X.RUT_ALUMNO
	                                     AND ADP.CODCARR = X.CODCARR
	                          ),
	                          0
	                      ),
	                      --ADP.LUGAR AS 'LUGAR ORIGINAL', 
	                      'NO' AS           MATRICULADO,
	                      COALESCE(
	                          (
	                              SELECT CASE 
	                                          WHEN CODBEN = 348
	                              AND VALOR = 1 THEN 'SI' 
	                                  ELSE 'NO' 
	                                  END AS PRUEBA 
	                                  FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                                  BE 
	                                  WHERE BE.NUM_DOC = X.RUT_ALUMNO
	                              AND CODBEN = 348
	                          ),
	                          'NO'
	                      )              AS 'CRAE',
	                      COALESCE(
	                          (
	                              SELECT CASE 
	                                          WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                                          ELSE 'NO'
	                                     END
	                              FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                                     BE
	                                     INNER JOIN MT_POSCAR MP
	                                          ON  MP.CODPOSTUL = PC.CODPOSTUL
	                                          AND MP.CODCARR = PC.CODCARR
	                              WHERE  BE.NUM_DOC = PC.CODPOSTUL
	                                     AND BE.CODBEN = 456 /*409*/
	                                     AND MP.ESTADO = 'A'
	                                     AND MP.ANO = @ANOPROCESO
	                                     AND MP.PERIODO = @PERIODOPROCESO
	                          ),
	                          'NO'
	                      )              AS 'LIDER',
	                      CASE (
	                               SELECT 1
	                               FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA 
	                                      B
	                               WHERE  B.NUM_DOC = PC.CODPOSTUL
	                                      AND B.SIGLA = 'UDD'
	                                      AND B.SITUACION = 
	                                          'EN LISTA DE SELECCIONADOS'
	                                      AND B.CARRERA = MC.COD_DEMRE
	                           )
	                           WHEN 1 THEN 'SI'
	                           ELSE 'NO'
	                      END            AS 'BEA',
	                      ADP.POND       AS 'PONDERADO CARRERA',
	                      CASE COALESCE(PC.ANOPSU, 0)
	                           WHEN 0 THEN 0
	                           ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', ADP.CODCLI, PC.ANOPSU)
	                      END            AS 'PROMEDIO PSU',
	                      0              AS 'POST_EFECT_CARR',
	                      0              AS 'POST_EFECT_SEDE',
	                      0              AS 'POST_EFECT_UDD',
	                      @ANOPROCESO    AS ANO,
	                      @PERIODOPROCESO AS PERIODO,
	                      COALESCE(
	                          (
	                              SELECT CASE 
	                                          WHEN CODBEN = 456 /*409*/ THEN VALOR
	                                          ELSE 0
	                                     END
	                              FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                                     BE
	                                     INNER JOIN MT_POSCAR MP
	                                          ON  MP.CODPOSTUL = PC.CODPOSTUL
	                                          AND MP.CODCARR = PC.CODCARR
	                              WHERE  BE.NUM_DOC = PC.CODPOSTUL
	                                     AND BE.CODBEN = 456 /*409*/
	                                     AND MP.ESTADO = 'A'
	                                     AND MP.ANO = @ANOPROCESO
	                                     AND MP.PERIODO = @PERIODOPROCESO
	                          ),
	                          0
	                      )              AS 'VALOR_LIDER',
	                      'PRESELEC_CAE_INGRESA' = ISNULL(
	                          (
	                              SELECT DISTINCT('SI')
	                              FROM   MT_CRAE_CARGATMP 
	                                     MCC
	                              WHERE  MCC.RUT = PC.CODPOSTUL
	                                     AND MCC.TIPO = 'N'
	                          ),
	                          'NO'
	                      ),
	                      MATRICULA.FN_ADM_TIENEBENEFICIOS(X.RUT_ALUMNO, X.CODCARR) AS 
	                      'BECAS',
	                      UE.CODCOL      AS RBD,
	                      UE.LOC_NOMBRE  AS COLEGIO,
	                      MATRICULA.FN_DEPENDENCIACOLEGIO(UE.CODCOL) AS 
	                      DEPENDENCIA_COLEGIO,
	                      CASE COALESCE(UET.[TARGET], 0)
	                           WHEN 1 THEN 'SI'
	                           ELSE 'NO'
	                      END            AS [TARGET],
	                      MP.PAAVERBAL,
	                      MP.PAAMATEMAT,
	                      MP.PAAHISGEO,
	                      MP.PCEBIO,
	                      MP.PTJE_RANKING,
	                      MP.NOTAEM AS PONDEM,
	                      '' AS             FEC_MAT,
	                      '' AS             TIPO_MATRICULA,
	                      C.NACIONALIDAD
	               FROM   (
	                          --MODIFICACION PARA MATRICULA EN LINEA			 
	                          SELECT mpa.RUT_ALUMNO,
	                                 mpa.CODCARR,
	                                 CASE 
	                                      WHEN (
	                                               SELECT ESTACAD
	                                               FROM   MATRICULA.MT_ALUMNO 
	                                                      MA_ALUM
	                                               WHERE  MA_ALUM.RUT = MPA.RUT_ALUMNO
	                                                      AND MA_ALUM.ANO_MAT = 
	                                                          @ANOPROCESO
	                                                      AND MA_ALUM.PERIODO_MAT = 
	                                                          @PERIODOPROCESO
	                                                      AND (MA_ALUM.CODCARPR = @CODCARR OR @CODCARR IS NULL)
	                                           ) IN ('VIGENTE', 'SUSPENDIDO') THEN 
	                                           'MATRICULADO'
	                                      ELSE 'EN PROCESO'
	                                 END AS ESTADO_MATRICULA
	                          FROM   MATRICULA.ML_PROCESO_ALUMNO mpa
	                          WHERE  MPA.ANNO = @ANOPROCESO
	                                 AND MPA.PERIODO = @PERIODOPROCESO
	                                 AND (MPA.CODCARR = @CODCARR OR @CODCARR IS NULL)
	                                 AND MPA.TIPO = 'Nuevo'
	                                 AND mpa.RUT_ALUMNO NOT IN (SELECT a.RUT
	                                                            FROM   MATRICULA.MT_ALUMNO 
	                                                                   a
	                                                            WHERE  a.ANO_MAT = 
	                                                                   @ANOPROCESO
	                                                                   AND a.PERIODO_MAT = 
	                                                                       @PERIODOPROCESO
	                                                                   AND a.ESTACAD 
	                                                                       IN ('VIGENTE', 'SUSPENDIDO')
	                                                                   AND A.CODCARPR = 
	                                                                       MPA.CODCARR)
	                      )              AS X
	                      INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA MC
	                           ON  MC.CODCARR = x.CODCARR
	                      INNER JOIN MT_CLIENT C
	                           ON  C.CODCLI = CONVERT(VARCHAR(30), x.RUT_ALUMNO)
	                      LEFT JOIN ADM_DATOS_POSTULANTES ADP
	                           ON  ADP.CODCLI = x.RUT_ALUMNO
	                      LEFT JOIN MT_POSCAR PC
	                           ON  ADP.CODCLI = PC.CODPOSTUL
	                           AND ADP.CODCARR = PC.CODCARR
	                           AND PC.ANO = @ANOPROCESO
	                           AND PC.PERIODO = @PERIODOPROCESO
	                      LEFT JOIN MT_PAA AS MP 
	                      ON MP.CODCLI = X.RUT_ALUMNO 
	                      AND PC.ANOPSU = MP.ANO
	                      LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	                           ON  AI.NUM_DOC = x.RUT_ALUMNO
	                      LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	                           ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	                           AND UE.UED_CODIGO = AI.UED_CODIGO
	                      LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET 
	                           UET
	                           ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	                           AND UET.UED_CODIGO = UE.UED_CODIGO
	               WHERE  X.ESTADO_MATRICULA = 'EN PROCESO'
	                      AND (x.CODCARR = @CODCARR OR @CODCARR IS NULL)
	                      AND MC.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	           ) AS PROC_PSU
	    WHERE  PROC_PSU.SEDE = @CODSEDE
	           OR  @CODSEDE IS NULL
	END
	--/////-----------------------------------------------------------------------------------------------------------------------------------/////--
	IF @NOMINA = 10
	BEGIN
	    SELECT C.SEDE,
	           C.CODCARR,
	           AMC.COD_DEMRE,
	           C.NOMBRE_C       AS 'NOMBRE CARRERA',
	           A.RUT            AS 'RUN',
	           CC.DIG           AS 'DV',
	           CC.PATERNO,
	           CC.MATERNO,
	           CC.NOMBRE,
	           CC.DIRPROC       AS DIRECCION,
	           CC.COMUNA,
	           MC2.CODREGION    AS REGION,
	           CC.EMAILPOSTULANTE,
	           CC.FONOPROC      AS 'TELEFONO',
	           CC.CELULARPOSTULANTE,
	           COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR EN LISTA',
	           COALESCE(P.PRIORIDAD,0) AS PREFERENCIA,
	           --PREFERENCIA = ISNULL(
	           --    (
	           --        SELECT ADP.PREFERENCIA
	           --        FROM   ADM_DATOS_POSTULANTES ADP
	           --        WHERE  ADP.CODCLI = A.RUT
	           --               AND ADP.CODCARR = A.CODCARPR
	           --    ),
	           --    0
	           --),
	           --COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR ORIGINAL',
	           'SI' AS 'MATRICULADO',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 348
	                   AND VALOR = 1 THEN 'SI'
	                       ELSE 'NO'
	                       END AS PRUEBA
	                       FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                       BE
	                       WHERE BE.NUM_DOC = A.RUT
	                   AND CODBEN = 348
	               ),
	               'NO'
	           )                AS 'CRAE',
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                               ELSE 'NO'
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               'NO'
	           )                AS 'LIDER',
	           CASE (
	                    SELECT 1
	                    FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                    WHERE  B.NUM_DOC = P.CODPOSTUL
	                           AND B.SIGLA = 'UDD'
	                           AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                           AND B.CARRERA = AMC.COD_DEMRE
	                )
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END              AS 'BEA',
	           P.POND           AS 'PONDERADO CARRERA',
	           CASE COALESCE(P.ANOPSU, 0)
	                WHEN 0 THEN 0
	                ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', A.RUT, P.ANOPSU)
	           END              AS 'PROMEDIO PSU',
	           'POST_EFECT_CARR' = ISNULL(
	               (
	                   SELECT COUNT(ADP.CODCLI)
	                   FROM   ADM_DATOS_POSTULANTES ADP
	                   WHERE  ADP.ESTADO = 'A'
	                          AND ADP.CODCARR = A.CODCARPR
	               ),
	               0
	           ),
	           'POST_EFECT_SEDE' = ISNULL(
	               (
	                   SELECT COUNT(ADP.CODCLI)
	                   FROM   ADM_DATOS_POSTULANTES ADP
	                          INNER JOIN MT_CARRER MC
	                               ON  MC.CODCARR = ADP.CODCARR
	                               AND MC.SEDE = A.CODSEDE
	                   WHERE  ADP.ESTADO = 'A'
	               ),
	               0
	           ),
	           'POST_EFECT_UDD' = ISNULL(
	               (
	                   SELECT COUNT(ADP.CODCLI)
	                   FROM   ADM_DATOS_POSTULANTES ADP
	                   WHERE  ADP.ESTADO = 'A'
	               ),
	               0
	           ),
	           @ANOPROCESO      AS ANO,
	           @PERIODOPROCESO  AS PERIODO,
	           COALESCE(
	               (
	                   SELECT CASE 
	                               WHEN CODBEN = 456 /*409*/ THEN VALOR
	                               ELSE 0
	                          END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = P.CODPOSTUL
	                               AND MP.CODCARR = P.CODCARR
	                   WHERE  BE.NUM_DOC = P.CODPOSTUL
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               0
	           )                AS 'VALOR_LIDER',
	           'PRESELEC_CAE_INGRESA' = ISNULL(
	               (
	                   SELECT DISTINCT('SI')
	                   FROM   MT_CRAE_CARGATMP 
	                          MCC
	                   WHERE  MCC.RUT = P.CODPOSTUL
	                          AND MCC.TIPO = 'N'
	               ),
	               'NO'
	           ),
	           MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 'BECAS',
	           MC3.CODCOL            AS RBD,
	           MC3.NOMBRE            AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS 
	           DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	           MP.PAAVERBAL,
	           MP.PAAMATEMAT,
	           MP.PAAHISGEO,
	           MP.PCEBIO,
	           MP.PTJE_RANKING,
	           MP.NOTAEM        AS PONDEM,
	           CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT TOP 1 CONVERT(VARCHAR(10), MM.FECHA_REGISTRO, 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       	AND MM.REMATRICULA IS NULL
                                ORDER BY
                                       MM.FECHA_REGISTRO DESC
                            )
                  END        AS FEC_MAT,
	           A.TIPO_MATRICULA,
	           CC.NACIONALIDAD
	    FROM   MATRICULA.MT_ALUMNO A
	           INNER JOIN MATRICULA.MT_POSCAR P
	                ON  A.RUT = P.CODPOSTUL
	                AND A.CODCARPR = P.CODCARR
	                AND P.ANO = @ANOPROCESO
	                AND P.PERIODO = @PERIODOPROCESO
	           INNER JOIN MATRICULA.MT_CARRER C
	                ON  A.CODCARPR = C.CODCARR
	                AND (C.CODCARR = @CODCARR OR @CODCARR IS NULL)
	                AND (C.SEDE = @CODSEDE OR @CODSEDE IS NULL)
	           INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA AMC
	                ON  AMC.CODCARR = C.CODCARR
	           INNER JOIN MATRICULA.MT_CLIENT CC
	                ON  CC.CODCLI = A.RUT
	           INNER JOIN MT_COMUNA mc2
	                ON  MC2.CODCOM = CC.COMUNAPRO
	           INNER JOIN MT_PAA MP
	                ON  MP.CODCLI = P.CODPOSTUL --.RUT
	                AND MP.ANO = P.ANOPSU
	           LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = CC.COLEGIO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	           --     ON  AI.NUM_DOC = A.RUT
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	           --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	           --     AND UE.UED_CODIGO = AI.UED_CODIGO
	           --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	           --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	           --     AND UET.UED_CODIGO = UE.UED_CODIGO
	    WHERE  A.ANO = @ANOPROCESO
	           AND A.ANO_MAT = @ANOPROCESO
	           AND A.PERIODO_MAT = @PERIODOPROCESO
	           AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	           AND A.COD_VIA  IN (37)
	           AND C.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	    ORDER BY
	           P.LUGARENLISTA
	END
	--/////-----------------------------------------------------------------------------------------------------------------------------------/////--
	IF @NOMINA = 11
	BEGIN
	    IF UPPER(@CODSEDE) <> 'TODAS'
	    BEGIN
	        SELECT C.SEDE,
	               C.CODCARR,
	               AMC.COD_DEMRE,
	               C.NOMBRE_C       AS 'NOMBRE CARRERA',
	               A.RUT            AS 'RUN',
	               CC.DIG           AS 'DV',
	               CC.PATERNO,
	               CC.MATERNO,
	               CC.NOMBRE,
	               CC.DIRPROC       AS DIRECCION,
	               CC.COMUNA,
	               MC2.CODREGION    AS REGION,
	               CC.EMAILPOSTULANTE,
	               CC.FONOPROC      AS 'TELEFONO',
	               CC.CELULARPOSTULANTE,
	               COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR EN LISTA',
	               COALESCE(P.PRIORIDAD,0) AS PREFERENCIA,
	               --PREFERENCIA = ISNULL(
	               --    (
	               --        SELECT ADP.PREFERENCIA
	               --        FROM   ADM_DATOS_POSTULANTES ADP
	               --        WHERE  ADP.CODCLI = A.RUT
	               --               AND ADP.CODCARR = A.CODCARPR
	               --    ),
	               --    0
	               --),
	               --COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR ORIGINAL',
	               'SI' AS 'MATRICULADO',
	               COALESCE(
	                   (
	                       SELECT CASE 
	                                   WHEN CODBEN = 348
	                       AND VALOR = 1 THEN 'SI'
	                           ELSE 'NO'
	                           END AS PRUEBA
	                           FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                           BE
	                           WHERE BE.NUM_DOC = A.RUT
	                       AND CODBEN = 348
	                   ),
	                   'NO'
	               )                AS 'CRAE',
	               COALESCE(
	                   (
	                       SELECT CASE 
	                                   WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                                   ELSE 'NO'
	                              END
	                       FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                              BE
	                              INNER JOIN MT_POSCAR MP
	                                   ON  MP.CODPOSTUL = P.CODPOSTUL
	                                   AND MP.CODCARR = P.CODCARR
	                       WHERE  BE.NUM_DOC = P.CODPOSTUL
	                              AND BE.CODBEN = 456 /*409*/
	                              AND MP.ESTADO = 'A'
	                              AND MP.ANO = @ANOPROCESO
	                              AND MP.PERIODO = @PERIODOPROCESO
	                   ),
	                   'NO'
	               )                AS 'LIDER',
	               CASE (
	                        SELECT 1
	                        FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                        WHERE  B.NUM_DOC = P.CODPOSTUL
	                               AND B.SIGLA = 'UDD'
	                               AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                               AND B.CARRERA = AMC.COD_DEMRE
	                    )
	                    WHEN 1 THEN 'SI'
	                    ELSE 'NO'
	               END              AS 'BEA',
	               P.POND           AS 'PONDERADO CARRERA',
	               CASE COALESCE(P.ANOPSU, 0)
	                    WHEN 0 THEN 0
	                    ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', A.RUT, P.ANOPSU)
	               END              AS 'PROMEDIO PSU',
	               'POST_EFECT_CARR' = ISNULL(
	                   (
	                       SELECT COUNT(ADP.CODCLI)
	                       FROM   ADM_DATOS_POSTULANTES ADP
	                       WHERE  ADP.ESTADO = 'A'
	                              AND ADP.CODCARR = A.CODCARPR
	                   ),
	                   0
	               ),
	               'POST_EFECT_SEDE' = ISNULL(
	                   (
	                       SELECT COUNT(ADP.CODCLI)
	                       FROM   ADM_DATOS_POSTULANTES ADP
	                              INNER JOIN MT_CARRER MC
	                                   ON  MC.CODCARR = ADP.CODCARR
	                                   AND MC.SEDE = A.CODSEDE
	                       WHERE  ADP.ESTADO = 'A'
	                   ),
	                   0
	               ),
	               'POST_EFECT_UDD' = ISNULL(
	                   (
	                       SELECT COUNT(ADP.CODCLI)
	                       FROM   ADM_DATOS_POSTULANTES ADP
	                       WHERE  ADP.ESTADO = 'A'
	                   ),
	                   0
	               ),
	               @ANOPROCESO      AS ANO,
	               @PERIODOPROCESO  AS PERIODO,
	               COALESCE(
	                   (
	                       SELECT CASE 
	                                   WHEN CODBEN = 456 /*409*/ THEN VALOR
	                                   ELSE 0
	                              END
	                       FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                              BE
	                              INNER JOIN MT_POSCAR MP
	                                   ON  MP.CODPOSTUL = P.CODPOSTUL
	                                   AND MP.CODCARR = P.CODCARR
	                       WHERE  BE.NUM_DOC = P.CODPOSTUL
	                              AND BE.CODBEN = 456 /*409*/
	                              AND MP.ESTADO = 'A'
	                              AND MP.ANO = @ANOPROCESO
	                              AND MP.PERIODO = @PERIODOPROCESO
	                   ),
	                   0
	               )                AS 'VALOR_LIDER',
	               'PRESELEC_CAE_INGRESA' = ISNULL(
	                   (
	                       SELECT DISTINCT('SI')
	                       FROM   MT_CRAE_CARGATMP 
	                              MCC
	                       WHERE  MCC.RUT = P.CODPOSTUL
	                              AND MCC.TIPO = 'N'
	                   ),
	                   'NO'
	               ),
	               MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 
	               'BECAS',
	               MC3.CODCOL            AS RBD,
	           MC3.NOMBRE            AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS 
	           DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	               MP.PAAVERBAL,
	               MP.PAAMATEMAT,
	               MP.PAAHISGEO,
	               MP.PCEBIO,
	               MP.PTJE_RANKING,
	               MP.NOTAEM        AS PONDEM,
	               CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT TOP 1 CONVERT(VARCHAR(10), MM.FECHA_REGISTRO, 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       	AND MM.REMATRICULA IS NULL
                                ORDER BY
                                       MM.FECHA_REGISTRO DESC
                            )
                  END        AS FEC_MAT,
	               A.TIPO_MATRICULA,
	               CC.NACIONALIDAD
	        FROM   MATRICULA.MT_ALUMNO A
	               INNER JOIN MATRICULA.MT_POSCAR P
	                    ON  A.RUT = P.CODPOSTUL
	                    AND A.CODCARPR = P.CODCARR
	                    AND P.ANO = @ANOPROCESO
	                    AND P.PERIODO = @PERIODOPROCESO
	               INNER JOIN MATRICULA.MT_CARRER C
	                    ON  A.CODCARPR = C.CODCARR
	                    AND (C.CODCARR = @CODCARR OR @CODCARR IS NULL)
	                    AND (C.SEDE = @CODSEDE OR @CODSEDE IS NULL)
	               INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA AMC
	                    ON  AMC.CODCARR = C.CODCARR
	               INNER JOIN MATRICULA.MT_CLIENT CC
	                    ON  CC.CODCLI = A.RUT
	               LEFT JOIN MT_COMUNA mc2
	                    ON  MC2.CODCOM = CC.COMUNAPRO
	               LEFT JOIN MT_PAA MP
	                    ON  MP.CODCLI = P.CODPOSTUL --.RUT
	                    AND MP.ANO = P.ANOPSU
	               LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = CC.COLEGIO
	               --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	               --     ON  AI.NUM_DOC = A.RUT
	               --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	               --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	               --     AND UE.UED_CODIGO = AI.UED_CODIGO
	               --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	               --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	               --     AND UET.UED_CODIGO = UE.UED_CODIGO
	        WHERE  A.ANO = @ANOPROCESO
	               AND A.ANO_MAT = @ANOPROCESO
	               AND A.PERIODO_MAT = @PERIODOPROCESO
	               AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	               AND A.COD_VIA  IN (37)
	               AND C.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	        ORDER BY
	               P.LUGARENLISTA
	    END
	    ELSE
	    BEGIN
	        SELECT C.SEDE,
	               C.CODCARR,
	               AMC.COD_DEMRE,
	               C.NOMBRE_C       AS 'NOMBRE CARRERA',
	               A.RUT            AS 'RUN',
	               CC.DIG           AS 'DV',
	               CC.PATERNO,
	               CC.MATERNO,
	               CC.NOMBRE,
	               CC.DIRPROC       AS DIRECCION,
	               CC.COMUNA,
	               MC2.CODREGION    AS REGION,
	               CC.EMAILPOSTULANTE,
	               CC.FONOPROC      AS 'TELEFONO',
	               CC.CELULARPOSTULANTE,
	               COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR EN LISTA',
	               COALESCE(P.PRIORIDAD,0) AS PREFERENCIA,
	               --PREFERENCIA = ISNULL(
	               --    (
	               --        SELECT ADP.PREFERENCIA
	               --        FROM   ADM_DATOS_POSTULANTES ADP
	               --        WHERE  ADP.CODCLI = A.RUT
	               --               AND ADP.CODCARR = A.CODCARPR
	               --    ),
	               --    0
	               --),
	               --COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR ORIGINAL',
	               'SI' AS 'MATRICULADO',
	               COALESCE(
	                   (
	                       SELECT CASE 
	                                   WHEN CODBEN = 348
	                       AND VALOR = 1 THEN 'SI'
	                           ELSE 'NO'
	                           END AS PRUEBA
	                           FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                           BE
	                           WHERE BE.NUM_DOC = A.RUT
	                       AND CODBEN = 348
	                   ),
	                   'NO'
	               )                AS 'CRAE',
	               COALESCE(
	                   (
	                       SELECT CASE 
	                                   WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                                   ELSE 'NO'
	                              END
	                       FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                              BE
	                              INNER JOIN MT_POSCAR MP
	                                   ON  MP.CODPOSTUL = P.CODPOSTUL
	                                   AND MP.CODCARR = P.CODCARR
	                       WHERE  BE.NUM_DOC = P.CODPOSTUL
	                              AND BE.CODBEN = 456 /*409*/
	                              AND MP.ESTADO = 'A'
	                              AND MP.ANO = @ANOPROCESO
	                              AND MP.PERIODO = @PERIODOPROCESO
	                   ),
	                   'NO'
	               )                AS 'LIDER',
	               CASE (
	                        SELECT 1
	                        FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                        WHERE  B.NUM_DOC = P.CODPOSTUL
	                               AND B.SIGLA = 'UDD'
	                               AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                               AND B.CARRERA = AMC.COD_DEMRE
	                    )
	                    WHEN 1 THEN 'SI'
	                    ELSE 'NO'
	               END              AS 'BEA',
	               P.POND           AS 'PONDERADO CARRERA',
	               CASE COALESCE(P.ANOPSU, 0)
	                    WHEN 0 THEN 0
	                    ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', A.RUT, P.ANOPSU)
	               END              AS 'PROMEDIO PSU',
	               'POST_EFECT_CARR' = ISNULL(
	                   (
	                       SELECT COUNT(ADP.CODCLI)
	                       FROM   ADM_DATOS_POSTULANTES ADP
	                       WHERE  ADP.ESTADO = 'A'
	                              AND ADP.CODCARR = A.CODCARPR
	                   ),
	                   0
	               ),
	               'POST_EFECT_SEDE' = ISNULL(
	                   (
	                       SELECT COUNT(ADP.CODCLI)
	                       FROM   ADM_DATOS_POSTULANTES ADP
	                              INNER JOIN MT_CARRER MC
	                                   ON  MC.CODCARR = ADP.CODCARR
	                                   AND MC.SEDE = A.CODSEDE
	                       WHERE  ADP.ESTADO = 'A'
	                   ),
	                   0
	               ),
	               'POST_EFECT_UDD' = ISNULL(
	                   (
	                       SELECT COUNT(ADP.CODCLI)
	                       FROM   ADM_DATOS_POSTULANTES ADP
	                       WHERE  ADP.ESTADO = 'A'
	                   ),
	                   0
	               ),
	               @ANOPROCESO      AS ANO,
	               @PERIODOPROCESO  AS PERIODO,
	               COALESCE(
	                   (
	                       SELECT CASE 
	                                   WHEN CODBEN = 456 /*409*/ THEN VALOR
	                                   ELSE 0
	                              END
	                       FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                              BE
	                              INNER JOIN MT_POSCAR MP
	                                   ON  MP.CODPOSTUL = P.CODPOSTUL
	                                   AND MP.CODCARR = P.CODCARR
	                       WHERE  BE.NUM_DOC = P.CODPOSTUL
	                              AND BE.CODBEN = 456 /*409*/
	                              AND MP.ESTADO = 'A'
	                              AND MP.ANO = @ANOPROCESO
	                              AND MP.PERIODO = @PERIODOPROCESO
	                   ),
	                   0
	               )                AS 'VALOR_LIDER',
	               'PRESELEC_CAE_INGRESA' = ISNULL(
	                   (
	                       SELECT DISTINCT('SI')
	                       FROM   MT_CRAE_CARGATMP 
	                              MCC
	                       WHERE  MCC.RUT = P.CODPOSTUL
	                              AND MCC.TIPO = 'N'
	                   ),
	                   'NO'
	               ),
	               MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 
	               'BECAS',
	               MC3.CODCOL            AS RBD,
	           MC3.NOMBRE            AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS 
	           DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	               MP.PAAVERBAL,
	               MP.PAAMATEMAT,
	               MP.PAAHISGEO,
	               MP.PCEBIO,
	               MP.PTJE_RANKING,
	               MP.NOTAEM        AS PONDEM,
	               CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT TOP 1 CONVERT(VARCHAR(10), MM.FECHA_REGISTRO, 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       	AND MM.REMATRICULA IS NULL
                                ORDER BY
                                       MM.FECHA_REGISTRO DESC
                            )
                  END        AS FEC_MAT,
	               A.TIPO_MATRICULA,
	               CC.NACIONALIDAD
	        FROM   MATRICULA.MT_ALUMNO A
	               INNER JOIN MATRICULA.MT_POSCAR P
	                    ON  A.RUT = P.CODPOSTUL
	                    AND A.CODCARPR = P.CODCARR
	                    AND P.ANO = @ANOPROCESO
	                    AND P.PERIODO = @PERIODOPROCESO
	               INNER JOIN MATRICULA.MT_CARRER C
	                    ON  A.CODCARPR = C.CODCARR
	                    AND (C.CODCARR = @CODCARR OR @CODCARR IS NULL)
	                    AND (C.SEDE = @CODSEDE OR @CODSEDE IS NULL)
	               INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA AMC
	                    ON  AMC.CODCARR = C.CODCARR
	               INNER JOIN MATRICULA.MT_CLIENT CC
	                    ON  CC.CODCLI = A.RUT
	               INNER JOIN MT_COMUNA mc2
	                    ON  MC2.CODCOM = CC.COMUNAPRO
	               INNER JOIN MT_PAA MP
	                    ON  MP.CODCLI = P.CODPOSTUL --.RUT
	                    AND MP.ANO = P.ANOPSU
				    LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = CC.COLEGIO		                    
	               --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	               --     ON  AI.NUM_DOC = A.RUT
	               --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	               --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	               --     AND UE.UED_CODIGO = AI.UED_CODIGO
	               --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	               --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	               --     AND UET.UED_CODIGO = UE.UED_CODIGO
	        WHERE  A.ANO = @ANOPROCESO
	               AND A.ANO_MAT = @ANOPROCESO
	               AND A.PERIODO_MAT = @PERIODOPROCESO
	               AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	               AND A.COD_VIA  IN (37)
	               AND C.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	        ORDER BY
	               P.LUGARENLISTA
	    END
	END
	--/////-----------------------------------------------------------------------------------------------------------------------------------/////--
	IF @NOMINA = 99 --EN PROCESO: TOTAL
	BEGIN
	    IF UPPER(@CODSEDE) <> 'TODAS'
	    BEGIN
	        SELECT C.SEDE,
	               C.CODCARR,
	               AMC.COD_DEMRE,
	               C.NOMBRE_C       AS 'NOMBRE CARRERA',
	               A.RUT            AS 'RUN',
	               CC.DIG           AS 'DV',
	               CC.PATERNO,
	               CC.MATERNO,
	               CC.NOMBRE,
	               CC.DIRPROC AS DIRECCION,
	               CC.COMUNAPRO AS COMUNA,
	               MC.CODREGION AS REGION,
	               CC.EMAILPOSTULANTE,
	               CC.FONOPROC      AS 'TELEFONO',
	               CC.CELULARPOSTULANTE,
	               COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR EN LISTA',
	               COALESCE(P.PRIORIDAD,0) AS PREFERENCIA,
	               --PREFERENCIA = ISNULL(
	               --    (
	               --        SELECT ADP.PREFERENCIA
	               --        FROM   ADM_DATOS_POSTULANTES ADP
	               --        WHERE  ADP.CODCLI = A.RUT
	               --               AND ADP.CODCARR = A.CODCARPR
	               --    ),
	               --    0
	               --),
	               --COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR ORIGINAL',
	               'SI' AS 'MATRICULADO',
	               COALESCE(
	                   (
	                       SELECT CASE 
	                                   WHEN CODBEN = 348
	                       AND VALOR = 1 THEN 'SI'
	                           ELSE 'NO'
	                           END AS PRUEBA
	                           FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                           BE
	                           WHERE BE.NUM_DOC = A.RUT
	                       AND CODBEN = 348
	                   ),
	                   'NO'
	               )                AS 'CRAE',
	               COALESCE(
	                   (
	                       SELECT CASE 
	                                   WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                                   ELSE 'NO'
	                              END
	                       FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                              BE
	                              INNER JOIN MT_POSCAR MP
	                                   ON  MP.CODPOSTUL = P.CODPOSTUL
	                                   AND MP.CODCARR = P.CODCARR
	                       WHERE  BE.NUM_DOC = P.CODPOSTUL
	                              AND BE.CODBEN = 456 /*409*/
	                              AND MP.ESTADO = 'A'
	                              AND MP.ANO = @ANOPROCESO
	                              AND MP.PERIODO = @PERIODOPROCESO
	                   ),
	                   'NO'
	               )                AS 'LIDER',
	               CASE (
	                        SELECT 1
	                        FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                        WHERE  B.NUM_DOC = P.CODPOSTUL
	                               AND B.SIGLA = 'UDD'
	                               AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                               AND B.CARRERA = AMC.COD_DEMRE
	                    )
	                    WHEN 1 THEN 'SI'
	                    ELSE 'NO'
	               END              AS 'BEA',
	               P.POND           AS 'PONDERADO CARRERA',
	               CASE COALESCE(P.ANOPSU, 0)
	                    WHEN 0 THEN 0
	                    ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', A.RUT, P.ANOPSU)
	               END              AS 'PROMEDIO PSU',
	               'POST_EFECT_CARR' = ISNULL(
	                   (
	                       SELECT COUNT(ADP.CODCLI)
	                       FROM   ADM_DATOS_POSTULANTES ADP
	                       WHERE  ADP.ESTADO = 'A'
	                              AND ADP.CODCARR = A.CODCARPR
	                   ),
	                   0
	               ),
	               'POST_EFECT_SEDE' = ISNULL(
	                   (
	                       SELECT COUNT(ADP.CODCLI)
	                       FROM   ADM_DATOS_POSTULANTES ADP
	                              INNER JOIN MT_CARRER MC
	                                   ON  MC.CODCARR = ADP.CODCARR
	                                   AND MC.SEDE = A.CODSEDE
	                       WHERE  ADP.ESTADO = 'A'
	                   ),
	                   0
	               ),
	               'POST_EFECT_UDD' = ISNULL(
	                   (
	                       SELECT COUNT(ADP.CODCLI)
	                       FROM   ADM_DATOS_POSTULANTES ADP
	                       WHERE  ADP.ESTADO = 'A'
	                   ),
	                   0
	               ),
	               @ANOPROCESO      AS ANO,
	               @PERIODOPROCESO  AS PERIODO,
	               COALESCE(
	                   (
	                       SELECT CASE 
	                                   WHEN CODBEN = 456 /*409*/ THEN VALOR
	                                   ELSE 0
	                              END
	                       FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                              BE
	                              INNER JOIN MT_POSCAR MP
	                                   ON  MP.CODPOSTUL = P.CODPOSTUL
	                                   AND MP.CODCARR = P.CODCARR
	                       WHERE  BE.NUM_DOC = P.CODPOSTUL
	                              AND BE.CODBEN = 456 /*409*/
	                              AND MP.ESTADO = 'A'
	                              AND MP.ANO = @ANOPROCESO
	                              AND MP.PERIODO = @PERIODOPROCESO
	                   ),
	                   0
	               )                AS 'VALOR_LIDER',
	               'PRESELEC_CAE_INGRESA' = ISNULL(
	                   (
	                       SELECT DISTINCT('SI')
	                       FROM   MT_CRAE_CARGATMP 
	                              MCC
	                       WHERE  MCC.RUT = P.CODPOSTUL
	                              AND MCC.TIPO = 'N'
	                   ),
	                   'NO'
	               ),
	               MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 
	               'BECAS',
	               MC3.CODCOL            AS RBD,
	           MC3.NOMBRE            AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS 
	           DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	               MP.PAAVERBAL,
	               MP.PAAMATEMAT,
	               MP.PAAHISGEO,
	               MP.PCEBIO,
	               MP.PTJE_RANKING,
	               MP.NOTAEM AS PONDEM,
	               CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT TOP 1 CONVERT(VARCHAR(10), MM.FECHA_REGISTRO, 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO= A.PERIODO
                                       	AND MM.REMATRICULA IS NULL
                                ORDER BY
                                       MM.FECHA_REGISTRO DESC
                            )
                  END        AS FEC_MAT,
	               TIPO_MATRICULA = (
	                   SELECT A.TIPO_MATRICULA
	                   FROM   MATRICULA.MT_ALUMNO A
	                   WHERE  A.RUT = ADP.CODCLI
	                          AND A.CODCARPR = ADP.CODCARR
	                          AND A.ANO_MAT = @ANOPROCESO
	                          AND A.PERIODO_MAT = @PERIODOPROCESO
	                          AND A.ANO = @ANOPROCESO
	                          AND A.PERIODO = @PERIODOPROCESO
	               ),
	               ADP.NACIONALIDAD
	        FROM   MATRICULA.MT_ALUMNO A
	               INNER JOIN MATRICULA.MT_POSCAR P
	                    ON  A.RUT = P.CODPOSTUL
	                    AND A.CODCARPR = P.CODCARR
	                    AND P.ANO = @ANOPROCESO
	                    AND P.PERIODO = @PERIODOPROCESO	                    
	               INNER JOIN MATRICULA.MT_CARRER C
	                    ON  A.CODCARPR = C.CODCARR
	                    AND (C.SEDE = @CODSEDE OR @CODSEDE IS NULL)
	               INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA AMC
	                    ON  AMC.CODCARR = C.CODCARR
	                    AND (
	                            AMC.CODCARR = @CODCARR
	                            OR @CODCARR IS NULL
	                            OR @CODCARR = ''
	                        )
	               INNER JOIN MATRICULA.MT_CLIENT CC
	                    ON  CC.CODCLI = A.RUT
	               LEFT JOIN MT_PAA AS mp 
	               ON MP.CODCLI = A.RUT 
	               AND MP.ANO = P.ANOPSU   
	               LEFT JOIN MT_COMUNA AS mc 
	               ON MC.CODCOM = CC.COMUNAPRO  
	               LEFT JOIN ADM_DATOS_POSTULANTES ADP
	                    ON  ADP.CODCLI = A.RUT
	                    AND ADP.CODCARR = A.CODCARPR
	                LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = CC.COLEGIO
	               --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	               --     ON  AI.NUM_DOC = A.RUT
	               --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	               --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	               --     AND UE.UED_CODIGO = AI.UED_CODIGO
	               --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	               --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	               --     AND UET.UED_CODIGO = UE.UED_CODIGO
	        WHERE  A.ANO = @ANOPROCESO
	               AND A.ANO_MAT = @ANOPROCESO
	               AND A.PERIODO_MAT = @PERIODOPROCESO
	               AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	               AND A.ESTADO_ARANCEL = 'PENDIENTE'
	               AND C.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	        ORDER BY
	               C.SEDE,
	               C.CODCARR,
	               'LUGAR EN LISTA'
	    END
	    ELSE
	    BEGIN
	        SELECT C.SEDE,
	               C.CODCARR,
	               AMC.COD_DEMRE,
	               C.NOMBRE_C       AS 'NOMBRE CARRERA',
	               A.RUT            AS 'RUN',
	               CC.DIG           AS 'DV',
	               CC.PATERNO,
	               CC.MATERNO,
	               CC.NOMBRE,
	               CC.DIRPROC AS DIRECCION,
	               CC.COMUNAPRO AS COMUNA,
	               MC.CODREGION AS REGION,
	               CC.EMAILPOSTULANTE,
	               CC.FONOPROC      AS 'TELEFONO',
	               CC.CELULARPOSTULANTE,
	               COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR EN LISTA',
	               PREFERENCIA = ISNULL(
	                   (
	                       SELECT ADP.PREFERENCIA
	                       FROM   ADM_DATOS_POSTULANTES ADP
	                       WHERE  ADP.CODCLI = A.RUT
	                              AND ADP.CODCARR = A.CODCARPR
	                   ),
	                   0
	               ),
	               --COALESCE(P.LUGARENLISTA, 0) AS 'LUGAR ORIGINAL',
	               'SI' AS 'MATRICULADO',
	               COALESCE(
	                   (
	                       SELECT CASE 
	                                   WHEN CODBEN = 348
	                       AND VALOR = 1 THEN 'SI'
	                           ELSE 'NO'
	                           END AS PRUEBA
	                           FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                           BE
	                           WHERE BE.NUM_DOC = A.RUT
	                       AND CODBEN = 348
	                   ),
	                   'NO'
	               )                AS 'CRAE',
	               COALESCE(
	                   (
	                       SELECT CASE 
	                                   WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                                   ELSE 'NO'
	                              END
	                       FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                              BE
	                              INNER JOIN MT_POSCAR MP
	                                   ON  MP.CODPOSTUL = P.CODPOSTUL
	                                   AND MP.CODCARR = P.CODCARR
	                       WHERE  BE.NUM_DOC = P.CODPOSTUL
	                              AND BE.CODBEN = 456 /*409*/
	                              AND MP.ESTADO = 'A'
	                              AND MP.ANO = @ANOPROCESO
	                              AND MP.PERIODO = @PERIODOPROCESO
	                   ),
	                   'NO'
	               )                AS 'LIDER',
	               CASE (
	                        SELECT 1
	                        FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                        WHERE  B.NUM_DOC = P.CODPOSTUL
	                               AND B.SIGLA = 'UDD'
	                               AND B.SITUACION = 'EN LISTA DE SELECCIONADOS'
	                               AND B.CARRERA = AMC.COD_DEMRE
	                    )
	                    WHEN 1 THEN 'SI'
	                    ELSE 'NO'
	               END              AS 'BEA',
	               P.POND           AS 'PONDERADO CARRERA',
	               CASE COALESCE(P.ANOPSU, 0)
	                    WHEN 0 THEN 0
	                    ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', A.RUT, P.ANOPSU)
	               END              AS 'PROMEDIO PSU',
	               'POST_EFECT_CARR' = ISNULL(
	                   (
	                       SELECT COUNT(ADP.CODCLI)
	                       FROM   ADM_DATOS_POSTULANTES ADP
	                       WHERE  ADP.ESTADO = 'A'
	                              AND ADP.CODCARR = A.CODCARPR
	                   ),
	                   0
	               ),
	               'POST_EFECT_SEDE' = ISNULL(
	                   (
	                       SELECT COUNT(ADP.CODCLI)
	                       FROM   ADM_DATOS_POSTULANTES ADP
	                              INNER JOIN MT_CARRER MC
	                                   ON  MC.CODCARR = ADP.CODCARR
	                                   AND MC.SEDE = A.CODSEDE
	                       WHERE  ADP.ESTADO = 'A'
	                   ),
	                   0
	               ),
	               'POST_EFECT_UDD' = ISNULL(
	                   (
	                       SELECT COUNT(ADP.CODCLI)
	                       FROM   ADM_DATOS_POSTULANTES ADP
	                       WHERE  ADP.ESTADO = 'A'
	                   ),
	                   0
	               ),
	               @ANOPROCESO      AS ANO,
	               @PERIODOPROCESO  AS PERIODO,
	               COALESCE(
	                   (
	                       SELECT CASE 
	                                   WHEN CODBEN = 456 /*409*/ THEN VALOR
	                                   ELSE 0
	                              END
	                       FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                              BE
	                              INNER JOIN MT_POSCAR MP
	                                   ON  MP.CODPOSTUL = P.CODPOSTUL
	                                   AND MP.CODCARR = P.CODCARR
	                       WHERE  BE.NUM_DOC = P.CODPOSTUL
	                              AND BE.CODBEN = 456 /*409*/
	                              AND MP.ESTADO = 'A'
	                              AND MP.ANO = @ANOPROCESO
	                              AND MP.PERIODO = @PERIODOPROCESO
	                   ),
	                   0
	               )                AS 'VALOR_LIDER',
	               'PRESELEC_CAE_INGRESA' = ISNULL(
	                   (
	                       SELECT DISTINCT('SI')
	                       FROM   MT_CRAE_CARGATMP 
	                              MCC
	                       WHERE  MCC.RUT = P.CODPOSTUL
	                              AND MCC.TIPO = 'N'
	                   ),
	                   'NO'
	               ),
	               MATRICULA.FN_ADM_TIENEBENEFICIOS(A.RUT, A.CODCARPR) AS 
	               'BECAS',
	               MC3.CODCOL            AS RBD,
	           MC3.NOMBRE            AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(MC3.CODCOL) AS 
	           DEPENDENCIA_COLEGIO,
	           COALESCE(
	               (
	                   SELECT DISTINCT CASE AUET.[TARGET]
	                                        WHEN 1 THEN 'SI'
	                                        ELSE 'NO'
	                                   END
	                   FROM   DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET AS 
	                          AUET
	                   WHERE  AUET.RBD = MC3.CODCOL
	               ),
	               'NO'
	           )                     AS [TARGET],
	               MP.PAAVERBAL,
	               MP.PAAMATEMAT,
	               MP.PAAHISGEO,
	               MP.PCEBIO,
	               MP.PTJE_RANKING,
	               MP.NOTAEM AS PONDEM,
	              CASE 
                       WHEN NOT EXISTS (
                                SELECT TOP 1 *
                                FROM   MT_MATRICULAS AS mm
                                WHERE  MM.CODCLI = A.CODCLI
                                       AND MM.ANO = A.ANO
                            ) THEN CONVERT(VARCHAR(10), A.FEC_MAT, 103)
                       ELSE (
                                SELECT TOP 1 CONVERT(VARCHAR(10), MM.FECHA_REGISTRO, 103)
                                FROM   MT_MATRICULAS AS mm
                                WHERE  mm.CODCLI = A.CODCLI
                                       AND mm.ANO = A.ANO
                                       AND MM.PERIODO=A.PERIODO
                                       	AND MM.REMATRICULA IS NULL
                                ORDER BY
                                       MM.FECHA_REGISTRO DESC
                            )
                  END        AS FEC_MAT,
	               TIPO_MATRICULA = (
	                   SELECT A.TIPO_MATRICULA
	                   FROM   MATRICULA.MT_ALUMNO A
	                   WHERE  A.RUT = ADP.CODCLI
	                          AND A.CODCARPR = ADP.CODCARR
	                          AND A.ANO_MAT = @ANOPROCESO
	                          AND A.PERIODO_MAT = @PERIODOPROCESO
	                          AND A.ANO = @ANOPROCESO
	                          AND A.PERIODO = @PERIODOPROCESO
	               ),
	               CC.NACIONALIDAD
	        FROM   MATRICULA.MT_ALUMNO A
	               INNER JOIN MATRICULA.MT_POSCAR P
	                    ON  A.RUT = P.CODPOSTUL
	                    AND A.CODCARPR = P.CODCARR
	                    AND P.ANO = @ANOPROCESO
	                    AND P.PERIODO = @PERIODOPROCESO
	               INNER JOIN MATRICULA.MT_CARRER C
	                    ON  A.CODCARPR = C.CODCARR
	               INNER JOIN DB_ADMISION.DBO.ADM_MAE_CARRERA AMC	               
	                    ON  AMC.CODCARR = C.CODCARR
	               LEFT JOIN MT_PAA AS mp 
	               ON MP.CODCLI = A.RUT
	               AND MP.ANO = P.ANOPSU
	               INNER JOIN MATRICULA.MT_CLIENT CC
	                    ON  CC.CODCLI = A.RUT
	               LEFT JOIN MT_COMUNA AS mc 
	               ON MC.CODCOM = CC.COMUNAPRO 
	               LEFT JOIN ADM_DATOS_POSTULANTES ADP
	                    ON  ADP.CODCLI = A.RUT
	                    AND ADP.CODCARR = A.CODCARPR
	               LEFT JOIN MT_COLEGIO  AS mc3
	                ON  MC3.CODCOL = CC.COLEGIO	                    
	               --LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	               --     ON  AI.NUM_DOC = A.RUT
	               --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	               --     ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	               --     AND UE.UED_CODIGO = AI.UED_CODIGO
	               --LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	               --     ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	               --     AND UET.UED_CODIGO = UE.UED_CODIGO
	        WHERE  A.ANO = @ANOPROCESO
	               AND A.ANO_MAT = @ANOPROCESO
	               AND A.PERIODO_MAT = @PERIODOPROCESO
	               AND A.ESTACAD IN ('VIGENTE', 'SUSPENDIDO')
	               AND A.ESTADO_ARANCEL = 'PENDIENTE'
	               AND C.CODCARR IN (SELECT DISTINCT AUAC.CODCARR
	                             FROM   ADM_USUARIO_ASIGNACION_CARRERA
	                                    AUAC
	                             WHERE  AUAC.ID_USUARIO = @USUARIO
	                                    OR  @USUARIO IS NULL)
	        ORDER BY
	               C.SEDE,
	               C.CODCARR,
	               'LUGAR EN LISTA'
	    END
	END
END



