/************************************************************
 * DESCRIPCIÓN			: REALIZA LA CARGA DE DATOS HISTÓRICOS QUE ALIMNETAN
 *							AL REPORTE DEL RECTOR
 * SE USA EN			: SISTEMA DE REPORTES, DEBE GATILLARSE MANUALMENTE							
 * AUTOR				: JORGE COLLAO QUEZADA							 
 * FECHA				: 12-10-2016 12:15:38
 ************************************************************/
ALTER  PROCEDURE pa_ADM_Reporte_Rector_CargaDatosHistoricosDePeriodo(@DIAUNO DATETIME ,@AÑO INT ,@CODCARR VARCHAR(30) = NULL)
AS
BEGIN
	IF @AÑO < 2016
	BEGIN
	    SELECT 'NO HAY DATOS HISTORICOS ANTES DEL 2016'
	END
	ELSE
	BEGIN

	DECLARE @FECHA_BISIESTO VARCHAR(6)
	
	SET @FECHA_BISIESTO = (
	        CASE 
	             WHEN @AÑO % 400 = 0 THEN '29-02-'-- 'Año Bisiesto'
	             WHEN @AÑO % 100 = 0 THEN '28-02-'--'Año NO Bisiesto'
	             WHEN @AÑO % 4 = 0 THEN '29-02-'--'Año Bisiesto'
	             ELSE '28-02-'--'Año NO Bisiesto'
	        END
	    )


	    DELETE 
	    FROM   ADM_HISTORICO_POR_DIA
	    WHERE  ANO = @AÑO
	    AND (CODCARR=@CODCARR OR @CODCARR IS NULL)
	    

	    INSERT INTO ADM_HISTORICO_POR_DIA
	    SELECT T.DIA
			,T.FECHA
			,T.AÑO
			,T.PERIODO
	    	,T.CODCARPR
	    	,T.HORA_INI
	    	,T.HORA_FIN
	    	,T.MATRICULADOS_PSU
	    	,T.MATRICULADOS_AE
	    	,T.MATRICULADOS_PSU+T.MATRICULADOS_BACH AS MATRICULADOS_TOTAL
	    	,T.MATRICULADOS_BACH
	    	,T.CODSEDE
	    	,T.MATRICULADOS_PSU_CIERRE
	    	,T.MATRICULADOS_AE_CIERRE
	    	,T.MATRICULADOS_BACH_CIERRE 
	    FROM 
	    (
	    SELECT DISTINCT(
	               SELECT CASE 
	                           WHEN DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) <= 0 THEN 1
	                           ELSE DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) + 1
	                      END
	           )                         AS DIA
	          ,CASE 
	                WHEN DATEDIFF(DAY ,@DIAUNO ,m.FECHA_REGISTRO) <= 0 THEN CONVERT(VARCHAR(10) ,@diauno ,103)
	                ELSE CONVERT(VARCHAR(10) ,m.FECHA_REGISTRO ,103)
	           END                       AS FECHA
	          ,@AÑO                      AS AÑO
	          ,1                         AS PERIODO
	          ,case A.CODCARPR 
				WHEN '1632S' THEN '1633S'
				WHEN '1631S' THEN '1635S'
				ELSE a.CODCARPR
				END AS CODCARPR 
	          
	          ,(
	               SELECT CASE 
	                           WHEN M.FECHA_REGISTRO <= @DIAUNO THEN '00:00'
	                           ELSE CASE 
	                                     WHEN DATEPART(hour ,m.fecha_registro) < 10 THEN '0'
	                                     ELSE ''
	                                END + CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M.FECHA_REGISTRO)) + ':00'
	                      END
	           )                         AS HORA_INI
	          ,(
	               SELECT CASE 
	                           WHEN M.FECHA_REGISTRO <= @DIAUNO THEN '00:59'
	                           ELSE CASE 
	                                     WHEN DATEPART(hour ,m.fecha_registro) < 10 THEN '0'
	                                     ELSE ''
	                                END + CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M.FECHA_REGISTRO)) + ':59'
	                      END
	           )                         AS HORA_FIN
	          ,(-----------------------------------------------------------------------------------------------------------------------------
	               SELECT COUNT(CODCLI)
	               FROM   (
	                          SELECT distinct (A1.CODCLI)
	                          FROM   MT_ALUMNO A1
	                                 INNER JOIN MT_MATRICULAS AS M1
	                                      ON  M1.CODCLI = A1.CODCLI
	                                          AND M1.ITEM = 1
	                                          AND M1.REMATRICULA IS NULL
	                                          AND M1.ANO = A1.ANO
	                       			LEFT JOIN MT_ALUMNO_CAMBIOVIAADMISION AS mac 
										ON mac.CODCLI = A1.CODCLI         
	                                INNER JOIN MT_VIADMISION AS V
	                                      ON V.COD_VIA = CASE 
																WHEN isnull(mac.COD_VIA_ANTERIOR,0)=0 THEN a1.COD_VIA 
																ELSE
																	CASE 
																		WHEN DATEDIFF(DAY,m1.FECHA_REGISTRO,mac.FECHA_CAMBIO)>=0 THEN mac.COD_VIA_ANTERIOR 
																												                ELSE mac.COD_VIA 
																	END
															END            
	                                          AND V.CODTIPOADMISION = 1
	                                          AND m1.CODCLI  NOT IN (SELECT RS.CODCLI
																	FROM   RA_SITU AS RS
																			INNER JOIN RA_TIPOSITU AS RT
																				ON  RS.TIPOSITU = RT.CODIGO
																					AND rs.EMISION <= '20-01-' + LTRIM(CONVERT(VARCHAR ,@AÑO))
																	WHERE  RT.ESTACAD IN ('ELIMINADO' ,'TITULADO' ,'RETRACTADO' ,'EGRESADO')
																			AND 
																				(
																					M.FECHA_REGISTRO > RS.FECHAREG
																					OR
																					(
																					M.FECHA_REGISTRO=RS.FECHAREG AND DATEPART(HOUR,M.FECHA_REGISTRO)>=DATEPART(HOUR,RS.FECHAREG)		
																					)
																				)
																			
																	)   
               
	                          WHERE  A1.ANO = @AÑO
	                                 AND A1.PERIODO = 1
	                                 AND A1.CODCARPR = A.CODCARPR
	                                 AND M1.FECHA_REGISTRO <= @FECHA_BISIESTO + LTRIM(RTRIM(STR(@AÑO)))--*
	                                 AND CASE 
	                                          WHEN DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) <= 0 THEN 1
	                                          ELSE DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO)+1
	                                     END = CASE 
	                                                WHEN DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO) <= 0 THEN 1
	                                                ELSE DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO)+1
	                                           END
	                                 AND CASE 
	                                          WHEN DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) < 0 THEN '00:00'
	                                          ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M.FECHA_REGISTRO))
	                                     END + ':00' = CASE 
	                                                        WHEN DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO) < 0 THEN '00:00'
	                                                        ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M1.FECHA_REGISTRO))
	                                                   END + ':00'
	                                         
	                           
									 

	                      )T
	           )  AS MATRICULADOS_PSU---------------------------------------------------------------------------------------------------------
	          ,(
	               SELECT COUNT(A1.CODCLI)
	               FROM   MT_ALUMNO A1
	                      INNER JOIN MT_MATRICULAS AS M1
	                           ON  M1.CODCLI = A1.CODCLI
	                               AND M1.ITEM = 1
	                               AND M1.REMATRICULA IS NULL
	                               AND M1.ANO = A1.ANO
	                               AND m1.CODCLI  NOT IN (SELECT RS.CODCLI
																	FROM   RA_SITU AS RS
																			INNER JOIN RA_TIPOSITU AS RT
																				ON  RS.TIPOSITU = RT.CODIGO
																					AND rs.EMISION <= '20-01-' + LTRIM(CONVERT(VARCHAR ,@AÑO))
																	WHERE  RT.ESTACAD IN ('ELIMINADO' ,'TITULADO' ,'RETRACTADO' ,'EGRESADO')
																			AND 
																				(
																					m1.fecha_registro > rs.FECHAREG
																					OR
																					(
																					m1.fecha_registro=rs.FECHAREG AND DATEPART(hour,m1.fecha_registro)>=DATEPART(hour,rs.FECHAREG)		
																					)
																				)
																			
																	)   
						 LEFT JOIN MT_ALUMNO_CAMBIOVIAADMISION AS mac 
							   ON mac.CODCLI = A1.CODCLI         									       	                               
	               WHERE  A1.ANO = @AÑO
	                      AND A1.PERIODO = 1
	                      AND A1.CODCARPR = A.CODCARPR
	                      AND CASE 
	                               WHEN DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) <= 0 THEN 1
	                               ELSE DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO)+1
	                          END = CASE 
	                                     WHEN DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO) <= 0 THEN 1
	                                     ELSE DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO)+1
	                                END
	                      AND CASE 
	                               WHEN DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) < 0 THEN '00:00'
	                               ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M.FECHA_REGISTRO))
	                          END + ':00' = CASE 
	                                             WHEN DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO) < 0 THEN '00:00'
	                                             ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M1.FECHA_REGISTRO))
	                                        END + ':00'
						 AND CASE 
											WHEN isnull(mac.COD_VIA_ANTERIOR,0)=0 THEN a1.COD_VIA 
												ELSE
													CASE 
														WHEN DATEDIFF(DAY,m1.FECHA_REGISTRO,mac.FECHA_CAMBIO)>0 THEN mac.COD_VIA_ANTERIOR 
														ELSE mac.COD_VIA 
													END
									END  IN (10
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
											,28										
									)  	                                        	                   
	                      
	                      
	                      
	           )                         AS MATRICULADOS_AE

	          ,(
	          	
	          	SELECT COUNT(A1.CODCLI)
	               FROM   MT_ALUMNO A1
	                      INNER JOIN MT_MATRICULAS AS M1
	                           ON  M1.CODCLI = A1.CODCLI
	                               AND M1.ITEM = 1
	                               AND M1.REMATRICULA IS NULL
	                               AND M1.ANO = A1.ANO	                                
						 LEFT JOIN MT_ALUMNO_CAMBIOVIAADMISION AS mac 
							   ON mac.CODCLI = A1.CODCLI         
									AND CASE 
											WHEN isnull(mac.COD_VIA_ANTERIOR,0)=0 THEN a1.COD_VIA 
												ELSE
													CASE 
														WHEN DATEDIFF(DAY,m1.FECHA_REGISTRO,mac.FECHA_CAMBIO)>0  /**/AND DATEPART(HOUR,MAC.FECHA_CAMBIO)<DATEPART(DAY,M1.FECHA_REGISTRO)/**/   THEN mac.COD_VIA_ANTERIOR 
														ELSE mac.COD_VIA 
													END
									END  = 19 
									AND m1.CODCLI  NOT IN (SELECT RS.CODCLI
																	FROM   RA_SITU AS RS
																			INNER JOIN RA_TIPOSITU AS RT
																				ON  RS.TIPOSITU = RT.CODIGO
																					AND rs.EMISION <= '20-01-' + LTRIM(CONVERT(VARCHAR ,@AÑO))
																	WHERE  RT.ESTACAD IN ('ELIMINADO' ,'TITULADO' ,'RETRACTADO' ,'EGRESADO')
																			AND 
																				(
																					m.fecha_registro > rs.FECHAREG
																					OR
																					(
																					m.fecha_registro=rs.FECHAREG AND DATEPART(hour,m.fecha_registro)>=DATEPART(hour,rs.FECHAREG)		
																					)
																				)
																			
																	)         	                               
	               WHERE  A1.ANO = @AÑO
	                      AND A1.PERIODO = 1
	                      AND A1.CODCARPR = A.CODCARPR
	                      AND M1.FECHA_REGISTRO <= @FECHA_BISIESTO + LTRIM(RTRIM(STR(@AÑO)))--*
	                      AND CASE 
	                               WHEN DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) <= 0 THEN 1
	                               ELSE DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO)+1
	                          END = CASE 
	                                     WHEN DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO) <= 0 THEN 1
	                                     ELSE DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO)+1
	                                END
	                      AND CASE 
	                               WHEN DATEDIFF(DAY ,@DIAUNO ,M.FECHA_REGISTRO) < 0 THEN '00:00'
	                               ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M.FECHA_REGISTRO))
	                          END + ':00' = CASE 
	                                             WHEN DATEDIFF(DAY ,@DIAUNO ,M1.FECHA_REGISTRO) < 0 THEN '00:00'
	                                             ELSE CONVERT(VARCHAR(5) ,DATEPART(HOUR ,M1.FECHA_REGISTRO))
	                                        END + ':00'
	              
	           )                         AS MATRICULADOS_BACH
	          ,A.CODSEDE
	           
	           --------------------------------------------------------
	          ,(
	               SELECT COUNT(CODCLI)
	               FROM   (
	                          SELECT (A1.CODCLI)
	                          FROM   MT_ALUMNO A1
	                                 INNER JOIN MT_MATRICULAS AS M1
	                                      ON  M1.CODCLI = A1.CODCLI
	                                          AND M1.ITEM = 1
	                                          AND M1.REMATRICULA IS NULL
	                                          AND M1.ANO = A1.ANO
	                                 INNER JOIN MT_VIADMISION AS V
	                                      ON  V.COD_VIA = A1.COD_VIA
	                                          AND V.CODTIPOADMISION = 1
	                          WHERE  A1.ANO = @AÑO
	                                 AND A1.PERIODO = 1
	                                 AND A1.CODCARPR = A.CODCARPR
	                                 AND M.FECHA_REGISTRO <= @FECHA_BISIESTO + LTRIM(RTRIM(STR(@AÑO)))
	                          
	                          
	                          UNION
	                          
	                          
	                          SELECT (A1.CODCLI)
	                          FROM   MT_ALUMNO A1
	                                 INNER JOIN MT_MATRICULAS AS M1
	                                      ON  M1.CODCLI = A1.CODCLI
	                                          AND M1.ITEM = 1
	                                          AND M1.REMATRICULA IS NULL
	                                          AND M1.ANO = A1.ANO
	                          WHERE  A1.ANO = @AÑO
	                                 AND A1.PERIODO = 1
	                                 AND A1.CODCARPR = A.CODCARPR
	                                 AND M.FECHA_REGISTRO <= @FECHA_BISIESTO + LTRIM(RTRIM(STR(@AÑO)))
	                                 AND A1.COD_VIA = 29
	                      )T
	           )                         AS MATRICULADOS_PSU_CIERRE
	          ,(
	               SELECT COUNT(A1.CODCLI)
	               FROM   MT_ALUMNO A1
	                      INNER JOIN MT_MATRICULAS AS M1
	                           ON  M1.CODCLI = A1.CODCLI
	                               AND M1.ITEM = 1
	                               AND M1.REMATRICULA IS NULL
	                               AND M1.ANO = A1.ANO
	               WHERE  A1.ANO = @AÑO
	                      AND A1.PERIODO = 1
	                      AND A1.CODCARPR = A.CODCARPR
	                      AND M.FECHA_REGISTRO <= '30-04-' + LTRIM(RTRIM(STR(@AÑO)))
	                      AND A1.COD_VIA IN (10
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
	           )                         AS MATRICULADOS_AE_CIERRE
	          ,(
	               SELECT COUNT(A1.CODCLI)
	               FROM   MT_ALUMNO A1
	                      INNER JOIN MT_MATRICULAS AS M1
	                           ON  M1.CODCLI = A1.CODCLI
	                               AND M1.ITEM = 1
	                               AND M1.REMATRICULA IS NULL
	                               AND M1.ANO = A1.ANO
	               WHERE  A1.ANO = @AÑO
	                      AND A1.PERIODO = 1
	                      AND A1.CODCARPR = A.CODCARPR
	                      AND M1.FECHA_REGISTRO <= '20-01-' + LTRIM(RTRIM(STR(@AÑO)))
	                      AND A1.COD_VIA = 19
	           )                         AS MATRICULADOS_BACH_CIERRE
	    FROM   MT_ALUMNO                 AS A
	           INNER JOIN MT_MATRICULAS  AS M
	                ON  M.CODCLI = A.CODCLI
	                    AND M.ITEM = 1
	                    AND M.REMATRICULA IS NULL
	                    AND M.ANO = A.ANO
	                    AND m.PERIODO=1
	           INNER JOIN MT_CARRER_CLASIFICACION AS mcc 
					ON a.CODCARPR=mcc.CODCARR
						AND mcc.CODTIPO=2
						AND a.ANO BETWEEN mcc.ANO_INI AND mcc.ANO_FIN		  		
	    WHERE  A.ANO = @AÑO
	           AND A.PERIODO = 1
	           AND A.PERIODO_MAT = A.PERIODO
	           AND (A.CODCARPR = @CODCARR OR @CODCARR IS NULL)
	           	                     
	    --ORDER BY
	    --       A.CODCARPR
	    )
	    T
	    IF @@ERROR <> 0
	    BEGIN
	        SELECT 'PROBLEMAS AL GENERAR LOS DATOS NUEVOS, BORRANDO LO YA GENERADO...'
	        DELETE 
	        FROM   ADM_HISTORICO_POR_DIA
	        WHERE  ANO = @AÑO
	    END
	    ELSE
	    BEGIN
	        SELECT 'FINALIZADO CON ÉXITO - INFORME RECTOR'
	    END
	END
