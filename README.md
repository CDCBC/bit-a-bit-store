<h1 align="center">Bit-a-Bit Store</h1>

<p align="center">
    <img src="tui.png"></img>
</p>

Progetto sviluppato per il corso di _Architettura degli Elaboratori_, che si tiene durante il secondo semestre del primo anno del CdS in Informatica presso l'@UniversitaDellaCalabria.

All'avvio il programma mostra una tabella e la possibilità di eseguire un'azione. Le righe della tabella costituiscono i prodotti del negozio di ellettronica, ciscuno descritto da diversi campi.

I dati sono salvati e letti da un file `entries.dat`. Le azioni che è possibile eseguire sui dati sono:

- aggiungere un nuovo prodotto, inserendo ciascun campo da terminale
- rimuovere un prodotto dopo averne specificando la posizione
- filtrare i prodotti
    - per _prezzo_ (fino ad un certo prezzo o a partire da un certo prezzo)
    - per _tipo_
- scambiare due prodotti dopo avere specificato le loro posizioni
- rimuovere il primo prodotto con il _prezzo_ uguale a quello immediatamente seguente
- scambiare i primi due prodotti non ordinati in modo crescente per il campo _scorte_
- ordinare tutta la tabella per _scorte_ in modo crescente
- calcolare la media decimale dei prezzi dei prodotti

## asm

In modo da evitare di scrivere lunghi comandi per fare operazioni come eseguire, disassemblare o debuggare un file sorgente assembly, ho scritto un semplice script bash che rende tutto più veloce.
