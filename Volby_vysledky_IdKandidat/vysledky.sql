--převedení kandidátů ze sloupců na řádky + přidání kraje
CREATE OR REPLACE temporary TABLE "2025_PS_vysledky_okrsky_hlasy" as
SELECT
		 "OKRES"
		,"KodObec"
    ,"OKRSEK"
		,"KSTRANA"
		,"POC_HLASU"
    ,"VOLKRAJ"
    ,cast(SUBSTR("PORCISLO", 7) AS int) as poradi_final
    ,hlasy
FROM (select 
    "PSV".*
    ,"KO"."VOLKRAJ"
    ,CASE
    	when KO."OBEC_PREZ" = PSV."OBEC" then KO."OBEC_PREZ"
      else KO."OBEC_PREZ"
     end as "KodObec"
from "2025_PS_vysledky_okrsky" AS "PSV"
LEFT JOIN "Kraje_obce-Kraje" AS "KO"
    ON "PSV"."OBEC" = "KO"."OBEC")
UNPIVOT INCLUDE NULLS (hlasy FOR "PORCISLO" IN (
    "HLASY_01",
    "HLASY_02",
    "HLASY_03",
    "HLASY_04",
    "HLASY_05",
    "HLASY_06",
    "HLASY_07",
    "HLASY_08",
    "HLASY_09",
    "HLASY_10",
    "HLASY_11",
    "HLASY_12",
    "HLASY_13",
    "HLASY_14",
    "HLASY_15",
    "HLASY_16",
    "HLASY_17",
    "HLASY_18",
    "HLASY_19",
    "HLASY_20",
    "HLASY_21",
    "HLASY_22",
    "HLASY_23",
    "HLASY_24",
    "HLASY_25",
    "HLASY_26",
    "HLASY_27",
    "HLASY_28",
    "HLASY_29",
    "HLASY_30",
    "HLASY_31",
    "HLASY_32",
    "HLASY_33",
    "HLASY_34",
    "HLASY_35",
    "HLASY_36"
));

--přidání idkandidát
 CREATE OR REPLACE temporary TABLE "2025_PS_vysledky_okrsky_hlasy_id" as
SELECT
    CONCAT(LPAD(CAST("VOLKRAJ" AS VARCHAR), 2, '0'),
    LPAD(CAST("KSTRANA" AS VARCHAR), 2, '0'),
    LPAD(CAST(poradi_final AS VARCHAR), 2, '0')) as "Idkandidat"
	,"VOLKRAJ"
	,"OKRES"
	,"KodObec"
  ,"OKRSEK"
	,"POC_HLASU"
	,"KSTRANA"
   ,hlasy
FROM "2025_PS_vysledky_okrsky_hlasy";

--propojení kandidátů a okrsků
CREATE OR REPLACE TABLE "2025_PS_vysledky_okrsky_hlasy_id_pohlavi" AS
SELECT
     PSKP."JMENO"
    ,PSKP."PRIJMENI"
    ,PSKP."POHLAVI"
    ,CONCAT(CAST(PSVOH."KodObec" AS VARCHAR),
     CAST(PSVOH."OKRSEK" AS VARCHAR)) as "IdOkrsek"
		,PSVOH.*
FROM "2025_PS_vysledky_okrsky_hlasy_id" AS PSVOH
INNER JOIN "2025_PS_kandidati_pohlavi_id" AS PSKP
ON PSVOH."Idkandidat" = PSKP."Idkandidat";

--Počty hlasů pro ženy po okrscích
CREATE OR REPLACE TABLE "2025_Preferencni_hlasy_zeny_oksrky" AS
SELECT
   *
    ,CASE
    	WHEN "HLASYCELKEM" = 0 then 0
    	else "HLASYZENY"/"HLASYCELKEM"
    END AS "PROCPOC"
FROM 
      (SELECT
    "IdOkrsek",
    "OKRES",
    "KodObec",
    SUM("HLASY") as "HLASYCELKEM",
    SUM(CASE WHEN "POHLAVI" = 'ZENA' THEN "HLASY" ELSE 0 END) AS "HLASYZENY"   
FROM "2025_PS_vysledky_okrsky_hlasy_id_pohlavi"
group by "IdOkrsek", "OKRES","KodObec")
;