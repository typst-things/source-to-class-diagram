#import "../src/lib.typ": setup-classuml
#set page(paper: "a4", flipped: true)
//#set page(width: auto)
//#set page(width: 10cm)
#show: setup-classuml

= Teste Gramática: Java

#let src = (
  read("java/Animal.java"),
  read("java/Cachorro.java"),
  read("java/Alimentavel.java"),
  read("java/Gato.java"),
  read("java/Coleira.java"),
  read("java/Dono.java"),
  read("java/Brinquedo.java"),
).join("\n\n")

#raw(src, block: true, lang: "class-diagram-java")
