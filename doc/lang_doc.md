## Inledning

EzPz är skapat som ett enkelt språk och försöker följa talspråk vilket gör det väldigt lätt att lära sig och förstå logiken bakom programmering. Språket har även ett slag av humor inbyggt för att göra det första intrycket av programmering kul och intressant.

Processen för att skapa detta språk har varit fylld av motgångar baserade i bristande kunskap och dålig tidsplanering.

Språket är skapat under kursen TDP019 av Niklas Åsberg och Emilia Michanek.

Detta dokument är i tre delar, användarmanual, ett systemdokument och själva koden som utgör språket.

Målgruppen är alla som vill lära sig programmera på ett enkelt och smidigt sätt.


## Användarmanual

För att förstå EzPz kommer vi jämföra mycket med Ruby.


### Tilldelning

Alla tilldelningar sker med operatorn "<<" som fungerar som ett enkelt lika med tecken i Ruby i.e. "=". Alla variabel namn börjar med "@" och får använda bokstäver och siffror.

```
@banan << "frukt"
@siffra << 7
```


### Kontrollsatser

kontrollsatserna är ganska kreativa, den första ("if") är betecknad som "(<uttryck>)?" dvs ett uttryck följt av ett frågetecken. och kodblocket som följer avslutas med ett utropstecken. nästa ("else if") är betecknad som "(<uttryck>)?!" dvs ett utryck som följs av ett frågetecken och ett utropstecken och kodblocket som följer avslutas även det med ett utropstecken. och sista ("else") är ytterligare ett kodblock som avslutas med ett utropstecken.

Vår tanke med dessa kontrollsatser var som om någon skulle fråga: (är detta ditt uttryck)? och om det inte var det så säger den till lite argare: (är detta ditt uttryck)?! och på else-satsen: Då är det här ditt uttryck!

```
(a = 3)?
@banan << 3!
(a = 4)?!
@banan << 4
@fisk << 5!
@banan << "tom"!
```


### Flödeskontroll

Flödeskontrollen i detta språk är väldigt kreativ, vi har endast en while-loop, som betecknas med "(<uttryck>)∞" och sen ett kodblock om avslutas med ett utropstecken. Koden inom kodblocket upprepas tills uttrycket inom parenteserna inte längre är sant.

```
(a < 3)∞
    a << a + 1!
```


### Logiska grindar

De logiska grindarna vi har är or(|), and(&) och not(#) och fungerar som logiska grindar ska göra.

```
True | False
True & True
#True
```


### Booleska uttryck

alla uttryck har vi satt inom parenteser,
de booleska operatorer vi har är större än (>) mindre än (<) större än eller lika med (>=) mindre än eller lika med (<=) lika med (=) inte lika med (=/=)

```
(1 = 1)
(3 <= 3)
(2 < 8)
(4 > 3)
(5 >= 13)
(3 =/= 5)
```


### Matematiska operatorer

de matematiska vi har addition(+), subtraktion(-), division(/), multiplikation(*), modulo(%%) och exponenter(^).

```
1 + 1
5 - 4
2 ^ 3
4 / 2
5 %% 2
3 * 4
```


### Funktioner

I detta språk har vi även funktioner, funktionerna fungerar som i många andra språk fast våran börjar alltid med ett $ och har argumenten innan funktionsnamnet, och koden i funktionen avslutas med ett utropstecken.

```
(argument)$func_namn
    kod_innuti_funktion!
```


### Scopes

Vi använder scopes som beter sig så att man kan läsa variablerna som är deklarerade i samma scope eller över men inte de scopen som är deklarerade under.


## Systemdokumentation

EzPz är bygd med hjälp av en utökad RDParse där vi har tagit inspiration från bl.a. Python och Ruby. Språket består av fyra filer, "rdparse.rb", där parsern finns, "node.rb", där alla noder finns, och "main.rb", där vi skapar ett nytt parser objekt som sedan används för den lexikaliska analysen när vi kör ett program.

EzPz är anpassat för nybörjare och försöker ha likt humor och intressanta lösningar inbyggt.

### Lexikalisk analys (lista på tokens)

* `token(/\s+/)` | Tar bort "tomma" tecken så som tabbar, blanksteg och nya rader.
* `token(/-?((0|[1-9]\d*)\.\d*[1-9])/)` | Hanterar decimaltal, positiva som negativa.
* `token(/-?(0|[1-9]\d*)/)` | Hanterar heltal, positiva som negativa.
* `token(/[a-zA-ZåäöÅÄÖ0-9_]+/)` | Hanterar tillåtna karaktärer i t.ex. variabelnamn.
* `token(/".*?"/)` | Hanterar strängar inom citattecken.
* `token(/(&|\|)/)` | Hanterar "och" samt "eller" operatorerna.
* `token(/<</)` | Hanterar tilldelningstecken.
* `token(/#/)` | Hanterar negationstecken.
* `token(/(\+|-)/)` | Hanterar plus- och minustecken.
* `token(/(\*|\/|%%|\^)/)` | Hanterar gånger, "delat med", modulo, samt "upphöjt till".
* `token(/@/)` | Hanterar snabel a.
* `token(/(<=|>=)/)` | Hanterar "mindre än eller lika med", samt "större än eller lika med".
* `token(/(=\/=|=)/)` | Hanterar "inte lika med" samt "lika med".
* `token(/(\)\?!|\)\?|\)∞|\)\$)/)` | Hanterar if, elseif, while, samt funktionstecken.
* `token(/!/)` | Hanterar end-tecken.
* `token(/(<|>)/)` | Hanterar "mindre än" och "större än".
* `token(/\(|\)|,/)` | Hanterar parenteser och kommatecken.
* `token(/(True|False)/)` | Hanterar booleska värden.

### Parsning

Då vi använder oss av RDParse har vi satt upp en antal regler (rules) efter den BNF-grammatik som vi jobbat på tidigare i kursen. Med dessa regler kan vi nu matcha lextokens mot vad det nu är vi vill matcha mot, t.ex. en if-sats. Till varje "match"-funktion skickar vi ett kodblock där standardregeln är att vi skapar och skickar tillbaka en ny nod av någon typ. De flesta noder är någon typ av statement, t.ex. en variabeldeklaration, ett variabelanrop, en if-sats, m.m., och kommer när den skickas upp hamna i andra noder, och på så sätt byggs vårt abstrakta syntaxträd upp.


### Evaluering

Evalueringen sker genom att trigga eval funktionen på rotnoden "program". Denna kommer sedan iterera över alla statements i programmet och kalla på deras eval-funktioner. Eftersom alla noder har en eval-metod implementerad kommer programmet tillslut komma till de yttersta komponenterna, sådana komponenter som faktiskt håller i värden så som heltal, flyttal, och strängar. När detta sker kommer de returnera sina resultat upp i trädet och beräkningar kommer ske.


### Installation

För att kunna köra språket krävs Ruby-version `1.9.3-p551`. Språket har ej testats på andra versioner, så vi kan inte garantera felfri körning utan denna. Enklast är att gå in på Rubys hemsida och följa instruktioner där.

När väl Ruby är installerat behövs vår kod, denna kan du hitta här: ----

Nu när du har alla komponenter kan du packa upp språket till valfri katalog och sedan är allt klart. För att sedan köra en fil skriver du `ruby src/exec_file.rb test_file.ezpz`.

Grattis, nu har du installerat Ruby och kört ditt första EzPz program.
