# Generátor bludišť - Dokumentace

## Stručný popis
Program slouží ke generování obdelníkových bludišť na základě uživatelem zadaných parametrů. 

## Uživatelský popis
Program se postupně ptá na následující parametry, které musí uživatel zadat:
1. Výška bludiště 
2. Šířka bludiště
3. Větvící faktor 
4. Relativní množství možných cest bludištěm od 0 do 100 včetně

Na základě těchto parametrů program vytiskne pseudonáhodně vygenerované bludiště.

### Větvící faktor
Číslo od 0 včetně do 100 včetně. 

Určuje, jak moc bude se bude bludiště větvit. Od 0 do cca 70 platí, že čím je tento faktor větší, tak tím více se bludiště větví. Pokud je však hodnota příliš velká (například 100), tak se naopak bludiště tolik nevětví. (důvod popisuji v sekci Algoritmus)

### Relativní četnost cest bludištěm
Číslo od 0 včetně do 100 včetně. 

Určuje v relativních číslech od 0 do 100, kolik bude existovat možných cest bludištěm od začátku do konce. 
0 - pouze jedna jediná cesta
100 - maximální možné množství cest od začátku do konce

## Algoritmus
Program provádí poupravené vytváření náhodné kostry grafu. Bludiště vznikne tak, že hrany vytvořené kostry bereme jako cesty v bludišti a dle toho ten graf náležitě vytiskneme. Kostra nám zaručí tu vlastnost, že bludištěm povede právě jedna cesta (kostra nemá cykly) a zároveň bude existovat cesta do každého políčka bludiště (kostra spojuje všechny vrcholy do souvislého grafu).

Konkrétněji algoritmus začne s prázdným grafem bez hran a postupně se snaží přidávat hrany, které nevytvoří cyklus. Hrany se snaží přidávat podle toho, jak je nachází ve své frontě, která obsahuje potenciální hrany na přidání do grafu.

Algoritmus je však upravený tím způsobem, aby bylo možné nastavit poměr mezi tím, kolik vrcholů vkládám při prohledávání vrcholů na začátek a kolik na konec fronty. To nám pak efektivně určuje, kolik křižovatek bude graf mít: 
1. Pokud vkládám vždy na začátek fronty, tak provádím prohledávání do hloubky a bludiště se nebude tolik větvit.
2. Pokud naopak vkládám občas i na konec fronty, tak se může stát. Že při vytváření části kostry se zastavím a začnu odjinud, čímž vznikne křižovatka (pokud nově vybraný vrchol není koncový a má kolem sebe nějaké nenavštívené sousedy).

POZOR: Pokud je vkládám vždy na konec fronty, tak provádím čisté bfs a poté sice začínám v každém kroku od jiných vrcholů, ale vždy se mi stává, že beru ty koncové, takže křižovatky nevytvářím. Proto tento parametr ideálně nesmí být příliš vysoký.

Druhá úprava algoritmu je taková, že mohu ovládat procentuální šanci, že pokud vidím hranu, která by vytvořila cyklus, tak ji přidám i tak, čímž zničím pravidlo acykličnosti a vytvořím tím další možnou cestu, jak projít bludištěm.

## Kód

Program jsem rozdělil na 7 následujících částí:
1. IMPORTS
2. DATA STRUCTURES AND TYPE SYNONYMS
3. MAZE GENERATION
4. STRUCTURES HELPER FUNCTIONS
5. SHOWING
6. RANDOM NUMBERS
7. MAIN

Níže popíši jednotlivé části blíže.

### IMPORTS
Tato část obsahuje příkazy pro přidání knihoven, které v programu používám. Knihovna `Debug.Trace` není použita přímo, ale ve funkci `mazeSearch` mám schovaný komentář, který při odkomentování umožňuje postupně tisknout jednotlivé kroky, během kterých se generuje bludiště. Knihovna `System.IO` zase slouží k čtení vstupu od uživatele.

### DATA STRUCTURES AND TYPE SYNONYMS
Obsahuje definice důležitých typů, jako je vrchol, hrana a graf. Nějaké z typů pak implementují různé typové třídy, většinou pomocí výchozí implementace. Rozdílem je implementace rovnosti na hranách, která ignoruje směr hrany.

### MAZE GENERATION
To je hlavní algoritmická část programu. Zde se nachází samotný algoritmus vytváření kostry `mazeSearch` a některé pomocné funkce, které tento algoritmus používá. Mezi takové funkce spadá například kontrola, zda vrchol pro daný graf je uvnitř tohoto grafu (je validní) `isValid` nebo funkce, která vrátí všechny sousedy daného vrcholu `neighbors`. Důležitá je také funkce `addEdge`, která grafu přidá hranu mezi zadanými vrcholy.

### STRUCTURES AND HELPER FUNCTIONS
Zde se nachází pomocné funkce, které nejsou klíčové k tomu, aby algoritmus fungoval, ale nějakým způsobem ulehčují čitelnost kódu. Nachází se zde například převody z vestavěných typů na ty mé grafové typy `toNode` a `toEdge`. Dále pomocné funkce na vytváření prázdného grafu, což je vlastně bludiště bez proražených zdí `emptyGraph`. Nakonec se zde nachází funkce, které přidají vchod a východ a mají tedy pro program pouze kosmetický význam `addExitEdge` a `addEntranceEdge`.

### SHOWING
Slouží k tisknutí vnitřní algoritmické reprezentace grafu na uživatelsky přívětivou verzi. Pomocí funkcí, které nemají vstup jsem si zavedl konstanty pro prázdné políčko a pro políčko se zdí `wall` a `blank`. Vrcholy samy o sobě vlastně v našem bludišti už od počátku představují prázdná políčka a tento fakt se v průběhu programu nemění. Důležité jsou hrany, které určují, mezi jakými těmito volnými políčky bude zeď proražená a kde ne. Pro každý řádek vnitřní reprezentace grafu tisknu vždy dva řádky textové reprezentace grafu. První řádek tiskne dutiny odpovídající vrcholům a hrany, které se nachází mezi vrcholy ve stejné vrstvě. Druhý řádek pak tiskne hrany, které se nacházejí mezi tímto řádkem vnitřní reprezentace grafu a tím řádkem pod ním ve vnitřní reprezentaci grafu.

### RANDOM NUMBERS
Zde se nachází kód pro generování náhodných čísel vypůjčený od pana doc. RNDr. Tomáše Dvořáka, CSc. Dále se zde nachází funkce, které pak tento kód využívají na náhodné rozdělování prvků do dvou podmnožin `splitRand` a funkce pro zamíchání pořadí seznamu `shuffle`, které využívá hlavní algoritmus, pokud objeví hranu do vrcholu, který ještě nebyl navštíven. Naopak funkce `addEdgeMaybe` slouží, aby v určitých případech mohlo nastat, že přidáme hranu i pokud už její přidání vytvoří v naší dosavadní kostře (nebo už nekostře) cyklus.

### MAIN
Zde se nachází část kódu, která umožňuje, že je program spustitelný a čte od uživatele počáteční parametry bludiště na vstupu.
