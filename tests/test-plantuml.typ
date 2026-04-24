#import "../src/lib.typ": setup-classuml

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

Animal <|-- Cachorro
Cachorro ..|> Alimentavel
@enduml
```
