#import "../src/lib.typ": setup-classuml, class-diagram

#show: setup-classuml

= Manual: cetz-classuml
Pacote Typst para renderização de diagramas de classe UML utilizando o engine CeTZ.

== Instalação e Uso
O pacote disponibiliza regras de `show` (interceptação) para code fences.
Basta importar e invocar o comando de setup:
```typst
#import "cetz-classuml/src/lib.typ": setup-classuml
#show: setup-classuml
```

== Gramáticas Suportadas

O pacote suporta o modo PlantUML, além de inferência semântica de relacionamentos lendo código Java e C# reais.

### PlantUML (padrão)
Utilize ` ```class-diagram-plantuml `

### Java
Utilize ` ```class-diagram-java `
Com código Java real, as relações de herança e implementação (extends/implements) e de associação (atributos da classe) serão criadas automaticamente.

### C#
Utilize ` ```class-diagram-csharp `
Com código C# real, a herança e interfaces implementadas via `:` são inferidas; bem como as associações por propriedades ou atributos.

== Features (Roadmap)
- Layout automático das caixas de classes.
- Resolução de estereótipos `<<stereotype>>`.
- Inclusão e renderização de pacotes UML (Planejado na Fase 4).

== Exemplo 
```class-diagram-plantuml
@startuml
class User {
  - int id
  - String email
  + void login()
}

class Admin {
  + void banUser()
}

User <|-- Admin
@enduml
```
