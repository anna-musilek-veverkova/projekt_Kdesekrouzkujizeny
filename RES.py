# Registr ekonomických subjetků
# Výběr subjektů z relevantních NACE kategorií
# Přiřazení kódu obce před kód adresního místa, který je i v základní tabulce o geolokaci volební okrsků
# Rozřazení subjektů do kategorií a vypočítání jejich počtů v daných kategoriích na obec
# Do indexu občanské vybavenosti vstupuje jako jedno číslo reflektující celkové množství subjektů poskytující služby v dané obci 

import pandas as pd
import re

df = pd.read_csv("res_data.csv", sep=",", encoding="utf-8")

# vyfiltrování zaniklých subjektů a odstranění těch které vznikly v roce 2026
df = df[
    (df["DDATVZN"] < '2026-01-01') &
    (df["DDATZAN"].isna() | (df["DDATZAN"] > '2025-01-01'))
]

# vybrané sloupce

df = df [["NACE",
"NACE2025",
"KODADM",
"DDATVZN",
"DDATZAN",
"ICZUJ",
"FIRMA",
"TEXTADR",
"PSC",
"OBEC_TEXT",
"COBCE_TEXT",
"ULICE_TEXT",
"TYPCDOM",
"CDOM",
"COR"]]

# filtr NACE 
nace_filtry = [
    r'47[1-6]', # maloobchod (potraviny,phm, atp.)
    r'56[1-9]', # Poskytování stravování a podávání nápojů
    r'85[1-9]', # vzdělávání - zš, sš, mš, zuš, vš, autoškoly atd.
    r'86[1-9]', # zdravotní péče - lůžková, ambulatní, zubní
    r'84[1-9]', # Veřejná správa a obrana; povinné sociální zabezpečení
    r'90[1-9]', # Umělecká tvorba a činnosti v oblasti scénických umění
    r'91[1-9]', # knihovny, muzea, kulturní zaříení, zoo atp.
    r'93[1-9]', # sportu, zábavy a rekreace
    r'96[1-9]' # Kadeřnické a kosmetické činnosti, činnosti denních lázní,
]
pattern = r'^(' + '|'.join(nace_filtry) + r')'

# kontrola regexu v obou sloupcích
df = df[
    df["NACE"].astype(str).str.match(pattern) |
    df["NACE2025"].astype(str).str.match(pattern)
]

# úprava datového typu kodadm
df["KODADM"] = df["KODADM"].astype("Int64")

# přes KODADM přidání kódu obce a čísla volebního okrsku a vytvoření IdOkrsek
okrsky = pd.read_csv("vystup/spojeny_okrsky.csv", low_memory=False)
okrsky["Kód ADM"] = okrsky["Kód ADM"].astype("Int64")
okrsky["Kód obce"] = okrsky["Kód obce"].astype("Int64")
okrsky["Číslo volebního okrsku"] = okrsky["Číslo volebního okrsku"].str.extract(r"^(\d+)")
okrsky["Číslo volebního okrsku"] = okrsky["Číslo volebního okrsku"].astype("Int64")

lookup = pd.read_csv("obce_kraje.csv")
lookup["OBEC"] = lookup["OBEC"].astype("Int64")

okrsky = okrsky.merge(lookup[["OBEC", "OBEC_PREZ"]], left_on="Kód obce", right_on="OBEC", how="left")
okrsky["OBEC_PREZ"] = okrsky["OBEC_PREZ"].fillna(okrsky["Kód obce"])
okrsky = okrsky.rename(columns={"OBEC_PREZ": "KodObec"})

okrsky["IdOkrsek"] = okrsky["KodObec"].astype("Int64").astype(str) + okrsky["Číslo volebního okrsku"].astype(str)


# merge - souřadnice + IdOkrsek v jednom kroku
res = df.merge(
    okrsky[["Kód ADM", "IdOkrsek", "KodObec"]],
    left_on="KODADM",
    right_on="Kód ADM",
    how="left"
)
# vyhodit nadbytečený sloupce a IdOkrsek dát na záčátek
res = res.drop(columns=["Kód ADM"])
res = res[["IdOkrsek"] + [c for c in res.columns if c != "IdOkrsek"]]

res.to_csv("RES_IdOkrsek.csv", sep=",", index=False, encoding="utf-8-sig")

# mapování NACE prefix -> název kategorie
def nace_kategorie(row):
    nace = str(row["NACE2025"]) if pd.notna(row["NACE2025"]) else str(row["NACE"])  # <- sem
    if re.match(r'^47[1-6]', nace): return 'maloobchod'
    if re.match(r'^56', nace): return 'stravovani'
    if re.match(r'^85', nace): return 'vzdelavani'
    if re.match(r'^86', nace): return 'zdravotnictvi'
    if re.match(r'^84', nace): return 'verejna_sprava'
    if re.match(r'^90', nace): return 'umeni'
    if re.match(r'^91', nace): return 'knihovny_muzea'
    if re.match(r'^93', nace): return 'sport_rekreace'
    if re.match(r'^96', nace): return 'kadernictvi'
    return 'jine'

res["kategorie"] = res.apply(nace_kategorie, axis=1)

# počty v kategoriích na OKRSEK
pocty = res.groupby(["IdOkrsek", "kategorie"]).size().unstack(fill_value=0)
pocty.columns = [f"pocet_{col}" for col in pocty.columns]
pocty = pocty.reset_index()

pocty.to_csv("RES_pocty_okrsky.csv", sep=",", index=False, encoding="utf-8-sig")

# počty v kategoriích na OBEC
pocty_obec = res.groupby(["KodObec", "kategorie"]).size().unstack(fill_value=0)
pocty_obec.columns = [f"pocet_{col}" for col in pocty_obec.columns]
pocty_obec = pocty_obec.reset_index()
pocty_obec["KodObec"] = pocty_obec["KodObec"].astype("Int64").astype(str)

pocty_obec.to_csv("RES_pocty_obce.csv", sep=",", index=False, encoding="utf-8-sig")

print("Hotovo!")