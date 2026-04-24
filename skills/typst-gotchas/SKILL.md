---
name: Typst Gotchas e Padrões
description: Conhecimento específico sobre o comportamento e limitações da linguagem Typst ao implementar algoritmos lógicos e interações dentro do projeto.
---

# Typst: Gotchas e Padrões de Projeto

Esta skill deve ser consultada sempre que algoritmos dinâmicos de iteração ou manipulação de arrays e loops complexos (como buscas BFS/DFS) precisarem ser desenhados e implementados dentro de arquivos `*.typ`.

## 1. Avaliação Estática de Arrays em Loops (`for`)
No Typst, um laço `for x in array` não evalua as mutações que ocorrem no próprio array original durante o corpo do loop. Se você estiver iterando sobre uma lista e aplicar a função `.push(...)` nessa mesma lista enquanto o bloco do `for` roda, a iteração **não sentirá a expansão das posições do vetor**; ele terminará a iteração rigidamente utilizando o comprimento da versão original avaliada na primeira passagem.

Isso previne a realização bem sucedida de algoritmos que auto-expandem listas pendentes, como por exemplo os de busca (BFS/DFS), provocando falhas lógicas onde as referências mais novas (como classes/nodes descobertos na recursão) acabam sistematicamente puladas se um laço `for` for usado nativamente.

### Exemplo (⚠️ A evitar - Falha estrutural)
```typst
let queue = (A, B)
// O loop não vai passar em 'C' porque a matriz capturada no momento
// inicial do loop só tinha tamanho 2.
for entry in queue {
   if entry == A { queue.push(C) }
}
```

### Solução Válida (✅ Correta)
Em Typst a solução estrutural para implementar filas auto-reguladas/BFS é aplicar de maneira estrita a construção com `while`, somado ao resgate das posições estouradas manipulando o tamanho da fila:

```typst
let queue = (A, B)
while queue.len() > 0 {
    let entry = queue.remove(0) // Extrai o primeiro termo pra processar
    
    // ... lógica BFS ...
    if entry == A { queue.push(C) } // a fila ganha um termo realçado e aumenta
}
```

Sempre aplique este padrão se a lógica que governa suas tabelas, nodes ou componentes no Typst envolver propagação interativa na própria coleção.
