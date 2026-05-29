# Určení počtu zařízení poskytující zdravotnickou péči v jednotilvých obcích a volebních okrscích.
# Ve výsledku uloženy zvlášť typy, které jsou zahrnuty v idexu občanské vybavenosti.
# Příslušnost zdravotnických zařízení v daných obcích a volebních okrscích bylo nutné určit přes polygony obcí.

# přes GPS protáhnout polygony a přiřadit kod obce a IdOkrsek

import pandas as pd 
import geopandas as gpd
from shapely.geometry import Point
import re

df = pd.read_csv("mista-poskytovani-zdravotnich-sluzeb.csv", low_memory=False)

# vybrat pouze relevantní sloupce
ZZ = df [["ZZ_ID","ZZ_kod","ZZ_nazev","ZZ_druh_kod","ZZ_druh_nazev","ZZ_ORP_kod","ZZ_obec","ZZ_PSC","ZZ_ulice","ZZ_cislo_domovni_orientacni","ZZ_RUIAN_kod","ZZ_GPS"]]

# Extrakce souřadnic z formátu POINT(lat lon) do sloupců ZZ_lat a ZZ_lon
ZZ[["ZZ_lat", "ZZ_lon"]] = ZZ["ZZ_GPS"].str.extract(r'POINT\((\d+\.\d+)\s+(\d+\.\d+)\)')
ZZ = ZZ.drop(columns=["ZZ_GPS"])

# přes GPS přiřadit polygony a přiřadit kod obce a IdOkrsek
gdf = gpd.read_file("C:/Users/AnnaMusílek/Desktop/1/VO_P.shp")

gdf = gdf.to_crs("EPSG:4326") #převedení křováka na gps!!

ZZ = gpd.GeoDataFrame(ZZ, geometry=gpd.points_from_xy(ZZ.ZZ_lon, ZZ.ZZ_lat), crs="EPSG:4326")

vysledek = gpd.sjoin(ZZ, gdf[["CISLO", "OBEC_KOD", "geometry"]], how="left", predicate="within")
lookup = pd.read_csv("obce_kraje.csv")

vysledek["OBEC_KOD"] = vysledek["OBEC_KOD"].astype("Int64")
lookup["OBEC"] = lookup["OBEC"].astype("Int64")

vysledek = vysledek.merge(lookup[["OBEC", "OBEC_PREZ"]], left_on="OBEC_KOD", right_on="OBEC", how="left")
vysledek["OBEC_PREZ"] = vysledek["OBEC_PREZ"].fillna(vysledek["OBEC_KOD"])
vysledek = vysledek.rename(columns={"OBEC_PREZ": "KodObec"})
vysledek["KodObec"] = vysledek["KodObec"].fillna(vysledek["OBEC_KOD"])
vysledek.insert(0, "KodObec", vysledek.pop("KodObec"))
vysledek.insert(0, "IdOkrsek", vysledek["KodObec"].astype("Int64").astype(str) + vysledek["CISLO"].astype(str).str.zfill(4))
vysledek["KodObec"] = vysledek["KodObec"].astype("Int64")

vysledek = vysledek[vysledek["OBEC_KOD"].notna()] # vyfiltrovat jen ty s přiřazeným okrskem

#uložit VSECHNA ZZ do csv
vysledek.to_csv("zdravotnicka_zarizeni_all.csv", sep=",", index=False, encoding="utf-8")

# uložit do csv důležité pro občasnkou vybavenost
vybrane_typy = ["Samostatná ordinace PL - stomatologa","Poskytovatel amb. služeb (nad 5 oborů)","Lékárna", "Samost. ordinace všeob. prakt. lékaře", "Poskytovatel amb. služeb (do 5 oborů)", "Centrum komplexní péče o děti", "Sam.ord.prakt.lékaře pro děti a dorost", "Zařízení závodní preventivní péče", "Samostatná ordinace PL - gynekologa"]
ZZ_vybavenost = vysledek[vysledek["ZZ_druh_nazev"].isin(vybrane_typy)]
ZZ_vybavenost.to_csv("zdravotnicka_zarizeni_vybavenost.csv", sep=",", index=False, encoding="utf-8")

# uložit do csv nemocnice
nemocnice = ["Fakultní nemocnice","Nemocnice", "Specializovaná nemocnice", "Zdravotnické středisko"]
ZZ_nemocnice = vysledek[vysledek["ZZ_druh_nazev"].isin(nemocnice)]
ZZ_nemocnice.to_csv("zdravotnicka_zarizeni_nemocnice.csv", sep=",", index=False, encoding="utf-8")

print("Hotovo!")

