
--preferenční hlasy pro ženy v obcích + rozdělení do kvartilů
CREATE OR REPLACE TABLE "Preferencni_hlasy_obce" AS
SELECT
    *
    --Rozdělení dat do 4 skupin
    ,NTILE(4) OVER (ORDER BY TRY_CAST("Podil_preferencni_hlasy_zeny_obce" AS FLOAT)) AS "kvartil"
FROM (
    SELECT
        *
        -- Podíl preferenčních hlasů v obci
        ,CASE
            WHEN "Preferencni_hlasy_celkem_obce" = 0 THEN 0
            ELSE ("Pocet_preferencni_hlasy_zeny_obce" * 100.0) / "Preferencni_hlasy_celkem_obce"
        END AS "Podil_preferencni_hlasy_zeny_obce"
        
        ,CASE
            WHEN "Preferencni_hlasy_celkem_obce" = 0 THEN 0
            ELSE ("Pocet_preferencni_hlasy_muzi_obce" * 100.0) / "Preferencni_hlasy_celkem_obce"
        END AS "Podil_preferencni_hlasy_muzi_obce"
        --Vážené preferenční hlasy v obci
        ,CASE
            WHEN "Preferencni_hlasy_celkem_obce" = 0 THEN 0
            ELSE COALESCE(
                ( ("Pocet_preferencni_hlasy_zeny_obce" * 100.0) / NULLIF("pocet_kandidatek", 0) )
                /
                NULLIF( ( ("Pocet_preferencni_hlasy_muzi_obce" * 100.0) / NULLIF("pocet_kandidatu", 0) ), 0 )
            , 1.0)
        END AS "Vazene_preferencni_hlasy"
    FROM (
        SELECT
            "KodObec"
            ,SUM("HLASY") AS "Preferencni_hlasy_celkem_obce"
            ,SUM(CASE WHEN "POHLAVI" = 'ZENA' THEN "HLASY" ELSE 0 END) AS "Pocet_preferencni_hlasy_zeny_obce"
            ,SUM(CASE WHEN "POHLAVI" = 'ZENA' THEN 1 ELSE 0 END) AS "pocet_kandidatek"
            ,SUM(CASE WHEN "POHLAVI" = 'MUZ' THEN "HLASY" ELSE 0 END) AS "Pocet_preferencni_hlasy_muzi_obce"
            ,SUM(CASE WHEN "POHLAVI" = 'MUZ' THEN 1 ELSE 0 END) AS "pocet_kandidatu"
        FROM "2025_PS_vysledky_okrsky_hlasy_id_pohlavi"
        GROUP BY "KodObec"
    ) AS "preferencni_hlasy"
) AS "podily_preferencnich_hlasu";

