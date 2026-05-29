# Výpočet rozpočtového určení daní pro jednotlivé obce
# Tabulka z Ministerstva financí určující procentní podíly byla ve formátu xlsx a nezačínala na první řádku a měla hodně nadpisů a součených buněk
# Velmi velká variabilita datových typů. 

import pandas as pd
df = pd.read_excel('2025-09-01_Priloha-k-vyhlasce-c-301-2005-Sb.xlsx', header=13, nrows=6254)  # načte 13. řádek jako hlavičku

for col in [5, 6, 7, 9, 10, 11]:
    df[col] = df[col].astype(str).str.replace(',', '.').astype(float)

# NÁZVY SLOUPCŮ BEZ UVOZOVEK, JSOU TO ČÍSLA NE STRINGY!!!
#print(df.columns.tolist())

# E7 DPH                                       623,1 mld. Kč
# E9 DPPO (bez WFT)                            333,0 mld. Kč
# E10 DPFO celkem                              290,1 mld. Kč
# E11 — z toho srážková                        44,8 mld. Kč
# E12 — z toho placená plátci (závislá činnost)223,4 mld. Kč
# E13 — z toho placená poplatníky (OSVČ)       21,9 mld. Kč

DPH = 623_100_000_000
DPPO = 332_990_000_000
DPFO_platci = 223_400_000_000
DPFO_srazka = 44_780_000_000
DPFO_poplatnici = 21_880_000_000

# 1. DPH + DPFO ze závislé činnosti (plátci) + DPPO
# DPH + DPPO + DPFO placená plátci + DPFO srážková) × 24,16 % × procentní podíl obce

slozka_1 = (DPH + DPPO + DPFO_platci + DPFO_srazka) * 0.2416 * (df[9]/100)


# 2. DPFO ze závislé činnosti — motivační složka
# celostátní výnos DPFO ze závislé činnosti × 1,5 % × (počet zaměstnanců na území obce / celkový počet zaměstnanců v ČR)

slozka_2 = DPFO_platci * 0.015 * (df[11]/100)


# 3. DPFO z přiznání (OSVČ a ostatní poplatníci)
# celostátní výnos DPFO placená poplatníky (OSVČ) × 30 %  × (počet obyvatel obce / celkový počet obyvatel ČR)

slozka_3 = DPFO_poplatnici * 0.30 * (df[5]/df[5].sum())

RUD_spocitany = df[[1, 2, 3, 4]].copy()  # sloupce které chceš zachovat

RUD_spocitany["slozka_1"] = slozka_1
RUD_spocitany["slozka_2"] = slozka_2
RUD_spocitany["slozka_3"] = slozka_3
RUD_spocitany["RUD_celkem"] = slozka_1 + slozka_2 + slozka_3

RUD_spocitany[4]=RUD_spocitany[4].astype("Int64")
RUD_spocitany = RUD_spocitany.rename(columns={1: "kraj", 2: "okres", 3: "obec", 4: "KodObec"})

# uložit celé do RUD_spocitany.csv
RUD_spocitany.to_csv("RUD_spocitany.csv", index=False, sep=',')

