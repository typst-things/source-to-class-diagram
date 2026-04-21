#import "../src/lib.typ": class-diagram

= Teste Gramática: C#

```class-diagram-csharp
public abstract class Animal {
  private string nome;
  private int idade;
  public string GetNome() { }
  public abstract void EmitirSom();
}

public class Cachorro : Animal {
  private string raca;
  private Coleira coleira;

  public Cachorro(Dono dono) {
    this.dono = dono;
  }

  public void Latir() {
    Brinquedo b = new Brinquedo();
  }
}

public interface IAlimentavel {
  void Alimentar();
}

public class Gato : Animal, IAlimentavel {
  private bool domestico;
}

public class Coleira {}
public class Dono {}
public class Brinquedo {}
```
