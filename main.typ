#import "src/lib.typ": setup-classuml

#show: setup-classuml

#set page(margin: 1.5cm)
#set text(font: "Segoe UI")

= cetz-classuml — Demonstração

== Exemplo 1: Sintaxe PlantUML

```class-diagram-plantuml
@startuml
abstract class Animal {
  - String nome
  - int idade
  + String getNome()
  + void setNome(String nome)
  + {abstract} void emitirSom()
}

class Cachorro {
  - String raca
  + void latir()
}

class Gato {
  - boolean domestico
  + void miar()
}

interface Alimentavel {
  + void alimentar()
  + boolean estaComFome()
}

enum Porte {
  PEQUENO
  MEDIO
  GRANDE
}

Animal <|-- Cachorro
Animal <|-- Gato
Cachorro ..|> Alimentavel
Gato ..|> Alimentavel
Cachorro --> Porte
@enduml
```

== Exemplo 2: Sintaxe Java

```class-diagram-java
public abstract class Animal {
  private String nome;
  private int idade;
  public String getNome() {}
  public abstract void emitirSom();
}
public class Cachorro extends Animal {
  private String raca;
  public void latir() {}
}
public class Gato extends Animal implements Alimentavel {
  private boolean domestico;
  public void miar() {}
  public void alimentar() {}
}
public interface Alimentavel {
  void alimentar();
}
```

== Exemplo 3: Sintaxe C#

```class-diagram-csharp
public abstract class Animal {
  private string nome;
  private int idade;
  public string GetNome() {}
  public abstract void EmitirSom();
}
public class Cachorro : Animal {
  private string raca;
  public void Latir() {}
}
public interface IAlimentavel {
  void Alimentar();
}
public class Gato : Animal, IAlimentavel {
  private bool domestico;
  public void Miar() {}
}
```
