#import "../src/lib.typ": setup-classuml
//#set page(paper: "a4", flipped: true)
#set page(width: auto)
//#set page(width: 10cm)
#show: setup-classuml



















= Teste Gramática: Java

```class-diagram-java
interface Interface1{
 void method1();
}

class MiniTeste implements Interface1{
  public void method1(){

  }

  private void method2(){

  }
}

class Class1 {
  private List<Class2> listClass2;
  public addClass2(String class2Name){
    Class2 class2 = new Class2(class2Name, this);
    listClass2.add(class2);
  }
}

class Class2{
  private Class1 class1;
  private String name;

  public Class2(String name, Class1 class1){
    this.class1 = class1;
    this.name = name;
  }

  public Class2(Class1 class1){
    this.class1 = class1;
  }
}
class Class4 extends Class1{
  public String teste;
}

@Layout(level=1, order=1)
class Class3 implements Interface1{
  private Class1 class1;
}

class Class4 extends Class1{
  public String teste;
}

class Class5 extends Class1{
  public String teste;
}

class Class6 extends Class1{
  public String teste;
}


```
