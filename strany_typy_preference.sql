-- Výpočet preferenčních hlasů pro ženy a muže v jednotlivých stranách
CREATE OR REPLACE TABLE "Preferencni_hlasy_strany" AS
SELECT
    *
    ,NTILE(4) OVER (ORDER BY TRY_CAST("Podil_preferencni_hlasy_zeny_strany" AS FLOAT)) AS "kvartal"
FROM (SELECT
   *
   ,CASE
        WHEN "Preferencni_hlasy_celkem_strany" = 0 THEN 0
        ELSE ("Pocet_preferencni_hlasy_zeny_strany" * 100.0) / "Preferencni_hlasy_celkem_strany"
    END AS "Podil_preferencni_hlasy_zeny_strany"
    ,CASE
        WHEN "Preferencni_hlasy_celkem_strany" = 0 THEN 0
        ELSE ("Pocet_preferencni_hlasy_muzi_strany" * 100.0) / "Preferencni_hlasy_celkem_strany"
    END AS "Podil_preferencni_hlasy_muzi_strany"
FROM 
      (SELECT
   	"KSTRANA"
    ,SUM("HLASY") as "Preferencni_hlasy_celkem_strany"
    ,SUM(CASE WHEN "POHLAVI" = 'ZENA' THEN "HLASY" ELSE 0 END) AS "Pocet_preferencni_hlasy_zeny_strany"
    ,sum(CASE WHEN "POHLAVI" = 'ZENA' THEN 1 ELSE 0 END) AS "pocet_kandidatek"
    ,SUM(CASE WHEN "POHLAVI" = 'MUZ' THEN "HLASY" ELSE 0 END) AS "Pocet_preferencni_hlasy_muzi_strany"
    ,SUM(CASE WHEN "POHLAVI" = 'MUZ' THEN 1 ELSE 0 END) AS "pocet_kandidatu"
FROM "2025_PS_vysledky_okrsky_hlasy_id_pohlavi"
group by "KSTRANA"));

--přiřazení typu strany
create or replace table "Strany_typ" as
select *,
    CASE 
        -- Liberální blok
        WHEN NAZEVCELK IN (
            'SPOLU (ODS, KDU-ČSL, TOP 09)', 
            'Česká pirátská strana', 
            'STAROSTOVÉ A NEZÁVISLÍ'
        ) THEN 'Liberalni'

        -- Konzeravitní blok
        WHEN NAZEVCELK IN (
            'Svoboda a přímá demokracie (SPD)', 
            'Motoristé sobě', 
            'ANO 2011'               		
        ) THEN 'Konzervativni'
    END AS "Strany_typ"
from "2025_PS_strany";

--spojení preferenčních hlasů pro ženy s typem strany
create or replace table "Preferencni_hlasy_strany_typ" as
select 
    "Preferencni_hlasy_strany"."KSTRANA"	
	,"Preferencni_hlasy_strany"."Podil_preferencni_hlasy_zeny_strany"
    ,"Strany_typ"."Strany_typ"
from  "Preferencni_hlasy_strany"
left join  "Strany_typ" on  "Strany_typ"."KSTRANA" = "Preferencni_hlasy_strany"."KSTRANA"
where "Preferencni_hlasy_strany"."KSTRANA" in (6,11,16,20,22,23);