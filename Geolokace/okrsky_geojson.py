# určení středu každého okrsku
# vytvoření IdOkrsek

import geopandas as gpd
import pandas as pd

# okrsky geolokace a vytvoření IdOkrsek
okrsky = gpd.read_file("vol_okrsky_2025_20250701.geojson")

# určení centroidu a převod Křovákova zobrazení na GPS
okrsky["lon"] = okrsky.geometry.centroid.to_crs("EPSG:4326").x
okrsky["lat"] = okrsky.geometry.centroid.to_crs("EPSG:4326").y

#vytvoření IdOkrsek a zařazení sloupce na začátek souboru
okrsky["cislo"] = okrsky["cislo"].astype(str)
okrsky.insert(0, "IdOkrsek", okrsky["kod_obec"] + okrsky["cislo"])

#přejmenovat sloupec s obcí a počtem obyvatel
okrsky = okrsky.rename(columns={"kod_obec": "KodObec"})
okrsky = okrsky.rename(columns={"pobyosl21": "poc_obyv"})

# drop nepotřebný columns
okrsky = okrsky.drop(columns=["OBJECTID","kod","platiod", "pocadr", "vymera", "shape_Length", "shape_Area", "geometry"])

#uložit do csv
okrsky.to_csv("okrsky_geolokace_FINAL_FINAL.csv", sep=";", decimal=".", index=False, encoding="utf-8-sig")

print("It's done done done!")