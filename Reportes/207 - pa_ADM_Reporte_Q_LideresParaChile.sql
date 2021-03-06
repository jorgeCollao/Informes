USE [matricula]
GO
/****** Object:  StoredProcedure [matricula].[pa_ADM_Reporte_Q_LideresParaChile]    Script Date: 05-12-2016 11:53:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/************************************************************
 * ROBERTO LARRONDE RYBERTT
 * Fecha: 20-11-2012 12:57:24
 ************************************************************/
 
/***************************************************************************************/
/*
* MODIFICACIONES PROCESO 2015
* FECHA			: 06/08/2014
* AUTOR			: Alexanders Gutierrez Muñoz
* DESCRIPCION	: se agregan nuevos campos requeridos por Miryam Martinez. Se establece el periodo a 1
*					SEDE			: Sede postulación (CONCEPCION/SANTIAGO)
*					MATRICULADO		: alumno esta matricula en UDD (SI/NO)					
*					BEA				: alumno con BEA (SI/NO)
*					CAE				: alumno con CAE (SI/NO)
*					BECA			: alumno con becas UDD (SI/NO)
*					RBD				: identificador de colegio
*					CRM				: alumno contactado por CRM (SI/NO)
*					LIDER			: alumno es lider (SI/NO)
*					TARGET			: colegio target (SI/NO)
*				: NUEVO PARAMETRO
*					@COD_DEMRE		: para indicar carrera para generar nomina, si es 0, genera resumen principal
*									  para generar nomina, solo se requiere CODSEDE,COD_DEMRE de la carrera	
*					@SITUACION		: indica si esta en lista de seleccionado o lista espera, para generar nomina
*					
*					
*	EXEC pa_ADM_Reporte_Q_LideresParaChile NULL,NULL,NULL
*/



