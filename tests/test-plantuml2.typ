#import "../src/lib.typ": setup-classuml
#set page(width: auto)
#show: setup-classuml

#set page(margin: 1.5cm)
#set text(font: "Segoe UI")
= Teste Gramática: PlantUML

```class-diagram-plantuml
@startuml
abstract class Animal {
  - String nome
  - int idade
  + String getNome()
  + {abstract} void emitirSom()
}

class Cachorro {
  - String raca
}

interface Alimentavel {
  + void alimentar()
}

class B{
  + void comer()
}

class D{
  + void comer()
}

Animal <|-- Cachorro
Cachorro ..|> Alimentavel
B --o Animal
D --* Cachorro
H ..> J
@enduml
```


association
```
(op: "--|>",  type: "inheritance",    swap: false),
(op: "..|>",  type: "implementation", swap: false),
(op: "--*",   type: "composition",    swap: true),
(op: "--o",   type: "aggregation",    swap: true),
(op: "-->",   type: "association",    swap: false),
(op: "..>",   type: "dependency",     swap: false),
(op: "--",    type: "link",           swap: false),
(op: "..",    type: "dashed-link",    swap: false),
```
