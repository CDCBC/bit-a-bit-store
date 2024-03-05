# Bit-a-Bit Store

Progetto sviluppato dal Gruppo 14 per il corso di *Architettura degli elaboratori*, che si tiene durante il secondo semestre del primo anno del CdS in Informatica presso l'[Unical](https://www.unical.it) (A.A. 2022/23).

Il progetto è scritto in ARM Assembly, ma fa uso di alcune funzioni della Libreria Standard di C.

![](demo.png)

## Compilare ed eseguire l'applicazione

Su GNU/Linux x86_64 è necessario avere `aarch64-linux-gnu-gcc` (sia per Arch che per Debian) e `qemu-user-binfmt` (per Debian) o `qemu-user` (per Arch), e quindi eseguire:

```bash
aarch64-linux-gnu-gcc -static bit-a-bit_store.s -o bit-a-bit_store
qemu-aarch64 bit-a-bit_store
```

## L'applicazione

All'avvio si ha una tabella e la possibilità di eseguire un'azione. Le righe della tabella costituiscono i prodotti del negozio di elettronica, ciascuno descritto da diversi campi.

I dati sono salvati e letti da un file `entries.dat`. Le azioni che è possibile eseguire sui dati sono:

- aggiungere un nuovo prodotto, inserendo ciascun campo da terminale
- rimuovere un prodotto dopo averne specificato la posizione
- filtrare i prodotti
    - per _prezzo_ (fino ad un certo prezzo o a partire da un certo prezzo)
    - per _tipo_
- scambiare due prodotti dopo avere specificato le loro posizioni
- rimuovere il primo prodotto con il _prezzo_ uguale a quello immediatamente seguente
- scambiare i primi due prodotti non ordinati in modo crescente per il campo _scorte_
- ordinare tutta la tabella per _scorte_ in modo crescente
- calcolare la media decimale dei prezzi dei prodotti
