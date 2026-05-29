import pandas as pd
from pyproj import Transformer

skoly = pd.read_csv("ZS_MS.csv", low_memory=False)

nazev_zarizeni = ["Mateřská škola","Základní škola","Základní umělecká škola","Školní družina","Školní klub", "Střední škola","Dům dětí a mládeže","Konzervatoř","Školní knihovna","Vyšší odborná škola","Domov mládeže","Jazyková škola s právem státní jazykové zkoušky","Stanice zájmových činností","Plavecká škola","Středisko volného času"]
ZS_MS_SS_krouzky = skoly[skoly["Název"].isin(nazev_zarizeni)].copy()
ZS_MS_SS_krouzky["Místo - Kód RÚIAN"] = ZS_MS_SS_krouzky["Místo - Kód RÚIAN"].astype("Int64")

# načti okrsky se souřadnicemi
okrsky = pd.read_csv("vystup/spojeny_okrsky.csv", low_memory=False)
okrsky["Kód ADM"] = okrsky["Kód ADM"].astype("Int64")
okrsky["Kód obce"] = okrsky["Kód obce"].astype("Int64")
okrsky["Číslo volebního okrsku"] = okrsky["Číslo volebního okrsku"].str.extract(r"^(\d+)")
okrsky["Číslo volebního okrsku"] = okrsky["Číslo volebního okrsku"].astype("Int64")

# oprava kódu obce pro Prahu a Brno přes lookup tabulku
lookup = pd.read_csv("obce_kraje.csv")
lookup["OBEC"] = lookup["OBEC"].astype("Int64")
okrsky = okrsky.merge(lookup[["OBEC", "OBEC_PREZ"]], left_on="Kód obce", right_on="OBEC", how="left")
okrsky["OBEC_PREZ"] = okrsky["OBEC_PREZ"].fillna(okrsky["Kód obce"])
okrsky = okrsky.rename(columns={"OBEC_PREZ": "KodObec"})

okrsky["IdOkrsek"] = okrsky["KodObec"].astype("Int64").astype(str) + okrsky["Číslo volebního okrsku"].astype(str).str.zfill(4)

# souřadnice převést na číslo a delimiter . místo ,
okrsky["Souřadnice Y"] = okrsky["Souřadnice Y"].str.replace(",", ".").astype(float)
okrsky["Souřadnice X"] = okrsky["Souřadnice X"].str.replace(",", ".").astype(float)

# merge - souřadnice + IdOkrsek + KodObec v jednom kroku
ZS_MS_SS_krouzky = ZS_MS_SS_krouzky.merge(
    okrsky[["Kód ADM", "Souřadnice Y", "Souřadnice X", "IdOkrsek", "KodObec"]],
    left_on="Místo - Kód RÚIAN",
    right_on="Kód ADM",
    how="left"
)

# převod Křováka na WGS84
transformer = Transformer.from_crs("EPSG:5514", "EPSG:4326", always_xy=True)
ZS_MS_SS_krouzky["lon"], ZS_MS_SS_krouzky["lat"] = transformer.transform(
    -ZS_MS_SS_krouzky["Souřadnice X"].values,
    -ZS_MS_SS_krouzky["Souřadnice Y"].values
)

# pivot_table - počty zařízení dle obce (PŘED dropem!)
pocty = ZS_MS_SS_krouzky.groupby(["KodObec", "Název"])["RED_IZO"].count().reset_index()
pocty = pocty.pivot_table(index="KodObec", columns="Název", values="RED_IZO", fill_value=0).reset_index()
pocty.columns.name = None

# uložit
pocty.to_csv("ZS_MS_SS_krouzky_obce.csv", sep=",", index=False, encoding="utf-8")

