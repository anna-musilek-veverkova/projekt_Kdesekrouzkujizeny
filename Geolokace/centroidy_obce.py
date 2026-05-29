# Určení středu obcí pro zobrazení na mapě

import geopandas as gpd

gdf_obce = gpd.read_file("C:/Users/AnnaMusílek/Desktop/1/OBCE_P.shp")
print(gdf_obce.crs)
print(gdf_obce.columns.tolist())
#print(gdf_obce.head())

gdf_obce = gdf_obce.to_crs("EPSG:4326")
gdf_obce["lon"] = gdf_obce.geometry.centroid.x
gdf_obce["lat"] = gdf_obce.geometry.centroid.y

result = gdf_obce[["KOD", "NAZEV", "lat", "lon"]].rename(columns={"KOD": "KodObce"})
result.to_csv("centroidy_obce.csv", index=False, encoding="utf-8-sig")
print(result.head())
