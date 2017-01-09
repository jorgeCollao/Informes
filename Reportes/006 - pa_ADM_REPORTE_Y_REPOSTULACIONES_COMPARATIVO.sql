/************************************************************
 * AUTOR:	JORGE COLLAO Q.
 * Time: 16-11-2016 16:32:55
 ************************************************************/

create  PROCEDURE pa_ADM_REPORTE_Y_REPOSTULACIONES_COMPARATIVO(@SEDE VARCHAR(10) = NULL)
AS
BEGIN
	DECLARE @AÑO_ADMISION INT
	SET @AÑO_ADMISION = (
	        SELECT MP.ANOADMISION
	        FROM   MT_PARAME AS MP
	    )
	
	SELECT MC.CODCARR
	      ,MC.NOMBRE_C
	      ,MC.SEDE
	      ,(
	           SELECT COUNT(*)
	           FROM   MT_ALUMNO AS MA
	                  INNER JOIN MT_MATRICULAS AS MM
	                       ON  MM.CODCLI = MA.CODCLI
	                           AND MM.ITEM = 1
	                           AND MM.REMATRICULA IS NULL
	                  INNER JOIN MT_POSCAR AS MP
	                       ON  MP.ANO = MA.ANO
	                           AND MP.PERIODO = MA.PERIODO
	                           AND MP.CODPOSTUL = MA.RUT
	                           AND MP.CODCARR = MA.CODCARPR
	                  INNER JOIN MT_POSTULACION_VIA AS MPV
	                       ON  MPV.CODPOSTUL = MP.CODPOSTUL
	                           AND MPV.CODCARR = MP.CODCARR
	                           AND MPV.ANO = MP.ANO
	                           AND MPV.PERIODO = MP.PERIODO
	           WHERE  MA.ESTACAD IN ('VIGENTE' ,'SUSPENDIDO')
	                  AND MPV.COD_VIA = 29
	                  AND MM.ANO = @AÑO_ADMISION
	                  AND MA.ANO = @AÑO_ADMISION
	                  AND MA.CODCARPR = MC.CODCARR
	       )          AS CANTIDAD_HOY
	      ,(
	           SELECT COUNT(*)
				FROM   MT_ALUMNO                      AS MA
					   INNER JOIN MT_MATRICULAS       AS MM
							ON  MM.CODCLI = MA.CODCLI
								AND MM.ITEM = 1
								AND MM.REMATRICULA IS NULL
					   INNER JOIN MT_POSCAR           AS MP
							ON  MP.ANO = MM.ANO
								AND MP.PERIODO = Mm.PERIODO
								AND MP.CODPOSTUL = MA.RUT
								AND MP.CODCARR = MA.CODCARPR
	           WHERE  ma.COD_VIA = 29
	                  AND MM.ANO = @AÑO_ADMISION -1
	                  AND MA.CODCARPR = MC.CODCARR
	                  AND mm.CODCLI  not IN (SELECT RS.CODCLI
                                 FROM   RA_SITU AS RS
                                        INNER JOIN RA_TIPOSITU AS RT
                                             ON  RS.TIPOSITU = RT.CODIGO
                                         AND rs.EMISION<='30-04-'+ltrim(convert(varchar,@AÑO_ADMISION-1))    
                                 WHERE  RT.ESTACAD IN ('ELIMINADO' ,'TITULADO' ,'RETRACTADO' ,'EGRESADO'))
	       )          AS CANTIDAD_ANTERIOR
	FROM   MT_CARRER  AS MC
	       INNER JOIN MT_CARRER_CLASIFICACION AS MCC
	            ON  MCC.CODCARR = MC.CODCARR
	                AND MCC.CODTIPO = 2
	                AND @AÑO_ADMISION BETWEEN MCC.ANO_INI AND MCC.ANO_FIN
	WHERE  (MC.SEDE = @SEDE OR @SEDE IS NULL)
	ORDER BY
	       MC.SEDE
	      ,MC.CODCARR
END