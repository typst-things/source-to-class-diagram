#import "../src/lib.typ": class-diagram

= Teste Gramática: Java

```class-diagram-java
public abstract class Animal {
  private String nome;
  private int idade;
  public String getNome() { }
  public abstract void emitirSom();
}

public class Cachorro extends Animal {
  private String raca;
  private Coleira coleira;

  public Cachorro(Dono dono) {
    this.dono = dono;
  }

  public void latir() {
    Brinquedo b = new Brinquedo();
  }
}

public interface Alimentavel {
  void alimentar();
}

public class Gato extends Animal implements Alimentavel {
  private boolean domestico;
}

public class Coleira {}
public class Dono {}
public class Brinquedo {}
```