--porovnání demografie a výsledků
Create or replace table "PorovnavaciTabulkaObce" as
SELECT
     "Preferencni_hlasy_obce"."KodObec"
    ,"Preferencni_hlasy_obce"."kvartil"
    ,"Preferencni_hlasy_obce"."Podil_preferencni_hlasy_zeny_obce"
    ,"Preferencni_hlasy_obce"."Vazene_preferencni_hlasy"
    ,"pocet_okrsku_demografie"."PocetOkrsku"::FLOAT AS "Pocetoksrku_Obec"
    ,"Volebni_ucast_obce"."VolebniUcastObce"::FLOAT as "VolebniUcastObce"
    --demografie
    ,"pocet_okrsku_demografie"."HUSTOTA_ZALIDNENI"::FLOAT as "HustotaZalidneni"
    ,"Obyvatelstvo-podle-veku---podil--0-az-14-let--2024"."Obyvatelstvo_podle_veku_0_az_14_let_2024"::FLOAT as "PodilObyvatel0_14"
    ,"Obyvatelstvo-podle-veku---podil--15-az-64-let"."Obyvatelstvo_podle_veku__podil_15_az_64_let_2024"::FLOAT as "PodilObyvatel15-65"
    ,"Obyvatelstvo-podle-veku---podil--65-a-vice-let--2024"."Obyvatelstvo65_a_vice_let_2024"::FLOAT as "PodilObyvatel65avice"
    ,"pocet_okrsku_demografie"."PrumVekCelkem"::FLOAT as "PrumernyVekCelkem"
    ,"pocet_okrsku_demografie"."PrumVekMuzi"::FLOAT as "PrumernyVekMuzi"
    ,"pocet_okrsku_demografie"."PrumVekZeny"::FLOAT as "PrumernyVekZeny"
    ,"Podil_vzdelani_obyvatele"."PodilBezVzdelani" as "PodilBezVzdelani"
    ,"Podil_vzdelani_obyvatele"."PodilZakladniVzdelani" as "PodilZakladniVzdelani"
    ,"Podil_vzdelani_obyvatele"."PodilVyuceni" as "PodilVyuceni"
    ,"Podil_vzdelani_obyvatele"."PodilStredniVzdelani" as "PodilStredoskolske"
    ,"Podil_vzdelani_obyvatele"."PodilVyssiOdborne" as "PodilVyssiOdborne"
    ,"Podil_vzdelani_obyvatele"."PodilVysokoskolske" as "PodilVysokoskolske"
    ,"Podil_vzdelani_obyvatele"."PodilNezjisteno" as "PodilVzdelaniNezjisteno"
    ,"Podil_vzdelani_obyvatele"."Podilzenyvysokoskolske" as "Podilzenyvysokoskolske"
	,"sociodemo_data_paq_joined_final"."NEZAMESTNANOST" as "NezamestnanostPodil"
    ,"sociodemo_data_paq_joined_final"."Dlouhodoba_nezamestnanost_2024" as "DlouhodobaNzamestnanostPodil"
    ,"RUD_spocitany"."RUD_celkem"::FLOAT as "RudCelkem"
    ,COALESCE("slbd_2021_ekonomaktiv"."vse6112"::FLOAT / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0),0) as "PodilEkonomickyAktivniMuzi2"
    ,COALESCE("slbd_2021_ekonomaktiv"."vse6113"::FLOAT / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilEkonomickyAktivniZeny"
    ,COALESCE("slbd_2021_ekonomaktiv"."vse6162"::FLOAT / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilPracujiciDuchodciMuzi"
    ,COALESCE("slbd_2021_ekonomaktiv"."vse6163"::FLOAT / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilPracujiciDuchodciZeny"
    ,COALESCE("slbd_2021_ekonomaktiv"."vse6173"::FLOAT / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilZenyNaMaterske"
    ,COALESCE("slbd_2021_ekonomaktiv"."vse6182"::FLOAT / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilNezamestnaniMuzi"
    ,COALESCE("slbd_2021_ekonomaktiv"."vse6183"::FLOAT / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilNezamestnaneZeny"
    ,COALESCE("slbd_2021_ekonomaktiv"."vse6192"::FLOAT / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilEkonomickyNeaktvniMuzi"
    ,COALESCE("slbd_2021_ekonomaktiv"."vse6193"::FLOAT / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilEkonomickyNeaktivniZeny"
    ,COALESCE("slbd_2021_ekonomaktiv"."vse61102"::FLOAT / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilNepracujiciDuchodciMuzi"
    ,COALESCE("slbd_2021_ekonomaktiv"."vse61103"::FLOAT / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilNepracujiciDuchodciZeny"
    ,COALESCE("slbd_2021_ekonomaktiv"."vse61111"::FLOAT / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilStudenti"
    ,COALESCE("slbd_2021_ekonomaktiv"."vse61121"::FLOAT / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilNezjisteno"
    ,COALESCE((COALESCE("slbd_2021_ekonomaktiv"."vse6112"::FLOAT, 0) + COALESCE("slbd_2021_ekonomaktiv"."vse6113"::FLOAT, 0)) / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilEkonomickyAktivniCelkem"
    ,COALESCE((COALESCE("slbd_2021_ekonomaktiv"."vse6162"::FLOAT, 0) + COALESCE("slbd_2021_ekonomaktiv"."vse6163"::FLOAT, 0)) / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilPracujiciDuchodciCelkem"
    ,COALESCE((COALESCE("slbd_2021_ekonomaktiv"."vse6182"::FLOAT, 0) + COALESCE("slbd_2021_ekonomaktiv"."vse6183"::FLOAT, 0)) / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilNezamestnaniCelkem"
    ,COALESCE((COALESCE("slbd_2021_ekonomaktiv"."vse6192"::FLOAT, 0) + COALESCE("slbd_2021_ekonomaktiv"."vse6193"::FLOAT, 0)) / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilEkonomickyNeaktvniCelkem"
   ,COALESCE((COALESCE("pocet_osob_exekuce"."exekuce"::FLOAT, 0) + COALESCE("slbd_2021_ekonomaktiv"."vse61103"::FLOAT, 0)) / NULLIF("pocet_okrsku_demografie"."CelkemObyvatel"::FLOAT, 0), 0) as "PodilOsobsexekuci"
     ,CASE
    	when "sociodemo_data_paq_joined_final"."Role_obce_na_predskolni_peci_2021" = 'data chybí' then 0
    	when "sociodemo_data_paq_joined_final"."Role_obce_na_predskolni_peci_2021" = 'Bezdětné' then 1
    	when "sociodemo_data_paq_joined_final"."Role_obce_na_predskolni_peci_2021" = 'Nedostatečné' then 2
    	when "sociodemo_data_paq_joined_final"."Role_obce_na_predskolni_peci_2021" = 'Závislé' then 3
    	when "sociodemo_data_paq_joined_final"."Role_obce_na_predskolni_peci_2021" = 'Spolupracující' then 4
    	when  "sociodemo_data_paq_joined_final"."Role_obce_na_predskolni_peci_2021" = 'Soběstačné' then 5
    	else 6
     end as "Role_obce_na_predskolni_peci"
    ,("sociodemo_data_paq_joined_final"."POCET_NAROZENYCH_DETI"*1000)/"sociodemo_data_paq_joined_final"."OBYVATELSTVO_POCET_2024" as "PodilNarozenychDetiNaTisicObyvatel"
,(("sociodemo_data_paq_joined_final"."PECOVATELAK"+"sociodemo_data_paq_joined_final"."STREDISKO_VOLNY_CAS"+"sociodemo_data_paq_joined_final"."DETSKE_HRISTE"+"sociodemo_data_paq_joined_final"."KULTURAK"+"sociodemo_data_paq_joined_final"."KINO"+"sociodemo_data_paq_joined_final"."KOSTEL")*1000)/"sociodemo_data_paq_joined_final"."OBYVATELSTVO_POCET_2024" as "VybaveniNaTisicObyvatelPAQ"
,(("RES_pocty_obce"."pocet_kadernictvi"::INT + "RES_pocty_obce"."pocet_knihovny_muzea"::INT + "RES_pocty_obce"."pocet_maloobchod"::INT + "RES_pocty_obce"."pocet_sport_rekreace"::INT + "RES_pocty_obce"."pocet_stravovani"::INT + "RES_pocty_obce"."pocet_umeni"::INT + "RES_pocty_obce"."pocet_verejna_sprava"::INT + "RES_pocty_obce"."pocet_vzdelavani"::INT + "RES_pocty_obce"."pocet_zdravotnictvi")*1000)/"pocet_okrsku_demografie"."CelkemObyvatel"::INT  as "VybaveniNaTisicObyvatelRes"
,
(("sociodemo_data_paq_joined_final"."PECOVATELAK"::INT+"sociodemo_data_paq_joined_final"."STREDISKO_VOLNY_CAS"::INT+"sociodemo_data_paq_joined_final"."DETSKE_HRISTE"::INT+"sociodemo_data_paq_joined_final"."KULTURAK"::INT+"sociodemo_data_paq_joined_final"."KINO"::INT+"sociodemo_data_paq_joined_final"."KOSTEL"::INT+"RES_pocty_obce"."pocet_kadernictvi"::INT + "RES_pocty_obce"."pocet_knihovny_muzea"::INT + "RES_pocty_obce"."pocet_maloobchod"::INT + "RES_pocty_obce"."pocet_sport_rekreace"::INT + "RES_pocty_obce"."pocet_stravovani"::INT + "RES_pocty_obce"."pocet_umeni"::INT + "RES_pocty_obce"."pocet_verejna_sprava"::INT + "RES_pocty_obce"."pocet_vzdelavani"::INT + "RES_pocty_obce"."pocet_zdravotnictvi"::INT)*1000)/"pocet_okrsku_demografie"."CelkemObyvatel"::INT  as "VybaveniNaTisicObyvatelCelkem" 
  	,("Pocty_skoly_nemocnice_zdravzar"."PocetVysokeSkoly"*1000)/"pocet_okrsku_demografie"."CelkemObyvatel"::INT as "PodilVysokychSkolNaTisicObyvatel"
    ,("Pocty_skoly_nemocnice_zdravzar"."PocetMaterskeSkoly"*1000)/"pocet_okrsku_demografie"."CelkemObyvatel"::INT as "PodilMaterskychSkolNaTisicObyvatel"
    ,("Pocty_skoly_nemocnice_zdravzar"."PocetZakladniSkoly"*1000)/"pocet_okrsku_demografie"."CelkemObyvatel"::INT as "PodilZakladnichSkolNaTisicObyvatel"
    ,("Pocty_skoly_nemocnice_zdravzar"."PocetStredniSkoly"*1000)/"pocet_okrsku_demografie"."CelkemObyvatel"::INT as "PodilStrednichSkolNaTisicObyvatel"
    ,("Pocty_skoly_nemocnice_zdravzar"."PocetZdravotnickychVybaveni"*1000)/"pocet_okrsku_demografie"."CelkemObyvatel"::INT as "PodilZravotnickychVybaveniNaTisicObyvatel"
    ,("Pocty_skoly_nemocnice_zdravzar"."PocetNemocnic"*1000)/"pocet_okrsku_demografie"."CelkemObyvatel"::INT as "PodilNemocnicNaTisicObyvatel"
FROM "Preferencni_hlasy_obce"
LEFT JOIN "pocet_okrsku_demografie" ON "pocet_okrsku_demografie"."KodObce" = "Preferencni_hlasy_obce"."KodObec"
LEFT JOIN "RUD_spocitany" ON "RUD_spocitany"."kod_obce" = "Preferencni_hlasy_obce"."KodObec"
LEFT JOIN "Volebni_ucast_obce" ON "Volebni_ucast_obce"."KodObec" = "Preferencni_hlasy_obce"."KodObec"
LEFT JOIN "sociodemo_data_paq_joined_final" ON "sociodemo_data_paq_joined_final"."Kod_obce" = "Preferencni_hlasy_obce"."KodObec"
LEFT JOIN "Pocty_skoly_nemocnice_zdravzar" ON "Pocty_skoly_nemocnice_zdravzar"."KodObec" = "Preferencni_hlasy_obce"."KodObec"
LEFT JOIN "RES_pocty_obce" ON "RES_pocty_obce"."KodObec" = "Preferencni_hlasy_obce"."KodObec"
LEFT JOIN "Obyvatelstvo-podle-veku---podil--0-az-14-let--2024" ON "Obyvatelstvo-podle-veku---podil--0-az-14-let--2024"."Kod_obce" = "Preferencni_hlasy_obce"."KodObec"
LEFT JOIN "Obyvatelstvo-podle-veku---podil--15-az-64-let" ON "Obyvatelstvo-podle-veku---podil--15-az-64-let"."Kod_obce" = "Preferencni_hlasy_obce"."KodObec"
LEFT JOIN "Obyvatelstvo-podle-veku---podil--65-a-vice-let--2024" ON "Obyvatelstvo-podle-veku---podil--65-a-vice-let--2024"."Kod_obce" = "Preferencni_hlasy_obce"."KodObec"
LEFT JOIN "Podil_vzdelani_obyvatele" ON "Podil_vzdelani_obyvatele"."KodObec" = "Preferencni_hlasy_obce"."KodObec"
LEFT JOIN "slbd_2021_ekonomaktiv" ON "slbd_2021_ekonomaktiv"."uzkod" = "Preferencni_hlasy_obce"."KodObec"
LEFT JOIN "pocet_osob_exekuce" on "pocet_osob_exekuce"."KodObec" = "Preferencni_hlasy_obce"."KodObec"