USE [matricula]
GO
/****** Object:  StoredProcedure [matricula].[pa_ADM_Reporte_A_ConvocadosPostulacionesEfectivas]    Script Date: 12-12-2016 11:07:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/************************************************************
 * ROBERTO LARRONDE RYBERTT
 * Fecha: 19-12-2012 17:01:19
 ************************************************************/

-- EXEC pa_ADM_Reporte_A_ConvocadosPostulacionesEfectivas NULL,NULL,1,NULL
-- EXEC pa_ADM_Reporte_A_ConvocadosPostulacionesEfectivas 'CONCEPCION',NULL,0,NULL

/****************************************************************************************/
/*
* MODIFICACIONES PROCESO 2015
* FECHA			: 04/08/2014
* AUTOR			: Alexanders Gutierrez Muñoz
* DESCRIPCION	: - se agrega campo de año proceso anterior, para efectos de titulos del informe.
*					ANO_ANT = año anterior al proceso actual.
*				  - Modificación de procedimiento, para control de divisiones por cero.			
*/


 
ALTER PROCEDURE [matricula].[pa_ADM_Reporte_A_ConvocadosPostulacionesEfectivas](
    @CODSEDE  VARCHAR(30) = NULL,
    @CODCARR  VARCHAR(30) = NULL,
    @RESUMEN  BIT = 1,
    @USUARIO  VARCHAR(50) = NULL
)
AS
BEGIN
	DECLARE @ANOPROCESO      INT,
	        @PERIODOPROCESO  INT,
	        @ANOPROCESOANT   INT
	
	SELECT @ANOPROCESO = MATRICULA.FN_OBTIENEANOPERIODO('A', 'M'),
	       @PERIODOPROCESO = 1
	SET @ANOPROCESOANT = @ANOPROCESO - 1
	
	DECLARE @TABLA TABLE (
	            SEDE VARCHAR(30),
	            CODCARR VARCHAR(30),
	            CODDEMRE VARCHAR(30),
	            NOMBRE VARCHAR(150),
	            CUPO_OFICIAL INT,
	            SOBRECUPO INT,
	            CUPO_OFICIAL_SOBRECUPO INT,
	            CONVOCADOS INT,
	            POSTULACIONES_EFECTIVAS INT,
	            POSTULANTES_X_CUPO DECIMAL(4, 1),
	            PTJE_POND_PRIMER_CONV DECIMAL(6, 2),
	            PTJE_POND_ULT_CONV DECIMAL(5, 2),
	            CUPO_OFICIAL_ANT INT DEFAULT 0,
	            SOBRECUPO_ANT INT DEFAULT 0,
	            CUPO_OFICIAL_SOBRECUPO_ANT INT DEFAULT 0,
	            CONVOCADOS_ANT INT,
	            POSTULACIONES_EFECTIVAS_ANT INT,
	            POSTULANTES_X_CUPO_ANT DECIMAL(4, 1),
	            PTJE_POND_PRIMER_CONV_ANT DECIMAL(6, 2),
	            PTJE_POND_ULT_CONV_ANT DECIMAL(6, 2),
	            ANO_ANT INT
	        )
	
	INSERT INTO @TABLA
	SELECT Z.SEDE,
	       Z.CODCARR,
	       Z.COD_DEMRE,
	       Z.NOMBRE,
	       Z.CUPO_OFICIAL,
	       Z.SOBRECUPO,
	       Z.CUPO_OFICIAL_SOBRECUPO,
	       Z.CONVOCADOS,
	       Z.POSTULACIONES_EFECTIVAS,
	       CASE 
	            WHEN Z.CUPO_OFICIAL > 0 THEN CAST(
	                     CAST(Z.POSTULACIONES_EFECTIVAS AS FLOAT) / CAST(Z.CUPO_OFICIAL AS FLOAT) AS DECIMAL(4, 1)
	                 )
	            ELSE 0
	       END AS POSTULANTES_X_CUPO,
	       Z.PTJE_POND_PRIMER_CONV,
	       Z.PTJE_POND_ULT_CONV,
	       COALESCE(Z.CUPO_OFICIAL_ANT, 0),
	       COALESCE(Z.SOBRECUPO_ANT, 0),
	       COALESCE(Z.CUPO_OFICIAL_ANT + Z.SOBRECUPO_ANT, 0) AS CUPO_OFICIAL_SOBRECUPO_ANT,
	       Z.CONVOCADOS_ANT,
	       Z.POSTULACIONES_EFECTIVAS_ANT,
	       CASE 
	            WHEN Z.CUPO_OFICIAL_ANT > 0 THEN CAST(
	                     CAST(Z.POSTULACIONES_EFECTIVAS_ANT AS FLOAT) / CAST(Z.CUPO_OFICIAL_ANT AS FLOAT) AS DECIMAL(4, 1)
	                 )
	            ELSE 0
	       END AS POSTULANTES_X_CUPO_ANT,
	       Z.PTJEPOND_PRIMERCONVOCADO,
	       Z.PTJEPOND_ULTIMOCONVOCADO,
	       @ANOPROCESOANT AS ANO_ANT
	FROM   (
	           SELECT mc.SEDE,
	                  mc.CODCARR,
	                  AMC.COD_DEMRE,
	                  mc.NOMBRE_C AS NOMBRE,
	                  MP.VACANTE_REGULAR AS CUPO_OFICIAL,
	                  MP.VACANTE_SOBRECUPO AS SOBRECUPO,
	                  MP.VACANTE_REGULAR + MP.VACANTE_SOBRECUPO AS CUPO_OFICIAL_SOBRECUPO,
	                  MATRICULA.FN_ADM_INFORMECONTROLMATRICULACOMITERECTORIA_CUENTACONVOCADOSLE(case mc.CODCARR WHEN '1633S' THEN '1632S' WHEN '1635S' THEN '1631S' ELSE mc.CODCARR END, 1, 0) AS CONVOCADOS,
	                  MATRICULA.FN_ADM_INFORMECONTROLMATRICULACOMITERECTORIA_CUENTACONVOCADOSLE(case mc.CODCARR WHEN '1633S' THEN '1632S' WHEN '1635S' THEN '1631S' ELSE mc.CODCARR END, 1, 1) AS POSTULACIONES_EFECTIVAS,
	                  MATRICULA.FN_ADM_INFORMECONTROLMATRICULACOMITERECTORIA_PJEPONDMAXMINCONVOCADOSLE(case mc.CODCARR WHEN '1633S' THEN '1632S' WHEN '1635S' THEN '1631S' ELSE mc.CODCARR END, 1, 0, 1) AS PTJE_POND_PRIMER_CONV,
	                  MATRICULA.FN_ADM_INFORMECONTROLMATRICULACOMITERECTORIA_PJEPONDMAXMINCONVOCADOSLE(case mc.CODCARR WHEN '1633S' THEN '1632S' WHEN '1635S' THEN '1631S' ELSE mc.CODCARR END, 1, 0, 0) AS PTJE_POND_ULT_CONV,
	                  --MP.PTJEPONDANTERIOR AS PTJE_POND_ULT_CONV,
	                  CUPO_OFICIAL_ANT = (
	                      SELECT MP2.VACANTE_REGULAR
	                      FROM   MT_PJECORTEPONDERADOCARRERA MP2
	                      WHERE  MP2.CODCARR = case mc.CODCARR WHEN '1633S' THEN '1632S' WHEN '1635S' THEN '1631S' ELSE mc.CODCARR END
	                             AND MP2.ANO = @ANOPROCESOANT
	                             AND MP2.PERIODO = @PERIODOPROCESO
	                  ),
	                  SOBRECUPO_ANT = (
	                      SELECT MP2.VACANTE_SOBRECUPO
	                      FROM   MT_PJECORTEPONDERADOCARRERA MP2
	                      WHERE  MP2.CODCARR = case mc.CODCARR WHEN '1633S' THEN '1632S' WHEN '1635S' THEN '1631S' ELSE mc.CODCARR END
	                             AND MP2.ANO = @ANOPROCESOANT
	                             AND MP2.PERIODO = @PERIODOPROCESO
	                  ),
	                  COALESCE(AD.CONVOCADOS, 0) AS CONVOCADOS_ANT,
	                  COALESCE(AD.CONVOCADOS + AD.LISTAESPERA, 0) AS POSTULACIONES_EFECTIVAS_ANT,
	                  COALESCE(AD.PTJEPOND_PRIMERCONVOCADO, 0) AS PTJEPOND_PRIMERCONVOCADO,
	                  COALESCE(AD.PTJEPOND_ULTIMOCONVOCADO, 0) AS PTJEPOND_ULTIMOCONVOCADO
	           FROM MT_CARRER_CLASIFICACION AS mcc 
					   INNER JOIN MT_CARRER AS mc 
							ON mc.CODCARR = mcc.CODCARR
					   left JOIN db_admision.dbo.ADM_MAE_CARRERA AMC 
							ON AMC.CODCARR = mcc.CODCARR					  
	                   left JOIN db_admision.dbo.ADM_MAE_SEDE AMS
	                       ON  AMS.CODSEDE = AMC.CODSEDE
	                   LEFT JOIN MT_PJECORTEPONDERADOCARRERA MP
	                       ON  MP.CODCARR = mc.CODCARR
	                           AND MP.ANO = @ANOPROCESO
	                           AND MP.PERIODO = @PERIODOPROCESO
	                  LEFT JOIN ADM_DATAHISTORICA AD
	                       ON  AD.CODCARR = case mc.CODCARR WHEN '1633S' THEN '1632S' WHEN '1635S' THEN '1631S' ELSE mc.CODCARR END
	                           AND AD.ANO_ADM = @ANOPROCESOANT
	           WHERE mcc.CODTIPO=2 AND @ANOPROCESO BETWEEN mcc.ANO_INI AND mcc.ANO_FIN  
	       ) Z
	ORDER BY
	       Z.SEDE,
	       CODCARR
	
	IF @RESUMEN = 1
	BEGIN
	    UPDATE @TABLA
	    SET    PTJE_POND_ULT_CONV = NULL
	    WHERE  PTJE_POND_ULT_CONV = 0
	    
	    UPDATE @TABLA
	    SET    PTJE_POND_ULT_CONV_ANT = NULL
	    WHERE  PTJE_POND_ULT_CONV_ANT = 0
	    
	    SELECT X.SEDE,
	           '' AS CODCARR,
	           '' AS CODDEMRE,
	           '' AS NOMBRE,
	           COALESCE(X.CUPO_OFICIAL,0) AS CUPO_OFICIAL,
	           COALESCE(X.SOBRECUPO,0) AS SOBRECUPO,
	           COALESCE(X.CUPO_OFICIAL_SOBRECUPO,0) AS CUPO_OFICIAL_SOBRECUPO,
	           X.CONVOCADOS,
	           X.POSTULACIONES_EFECTIVAS,
	           CASE WHEN X.CUPO_OFICIAL > 0 THEN 
	           CAST(
	               CAST(X.POSTULACIONES_EFECTIVAS AS FLOAT) / CAST(X.CUPO_OFICIAL AS FLOAT) AS DECIMAL(4, 1)
	           )
	           ELSE 0 END AS POSTULANTES_X_CUPO,
	           X.PTJE_POND_PRIMER_CONV,
	           X.PTJE_POND_ULT_CONV,
	           X.CUPO_OFICIAL_ANT,
	           X.SOBRECUPO_ANT,
	           X.CUPO_OFICIAL_SOBRECUPO_ANT,
	           X.CONVOCADOS_ANT,
	           X.POSTULACIONES_EFECTIVAS_ANT,
	           CASE WHEN X.CUPO_OFICIAL_ANT > 0 THEN
	           CAST(
	               CAST(X.POSTULACIONES_EFECTIVAS_ANT AS FLOAT) / CAST(X.CUPO_OFICIAL_ANT AS FLOAT) AS DECIMAL(4, 1)
	           ) ELSE 0 END AS POSTULANTES_X_CUPO_ANT,
	           X.PTJE_POND_PRIMER_CONV_ANT,
	           X.PTJE_POND_ULT_CONV_ANT,
	           @ANOPROCESOANT AS ANO_ANT
	    FROM   (
	               SELECT SEDE,
	                      SUM(CUPO_OFICIAL) AS CUPO_OFICIAL,
	                      SUM(SOBRECUPO) AS SOBRECUPO,
	                      SUM(CUPO_OFICIAL_SOBRECUPO) AS CUPO_OFICIAL_SOBRECUPO,
	                      SUM(CONVOCADOS) AS CONVOCADOS,
	                      SUM(POSTULACIONES_EFECTIVAS) AS POSTULACIONES_EFECTIVAS,
	                      MAX(PTJE_POND_PRIMER_CONV) AS PTJE_POND_PRIMER_CONV,
	                      MIN(PTJE_POND_ULT_CONV) AS PTJE_POND_ULT_CONV,
	                      SUM(CUPO_OFICIAL_ANT) AS CUPO_OFICIAL_ANT,
	                      SUM(SOBRECUPO_ANT) AS SOBRECUPO_ANT,
	                      SUM(CUPO_OFICIAL_SOBRECUPO_ANT) AS CUPO_OFICIAL_SOBRECUPO_ANT,
	                      SUM(CONVOCADOS_ANT) AS CONVOCADOS_ANT,
	                      SUM(POSTULACIONES_EFECTIVAS_ANT) AS POSTULACIONES_EFECTIVAS_ANT,
	                      MAX(PTJE_POND_PRIMER_CONV_ANT) AS PTJE_POND_PRIMER_CONV_ANT,
	                      MIN(PTJE_POND_ULT_CONV_ANT) AS PTJE_POND_ULT_CONV_ANT
	               FROM   @TABLA
	               GROUP BY
	                      SEDE
	           ) X
	    ORDER BY
	           X.SEDE
	END
	ELSE
	BEGIN
	    IF @USUARIO IS NULL
	    BEGIN
	        SELECT SEDE,
	               CODCARR,
	               CODDEMRE,
	               NOMBRE,
	               COALESCE(CUPO_OFICIAL,0) AS CUPO_OFICIAL,
	               COALESCE(SOBRECUPO,0) AS SOBRECUPO,
	               COALESCE(CUPO_OFICIAL_SOBRECUPO,0) AS CUPO_OFICIAL_SOBRECUPO,
	               CONVOCADOS,
	               POSTULACIONES_EFECTIVAS,
	               POSTULANTES_X_CUPO,
	               PTJE_POND_PRIMER_CONV,
	               CASE 
	                    WHEN PTJE_POND_ULT_CONV > 0 THEN PTJE_POND_ULT_CONV
	                    ELSE NULL
	               END AS PTJE_POND_ULT_CONV,
	               CUPO_OFICIAL_ANT,
	               SOBRECUPO_ANT,
	               CUPO_OFICIAL_SOBRECUPO_ANT,
	               CONVOCADOS_ANT,
	               POSTULACIONES_EFECTIVAS_ANT,
	               POSTULANTES_X_CUPO_ANT,
	               PTJE_POND_PRIMER_CONV_ANT,
	               CASE 
	                    WHEN PTJE_POND_ULT_CONV_ANT > 0 THEN PTJE_POND_ULT_CONV_ANT
	                    ELSE NULL
	               END AS PTJE_POND_ULT_CONV_ANT,
	               @ANOPROCESOANT AS ANO_ANT
	        FROM   @TABLA
	        WHERE  (SEDE = @CODSEDE OR @CODSEDE IS NULL)
	               AND (CODCARR = @CODCARR OR @CODCARR IS NULL)
	        ORDER BY
	               SEDE,
	               CODCARR
	    END
	    ELSE
	    BEGIN
	        SELECT T.SEDE,
	               T.CODCARR,
	               T.CODDEMRE,
	               T.NOMBRE,
	               T.CUPO_OFICIAL,
	               T.SOBRECUPO,
	               T.CUPO_OFICIAL_SOBRECUPO,
	               T.CONVOCADOS,
	               T.POSTULACIONES_EFECTIVAS,
	               T.POSTULANTES_X_CUPO,
	               T.PTJE_POND_PRIMER_CONV,
	               CASE 
	                    WHEN T.PTJE_POND_ULT_CONV > 0 THEN T.PTJE_POND_ULT_CONV
	                    ELSE NULL
	               END AS PTJE_POND_ULT_CONV,
	               T.CUPO_OFICIAL_ANT,
	               T.SOBRECUPO_ANT,
	               T.CUPO_OFICIAL_SOBRECUPO_ANT,
	               T.CONVOCADOS_ANT,
	               T.POSTULACIONES_EFECTIVAS_ANT,
	               T.POSTULANTES_X_CUPO_ANT,
	               T.PTJE_POND_PRIMER_CONV_ANT,
	               CASE 
	                    WHEN T.PTJE_POND_ULT_CONV_ANT > 0 THEN T.PTJE_POND_ULT_CONV_ANT
	                    ELSE NULL
	               END AS PTJE_POND_ULT_CONV_ANT,
	               @ANOPROCESOANT AS ANO_ANT
	        FROM   @TABLA T
	        WHERE  (T.SEDE = @CODSEDE OR @CODSEDE IS NULL)
	               AND (T.CODCARR = @CODCARR OR @CODCARR IS NULL)
	               AND T.CODCARR IN (SELECT AUAC.CODCARR
	                                 FROM   ADM_USUARIO_ASIGNACION_CARRERA AUAC
	                                 WHERE  AUAC.CODCARR = T.CODCARR
	                                        AND AUAC.ID_USUARIO = @USUARIO)
	        ORDER BY
	               T.SEDE,
	               T.CODCARR
	    END
	END
END


