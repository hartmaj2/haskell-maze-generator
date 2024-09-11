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

Určuje, jak moc bude program větvit. Od 0 do cca 70 platí, že čím je tento faktor větší, tak tím více se bludiště větví. Pokud je však hodnota příliš velká (například 100), tak se naopak bludiště tolik nevětví. (proč popisuji v sekci Algoritmus)

### Relativní četnost cest bludištěm
Číslo od 0 včetně do 100 včetně. 

Určuje v relativních číslech od 0 do 100, kolik bude existovat možných cest bludištěm od začátku do konce. 
0 - pouze jedna jediná cesta
100 - maximální možné množství cest od začátku do konce

## Algoritmus
Program provádí poupravené vytváření náhodné kostry grafu. Bludiště vznikne tak, že hrany vytvořené kostry bereme jako cesty v bludišti a dle toho ten graf náležitě vytiskneme. Kostra nám zaručí tu vlastnost, že bludištěm povede právě jedna cesta (kostra nemá cykly) a zároveň bude existovat cesta do každého políčka bludiště (kostra spojuje všechny vrcholy do souvislého grafu).

Konkrétněji algoritmus začne s prázdným grafem bez hran a postupně se snaží přidávat hrany, které nevytvoří cyklus. Hrany se snaží přidávat podle toho, jak je nachází ve své frontě, která obsahuje potenciální hrany na přidání do grafu.

Algoritmus je však upravený tím způsobem, aby se dal ovládat poměr mezi tím, kolik vrcholů vkládám při prohledávání vrcholů na začátek a kolik na konec fronty. To nám pak efektivně určuje, kolik křižovatek bude graf mít: 
1. Pokud vkládám vždy na začátek fronty, tak provádím prohledávání do hloubky a bludiště se nebude tolik větvit.
2. Pokud naopak vkládám občas i na konec fronty, tak se může stát. Že při vytváření části kostry se zastavím a začnu odjinud, čímž vznikne křižovatka (pokud nově vybraný vrchol není koncový a má kolem sebe nějaké nenavštívené sousedy).

POZOR: Pokud je vkládám vždy na konec fronty, tak provádím čisté bfs a poté sice začínám v každém kroku od jiných vrcholů, ale vždy se mi stává, že beru ty koncové, takže křižovatky nevytvářím. Proto tento parametr ideálně nesmí být příliš velký.

Druhá úprava algoritmu je taková, že mohu ovládat procentuální šanci, že pokud vidím hranu, která by vytvořila cyklus, tak ji přidám i tak, čímž zničím pravidlo acykličnosti a vytvořím tím další možnou cestu, jak projít bludištěm.

## Kód

Program jsem si rozdělil na 7 následujících částí:
1. IMPORTS
2. DATA STRUCTURES AND TYPE SYNONYMS
3. MAZE GENERATION
4. STRUCTURES HELPER FUNCTIONS
5. SHOWING
6. RANDOM NUMBERS
7. MAIN

Níže popíši jednotlivé části blíže.

### Imports
Tato část obsahuje příkazi pro přidání knihoven, které v programu používám.