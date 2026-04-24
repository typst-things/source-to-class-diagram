#import "../src/lib.typ": setup-classuml
//#set page(width: auto)
#set page(paper: "a4")
#show: setup-classuml

#set page(margin: 1.5cm)
#set text(font: "Segoe UI")
= Teste Gramática: PlantUML

```class-diagram-plantuml
@startuml
class A{
  - String nome
  - int idade
  - B n
  + A()
  + String getNome()
  + {abstract} void emitirSom()
}
A --* C
A <|-- D

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
