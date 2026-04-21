#import "../src/lib.typ": class-diagram

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
