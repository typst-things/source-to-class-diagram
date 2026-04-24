public class Cachorro extends Animal {
  private String raca;
  private Coleira coleira;
  private Dono dono;

  public Cachorro(Dono dono) {
    this.dono = dono;
  }

  public void latir() {
    Brinquedo b = new Brinquedo();
  }

  @Override
  public void emitirSom() {
    // TODO Auto-generated method stub
    throw new UnsupportedOperationException("Unimplemented method 'emitirSom'");
  }
}