---------------------------------------------------------------------------


SELECT 'INSERTANDO PARA INFORME 1'
DELETE 
FROM   ADM_DATAHISTORICA
WHERE  ANO_ADM = @AÑO

INSERT INTO ADM_DATAHISTORICA
SELECT C.CODCARR,
      @AÑO             AS 'AÑO_ADMISION',
      MATRICULA.FN_ADM_INFORMECONTROLMATRICULACOMITERECTORIA_CUENTACONVOCADOSLE(C.CODCARR, 1, 0) AS 
      CONVOCADOS,
      MATRICULA.FN_ADM_INFORMECONTROLMATRICULACOMITERECTORIA_CUENTACONVOCADOSLE(C.CODCARR, 0, 1) AS 
      LISTA_ESPERA,
      MATRICULA.FN_ADM_INFORMECONTROLMATRICULACOMITERECTORIA_PJEPONDMAXMINCONVOCADOSLE(C.CODCARR, 1, 0, 1) AS 
      PTJEPOND_PRIMERCONVOCADO,
      MATRICULA.FN_ADM_INFORMECONTROLMATRICULACOMITERECTORIA_PJEPONDMAXMINCONVOCADOSLE(C.CODCARR, 1, 0, 0) AS 
      PTJEPOND_ULTIMOCONVOCADO,
      PTJEPROM_PRIMERCONVOCADO = COALESCE(
          (
              SELECT TOP 1 COALESCE(
                         CONVERT(DECIMAL(6, 2), (P.PAAVERBAL + P.PAAMATEMAT) / 2),
                         0
                     )
              FROM   ADM_DATOS_POSTULANTES P
              WHERE  P.CODCARR = C.CODCARR
              ORDER BY
                     P.LUGAR ASC
          ),
          0
      ),
      PTJEPROM_ULTIMOCONVOCADO = COALESCE(
          (
              SELECT TOP 1 COALESCE(
                         CONVERT(DECIMAL(6, 2), (P.PAAVERBAL + P.PAAMATEMAT) / 2),
                         0
                     )
              FROM   ADM_DATOS_POSTULANTES P
              WHERE  P.CODCARR = C.CODCARR
              ORDER BY
                     P.LUGAR DESC
          ),
          0
      )
FROM MT_CARRER_CLASIFICACION AS     C
WHERE  C.CODTIPO= 2
    
    
    SELECT 'FIN INSERCIÓN PARA INFORME 1'  	
	
END

