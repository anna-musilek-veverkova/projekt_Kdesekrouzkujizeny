CREATE OR REPLACE TABLE "2025_PS_kandidati_pohlavi_id" AS
SELECT
    --vytvoření idkandidát
	CONCAT(LPAD(CAST("VOLKRAJ" AS VARCHAR), 2, '0'),
    LPAD(CAST("KSTRANA" AS VARCHAR), 2, '0'),
    LPAD(CAST("PORCISLO" AS VARCHAR), 2, '0')) as "Idkandidat"
    ,"JMENO"
    ,"PRIJMENI"
    ,"VEK"
    ,"PORCISLO"
    ,CASE	
		WHEN "DRUH_JMENA" = 'ZENA' THEN 'ZENA'
		WHEN "DRUH_JMENA" = 'MUZ' THEN 'MUZ'
    	when "DRUH_JMENA_PRIJMENI" = 'ZENA' THEN 'ZENA'
    	WHEN "DRUH_JMENA" IS NULL AND "DRUH_JMENA_2" IS NOT NULL THEN "DRUH_JMENA_2"
    	WHEN ("DRUH_JMENA" = 'NEUTRALNI'OR "DRUH_JMENA" IS NULL) AND "DRUH_JMENA_POVOLANI" = "DRUH_JMENA_PRIJMENI" THEN "DRUH_JMENA_PRIJMENI"
    	WHEN "PRIJMENI" = 'Nwelati' THEN 'MUZ'
		ELSE 'ZENA' 
    end AS "POHLAVI"
    ,"POVOLANI"
    ,"BYDLISTEN" AS "OBEC"
    ,"POCHLASU"
    ,"POCPROC"
	,"MANDAT"
    ,"PORADIMAND"
    ,"PORADINAHR"
    ,"VOLKRAJ"
    ,"KSTRANA"
FROM (SELECT 
    "sju"."DRUH_JMENA" AS "DRUH_JMENA",
    "sju2"."DRUH_JMENA" AS "DRUH_JMENA_2",
    CASE 
        WHEN "PSK"."PRIJMENI" ILIKE '%á %' OR "PSK"."PRIJMENI" ILIKE '%á' or "PSK"."PRIJMENI" ILIKE '%ova' or "PSK"."PRIJMENI" ILIKE '%ova %' THEN 'ZENA' 
        ELSE 'MUZ'
    END AS "DRUH_JMENA_PRIJMENI",
   CASE
    	when "PSK"."POVOLANI" ILIKE '%ka' or "PSK"."POVOLANI" ilike '%ně' or "PSK"."POVOLANI" ilike '%ice' or "PSK"."POVOLANI" ILIKE '%ka %' or "PSK"."POVOLANI" ilike '%ně %' or "PSK"."POVOLANI" ilike '%ice %' or "PSK"."POVOLANI" ilike '%ra %' or "PSK"."POVOLANI" ilike '%ra' or "PSK"."POVOLANI" ilike '%á' or "PSK"."POVOLANI" ilike '%á %'THEN 'ZENA'
    	when "PSK"."POVOLANI" ILIKE '%tel' or "PSK"."POVOLANI" ilike '%ář' or "PSK"."POVOLANI" ilike '%ík' or "PSK"."POVOLANI" ilike '%ista' or "PSK"."POVOLANI" ilike '%ik' or "PSK"."POVOLANI" ilike '%or' or "PSK"."POVOLANI" ilike '%er' or "PSK"."POVOLANI" ILIKE '%tel %' or "PSK"."POVOLANI" ilike '%ář %' or "PSK"."POVOLANI" ilike '%ík %' or "PSK"."POVOLANI" ilike '%ista %' or "PSK"."POVOLANI" ilike '%ik %' or "PSK"."POVOLANI" ilike '%or %' or "PSK"."POVOLANI" ilike '%er %' or "PSK"."POVOLANI" ilike '%ert' or "PSK"."POVOLANI" ilike '%ert %' or "PSK"."POVOLANI" ilike '%íř' or "PSK"."POVOLANI" ilike '%íř %' or "PSK"."POVOLANI" ilike '%osta %' or "PSK"."POVOLANI" ilike '%osta' or "PSK"."POVOLANI" ilike '%el %' or "PSK"."POVOLANI" ilike '%el' or "PSK"."POVOLANI" ilike '%ek %' or "PSK"."POVOLANI" ilike '%ek' or "PSK"."POVOLANI" ilike '%ec' or "PSK"."POVOLANI" ilike '%ec %' or "PSK"."POVOLANI" ilike '%ič %' or "PSK"."POVOLANI" ilike '%ič'  or "PSK"."POVOLANI" ilike '%ant'  or "PSK"."POVOLANI" ilike '%ant %'  or "PSK"."POVOLANI" ilike '%og'  or "PSK"."POVOLANI" ilike '%og %'  or "PSK"."POVOLANI" ilike '%el,%'  or "PSK"."POVOLANI" ilike '%ec,%'  or "PSK"."POVOLANI" ilike '%ař'  or "PSK"."POVOLANI" ilike '%ař %' or "PSK"."POVOLANI" ilike '%ent %' or "PSK"."POVOLANI" ilike '%ent' or "PSK"."POVOLANI" ilike '%ce %' or "PSK"."POVOLANI" ilike '%ce'  or "PSK"."POVOLANI" ilike '%předseda%' or "PSK"."POVOLANI" ilike '%an' or "PSK"."POVOLANI" ilike '%an %' THEN 'MUZ'
    	else 'NEUTRALNI'
    END AS "DRUH_JMENA_POVOLANI",
    "PSK".*
FROM (
    SELECT
        SPLIT_PART(REGEXP_REPLACE("JMENO", '-', ' '), ' ', 1) AS "jmeno1",
        SPLIT_PART(REGEXP_REPLACE("JMENO", '-', ' '), ' ', 2) AS "jmeno2",
        *
    FROM "2025_PS_kandidati"
    where "PLATNOST" = 'A'
   ) AS "PSK"
LEFT JOIN "Seznam_jmen_unikat" as "sju"
    ON LOWER("PSK"."jmeno1") = LOWER("sju"."JMENO")
LEFT JOIN "Seznam_jmen_unikat" as "sju2"
    ON LOWER("PSK"."jmeno2") = LOWER("sju2"."JMENO"));