ALTER PROCEDURE [matricula].[pa_ADM_Reporte_Q_LideresParaChile](
    @CODSEDE     VARCHAR(30) = NULL,
    @CARRERA     VARCHAR(30) = NULL,
    @USUARIO     VARCHAR(50) = NULL
)
AS
BEGIN
	DECLARE @ANOPROCESO         INT,
	        @PERIODOPROCESO     INT
	
	SELECT @ANOPROCESO = MATRICULA.FN_OBTIENEANOPERIODO('A', 'M'),
	       @PERIODOPROCESO = 1
		

	    SELECT MATRICULADO = COALESCE(
	               (
	                   SELECT 'S'
	                   FROM   MATRICULA.MT_ALUMNO A
	                   WHERE  A.RUT = ADP.CODCLI
	                          AND A.CODCARPR = ADP.CODCARR
	                          AND A.ANO_MAT = @ANOPROCESO
	                          AND A.PERIODO_MAT = @PERIODOPROCESO
	                          AND A.ANO = @ANOPROCESO
	                          AND A.PERIODO = @PERIODOPROCESO
	               ),
	               'N'
	           ),
	           S.NOMBRE            AS SEDE,
	           C.CODCARR,
	           C.COD_DEMRE,
	           C.NOMBRE            AS CARRERA,
	           ADP.PREFERENCIA,
	           ADP.LUGAR,
	           MC.CODCLI,
	           MC.DIG,
	           MC.PATERNO,
	           MC.MATERNO,
	           MC.NOMBRE,
	           SUBSTRING(ADP.DIRECCION, 1, 32) AS DIRECCION,
	           ADP.COMUNA,
	           AI.REGION,
	           COALESCE(ADP.EMAILPOSTULANTE, ' - ') AS 'EMAIL',
	           COALESCE(ADP.TELEFONO, ' - ') AS 'TELEFONO',
	           COALESCE(ADP.CELULARPOSTULANTE, ' - ') AS 'CELULAR',
	           ADP.POND            AS [PUNTAJE PONDERADO],
	           ADP.PAAVERBAL       AS PJE_LENGUAJE,
	           ADP.PAAMATEMAT      AS PTJE_MATEMATICAS,
	           ADP.PAAHISGEO       AS PTJE_HISTORIA,
	           ADP.PCEBIO          AS PJTE_CIENCIAS,
	           ADP.PONDEM,
	           ADP.PTJE_RANKING,
	           CASE COALESCE(P.ANOPSU, 0)
	                WHEN 0 THEN 0
	                ELSE MATRICULA.FN_ADM_GETDATOSPSU('PROMPSU', MC.CODCLI, P.ANOPSU)
	           END                 AS [PROMEDIO_PSU],
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
                                ORDER BY
                                       MM.FECHA_REGISTRO ASC
                            )
                  END     AS [FECHA MATRICULA],
	           --MA.FEC_MAT          AS [FECHA MATRICULA],
	           UE.CODCOL           AS RBD,
	           UE.LOC_NOMBRE       AS COLEGIO,
	           MATRICULA.FN_DEPENDENCIACOLEGIO(ADP.COLEGIO) AS 
	           DEPENDENCIA_COLEGIO,
	           CASE COALESCE(UET.[TARGET], 0)
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END                 AS [TARGET],
	           COALESCE(
	               (
	                   SELECT TOP 1 CASE 
	                                     WHEN BE.CODBEN = 348
	                   AND BE.VALOR = 1 THEN 'SI'
	                       ELSE 'NO'
	                       END
	                       FROM [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES 
	                       BE
	                       INNER JOIN [DB_ADMISION].DBO.ADM_BENEFICIOS_SIMULACION 
	                       BS ON BS.NUM_DOC = BE.NUM_DOC
	                   AND BS.CODBEN = BE.CODBEN
	                       WHERE BE.NUM_DOC = ADP.CODCLI
	                   AND BE.CODBEN = 348
	                   AND BS.CODCARR = ADP.CODCARR
	               ),
	               'NO'
	           )                   AS 'CRAE',
	           ISNULL(
	               (
	                   SELECT TOP 1 CASE 
	                                     WHEN CODBEN = 456 /*409*/ THEN 'SI'
	                                     ELSE 'NO'
	                                END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = ADP.CODCLI
	                               AND MP.CODCARR = ADP.CODCARR
	                   WHERE  BE.NUM_DOC = ADP.CODCLI
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               'NO'
	           )                   AS 'LIDER',
	           CASE (
	                    SELECT TOP 1 1
	                    FROM   DB_ADMISION.DBO.ADM_POSTULACIONES_BEA B
	                    WHERE  B.NUM_DOC = ADP.CODCLI
	                           AND B.SIGLA = 'UDD'
	                           AND B.CARRERA = C.COD_DEMRE
	                           AND ADP.TIENE_BEA = 1
	                )
	                WHEN 1 THEN 'SI'
	                ELSE 'NO'
	           END                 AS 'BEA',
	           COALESCE(
	               (
	                   SELECT TOP 1 CASE 
	                                     WHEN CODBEN = 456 /*409*/ THEN VALOR
	                                     ELSE 0
	                                END
	                   FROM   [DB_ADMISION].DBO.ADM_BENEFICIADOS_ESPECIALES
	                          BE
	                          INNER JOIN MT_POSCAR MP
	                               ON  MP.CODPOSTUL = ADP.CODCLI
	                               AND MP.CODCARR = ADP.CODCARR
	                   WHERE  BE.NUM_DOC = ADP.CODCLI
	                          AND BE.CODBEN = 456 /*409*/
	                          AND MP.ESTADO = 'A'
	                          AND MP.ANO = @ANOPROCESO
	                          AND MP.PERIODO = @PERIODOPROCESO
	               ),
	               0
	           )                   AS 'VALOR_LIDER',
	           MATRICULA.FN_ADM_TIENEBENEFICIOS(ADP.CODCLI, ADP.CODCARR) AS 
	           'BECAS',
	           @ANOPROCESO AS         ANO,
	           @PERIODOPROCESO AS     PERIODO,
	           'PRESELEC_CAE_INGRESA' = ISNULL(
	               (
	                   SELECT DISTINCT('SI')
	                   FROM   MT_CRAE_CARGATMP MCC
	                   WHERE  MCC.RUT = ADP.CODCLI
	                          AND MCC.TIPO = 'N'
	               ),
	               'NO'
	           ),
	           ADP.NACIONALIDAD,
	           MA.TIPO_MATRICULA
	    FROM   DB_ADMISION.DBO.ADM_BENEFICIADOS_ESPECIALES BE
	           INNER JOIN MT_POSCAR P
	                ON  P.CODPOSTUL = CONVERT(VARCHAR(30), BE.NUM_DOC)
	                AND P.ANO = @ANOPROCESO
	                AND P.PERIODO = @PERIODOPROCESO
	           LEFT JOIN MT_ALUMNO MA
	                ON  MA.RUT = CONVERT(VARCHAR(30), BE.NUM_DOC)
	                AND MA.ANO_MAT = @ANOPROCESO
	                AND MA.PERIODO = @PERIODOPROCESO
	                    --AND MA.ESTACAD IN('VIGENTE','SUSPENDIDO')
	                AND MA.RUT = P.CODPOSTUL
	                AND MA.CODCARPR = P.CODCARR
	           LEFT JOIN MT_CLIENT MC
	                ON  MC.CODCLI = CONVERT(VARCHAR(30), BE.NUM_DOC)
	           INNER JOIN  MT_CARRER_CLASIFICACION AS mcc 
					ON MCC.CODCARR=P.CODCARR
					AND(MCC.CODCARR=@CARRERA OR @CARRERA IS NULL) 
					AND MCC.CODTIPO=2 
					AND @ANOPROCESO BETWEEN MCC.ANO_INI AND MCC.ANO_FIN					
	           INNER JOIN [DB_ADMISION].DB_ADMISION.DBO.ADM_MAE_CARRERA C
	                ON  (P.CODCARR = @CARRERA OR @CARRERA IS NULL)
	                AND (CASE C.CODSEDE
							WHEN 1 THEN 'CONCEPCION'
							WHEN 2 THEN 'SATIAGO'
							END = @CODSEDE OR @CODSEDE IS NULL)
	                AND C.CODCARR = P.CODCARR
	                AND C.VIGENTE = 1
	           INNER JOIN ADM_MAE_SEDE S
	                ON  (S.NOMBRE = @CODSEDE OR @CODSEDE IS NULL)
	                AND C.CODSEDE = S.CODSEDE
	           INNER JOIN ADM_DATOS_POSTULANTES ADP
	                ON  P.CODPOSTUL = ADP.CODCLI
	                AND ADP.CODCARR = P.CODCARR
	           LEFT JOIN DB_ADMISION.DBO.ADM_INSCRITOS AI
	                ON  AI.NUM_DOC = ADP.CODCLI
	           LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS UE
	                ON  UE.LOC_CODIGO = AI.LOC_CODIGO
	                AND UE.UED_CODIGO = AI.UED_CODIGO
	           LEFT JOIN DB_ADMISION.DBO.ADM_UNIDADES_EDUCATIVAS_TARGET UET
	                ON  UET.LOC_CODIGO = UE.LOC_CODIGO
	                AND UET.UED_CODIGO = UE.UED_CODIGO
	    WHERE  BE.CODBEN = 456 /*409*/
	           --AND ADP.ESTADO = 'A'
	           AND P.ESTADO = 'A'
	           AND C.VIGENTE = 1
	             AND 
	             ( 
	             	C.CODCARR IN (SELECT AMC.CODCARR
	                             FROM   ADM_MAE_CARRERA AMC
	                                    INNER JOIN 
	                                         ADM_USUARIO_ASIGNACION_CARRERA 
	                                         AUAC
	                                         ON  AUAC.CODCARR = AMC.CODCARR
	                             WHERE  AUAC.ID_USUARIO = @USUARIO)
	                OR @USUARIO IS NULL
	                )             
	    ORDER BY
	           S.NOMBRE,
	           C.CODCARR,
	           ADP.LUGAR
	
END

