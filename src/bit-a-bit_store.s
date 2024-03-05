/* bit-a-bit_store.s -- Project source file
 *
 * Copyright (C) 2023  Silvio Bartolotta
 * Copyright (C) 2023  Alfredo Carlino
 * Copyright (C) 2023  Giorgio Carlino
 * Copyright (C) 2023  Alessandro Cava
 * Copyright (C) 2023  Mario D'Andrea <https://ormai.dev>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details. */

/*                ____ ____  _   _ ____  ____   ___     _ _  _               */
/*               / ___|  _ \| | | |  _ \|  _ \ / _ \   / | || |              */
/*              | |  _| |_) | | | | |_) | |_) | | | |  | | || |_             */
/*              | |_| |  _ <| |_| |  __/|  __/| |_| |  | |__   _|            */
/*               \____|_| \_\\___/|_|   |_|    \___/   |_|  |_|              */

/*                           NEGOZIO DI ELETTRONICA                          */

/* Struttura di questo file:                     (riga)
       - macro
            - removeProduct________________________41
            - swapProducts_________________________69
            - readInt_____________________________106
            - readStr_____________________________120
            - saveTo______________________________132
       - funzioni
            - main________________________________153
            - load________________________________211
            - save________________________________249
            - printTable__________________________292
            - printTUI____________________________373
            - addProduct__________________________392
            - remove______________________________454
            - swap________________________________484
            - removeDuplicatePrice________________526
            - filters_____________________________577
            - filterByPrice_______________________667
            - filterByType________________________714
            - sort________________________________772
            - bubbleSort__________________________824
            - meanPrice___________________________840
       - memoria
           - .bss_________________________________877
           - .data________________________________885
           - .rodata______________________________906
*/

/*****************************************************************************/

            .macro      removeProduct
            /* Questa macro rimuove il prodotto con indice in w0. */
            stp         x0, x1, [sp, #-16]!
            stp         x2, x3, [sp, #-16]!

            ldr         w2, nProducts
            sub         w2, w2, w0              // nProducts - indice

            mov         w3, productSize
            mul         w1, w0, w3              // offset = indice * productSize

            ldr         x0, =products
            add         x0, x0, x1              // [dest] products[w0]
            add         x1, x0, x3              // [src]  products[w0 + productSize]
            mul         w2, w2, w3              // byte da copiare (48)
            bl          memcpy

            // Calcola e salva nProducts aggiornato
            ldr         x0, =nProducts
            ldr         w1, [x0]
            sub         w1, w1, #1              // nProducts -= 1
            str         w1, [x0]

            ldp         x2, x3, [sp], #16
            ldp         x0, x1, [sp], #16
            .endm



            .macro      swapProducts
            /* Questa macro usa `memcpy` per scambiare due prodotti con indici
               in w0 e w1. */
            stp         x19, x20, [sp, #-16]!
            stp         x21, x22, [sp, #-16]!
            sub         sp, sp, productSize     // incrementa lo stack di 48 B

            mov         w19, w0
            mov         w20, w1
            ldr         x21, =products
            mov         w22, productSize

            // 1. copia il prodotto con indice in w0 sullo stack (w0 -> stack)
            mov         x0, sp                  // [dest] stack pointer
            madd        x1, x19, x22, x21       // [src]  products[w0]
            mov         w2, productSize         // byte da copiare (48)
            bl          memcpy

            // 2. copia il prodotto con indice in w1 in w0 (w1 -> w0)
            madd        x0, x19, x22, x21       // [dest] products[w0]
            madd        x1, x20, x22, x21       // [src]  products[w1]
            mov         w2, productSize         // byte da copiare (48)
            bl          memcpy

            // 3. copia il prodotto sullo stack all'indice in w1 (stack -> w1)
            madd        x0, x20, x22, x21       // [dest] products[w1]
            mov         x1, sp                  // [src]  stack pointer
            mov         w2, productSize         // byte da copiare (48)
            bl          memcpy

            add         sp, sp, productSize     // decrementa lo stack di 48 B
            ldp         x21, x22, [sp], #16
            ldp         x19, x20, [sp], #16
            .endm



            .macro      readInt prompt
            /* `readInt` legge un intero e lo salva a `tmpInt` */
            adr         x0, \prompt
            bl          printf

            adr         x0, scanInt
            adr         x1, tmpInt
            bl          scanf

            ldr         x0, tmpInt
            .endm



            .macro      readStr prompt dest
            /* `readStr` legge una stringa e la salva a `dest` */
            adr         x0, \prompt
            bl          printf

            adr         x0, scanStr
            adr         x1, tmpStr
            bl          scanf
            .endm



            .macro      saveTo item, offset, size
            /* salva una stringa da `tmpStr` all'indirizzo contenuto in xn */
            add         x0, \item, \offset      // indirizzo a cui copiare
            ldr         x1, =tmpStr             // stringa da copiare
            mov         x2, \size               // lunghezza stringa in B
            bl          strncpy

            add         x0, \item, \offset + \size - 1 // pulisci memoria
            strb        wzr, [x0]
            .endm

/*****************************************************************************/
/*                                          _                                */
/*                          _ __ ___   __ _(_)_ __                           */
/*                         | '_ ` _ \ / _` | | '_ \                          */
/*                         | | | | | | (_| | | | | |                         */
/*                         |_| |_| |_|\__,_|_|_| |_|                         */

            .text
            .type       main, %function
            .global     main
main:       stp         x29, x30, [sp, #-16]!

            bl          load                    // 1. carica dal file

begin:      bl          printTUI                // 2. stampa la tui

noTUI:      readInt     prmtMenu                // 3. leggi opzione

            // 4. Controlla opzione
option0:    cmp         w0, #0                  // opzione 0: esci
            beq         return

option1:    cmp         w0, #1                  // opzione 1: aggiungi articolo
            bne         option2
            bl          addProduct

option2:    cmp         w0, #2                  // opzione 2: rimuovi articolo
            bne         option3
            bl          remove

option3:    cmp         w0, #3                  // opzione 3: filtri
            bne         option4
            bl          filters

option4:    cmp         w0, #4                  // opzione 4: scambia elementi
            bne         option5
            bl          swap

option5:    cmp         w0, #5                  // opzione 5: rimuovi duplicato
            bne         option6
            bl          removeDuplicatePrice

option6:    cmp         w0, #6                  // opzione 6: ordina primi due
            bne         option7
            bl          sort

option7:    cmp         w0, #7                  // opzione 7: ordina scorte
            bne         option8
            bl          bubbleSort

option8:    cmp         w0, #8                  // opzione 8: media decimale
            bne         noOption
            bl          meanPrice               // stampa la media e non la
            b           noTUI                   // tabella

noOption:   b           begin                   // 5. Ripeti

return:     mov         w0, wzr                 // 6. Termina
            ldp         x29, x30, [sp], #16
            ret
            .size        main, (. - main)

/*****************************************************************************/
/* La funzione `load` legge un file entries.dat e ne carica il contenuto in  */
/* memoria all'indirizzo collegato all'etichetta `products`.                 */
/* Non prende argomenti e restituisce `void`.                                */

            .type       load, %function
load:       stp         x29, x30, [sp, #-16]!
            str         x19, [sp, #-16]!

            adr         x0, filename
            adr         x1, fmtRead
            bl          fopen                   // apri il file in mod lettura

            cmp         x0, xzr                 // se fopen restituisce NULL
            beq         loadReturn              // è finita, oppure
            mov         x19, x0                 // copia in x19 il file pointer

            ldr         x0, =nProducts          // indirizzo in cui salvare
            mov         x1, #4                  // dimensioni elemento (in B)
            mov         x2, #1                  // numero di elementi
            mov         x3, x19                 // puntatore al file (stream)
            bl          fread

            // carica gli articoli veri e propri dal file
            ldr         x0, =products
            mov         x1, productSize
            mov         x2, nMaxProducts
            mov         x3, x19
            bl          fread

            mov         x0, x19                 // chiudi il file a cui
            bl          fclose                  // l'indirizzo in x0 punta

loadReturn: ldr         x19, [sp], #16
            ldp         x29, x30, [sp], #16
            ret
            .size       load, (. - load)

/*****************************************************************************/
/* La funzione `save` trasferisce i dati dall'indirizzo dell'etichetta       */
/* `products` nel file `entries.dat`.                                        */
/* Non prende argomenti e restituisce `void`.                                */

            .type       save, %function
save:       stp         x29, x30, [sp, #-16]!
            str         x19, [sp, #-16]!

            adr         x0, filename
            adr         x1, fmtWrite
            bl          fopen                   // apri il file
            // se non riesci ad aprire il file termina
            cmp         x0, xzr
            beq         couldNotSave
            mov         x19, x0     // se riesci, copia in x19 il pointer

            // scrivi il numero di righe nella lista
            ldr         x0, =nProducts          // indirizzo da cui salvare
            mov         x1, #4                  // dimensione elemento
            mov         x2, #1                  // numero elementi
            mov         x3, x19                 // file pointer
            bl          fwrite

            // scrivi prodotti nel file
            ldr         x0, =products
            mov         x1, productSize
            mov         x2, nMaxProducts
            mov         x3, x19
            bl          fwrite

            mov         x0, x19
            bl          fclose                  // chiudi il file
            b           saveReturn              // successo -> termina

couldNotSave: // gestisci errore
            adr         x0, didNotSave
            bl          printf

saveReturn: ldr         x19, [sp], #16
            ldp         x29, x30, [sp], #16
            ret
            .size       save, (. - save)

/*****************************************************************************/
/* La funzione `printTable` stampa la tabella.                               */

            .type       printTable, %function
            .global     printTable
printTable: stp         x29, x30, [sp, #-16]!
            stp         x19, x20, [sp, #-16]!
            str         x21, [sp, #-16]!

            adr         x0, header              // titolo e inizio tabella
            bl          printf

            mov         w19, wzr                // indice
            ldr         x20, =products          // indirizzo inizio struttura
            ldr         w21, nProducts          // numero articoli in memoria

loopRows:   cmp         w19, w21
            beq         endLoopRows // se l'indice è >= a nProducts: break

            adr         x0, fmtEntry            // formato riga
            add         w1, w19, #1             // #
            add         x2, x20, offsetEan      // EAN
            add         x3, x20, offsetName     // Prodotto

            // il tipo è un numero, a cui è associata una stringa
            ldr         w4, [x20, offsetType]

whichType:  cmp         w4, #1
            bne         ifType1
            adr         x4, type1
            b           endIfType

ifType1:    cmp         w4, #2
            bne         ifType2
            adr         x4, type2
            b           endIfType

ifType2:    cmp         w4, #3
            bne         ifType3
            adr         x4, type3
            b           endIfType

ifType3:    cmp         w4, #4
            bne         ifType4
            adr         x4, type4
            b           endIfType

ifType4:    cmp         w4, #5
            bne         ifType5
            adr         x4, type5
            b           endIfType

ifType5:    cmp         w4, #6
            bne         noType
            adr         x4, type6
            b           endIfType

noType:     adr         x4, noneType

endIfType:  ldr         w5, [x20, offsetStock]  // Scorte

            ldr         w6, [x20, offsetPrice]  // Prezzo
            bl          printf                  // stampa riga

            add         w19, w19, #1            // incrementa indice
            add         x20, x20, productSize   // vai al prodotto successivo
            b           loopRows

endLoopRows:
            adr         x0, footer              // chiudi tabella
            bl          printf

            mov          w0, #0
            ldr         x21, [sp], #16
            ldp         x19, x20, [sp], #16
            ldp         x29, x30, [sp], #16
            ret
            .size        printTable, (. - printTable)

/*****************************************************************************/
/* La funzione `printTUI` stampa l'interfaccia utente compresa di opzioni e  */
/* tabella.                                                                  */
/* Non prende argomenti e restituisce `void`.                                */

            .type       printTUI, %function
            .global     printTUI
printTUI:   stp         x29, x30, [sp, #-16]!

            bl          printTable              // stampa la tabella

            adr         x0, options
            bl          printf

            mov         w0, wzr
            ldp         x29, x30, [sp], #16
            ret
            .size       printTUI, (. - printTUI)

/*****************************************************************************/
/* La funzione `addProduct` aggiunge un nuovo prodotto i cui campi sono      */
/* letti da input e fa anche la scrittura nel file.                          */
/* Non prende argomenti e restituisce `void`.                                */

            .type       addProduct, %function
            .global     addProduct
addProduct: stp         x29, x30, [sp, #-16]!
            stp         x19, x20, [sp, #-16]!

            ldr         w19, nProducts          // numero prodotti in memoria

            cmp         w19, nMaxProducts       // se si è raggiungo il numero
            bge         didNotAdd               // massimo di prodotti: termina

            ldr         x20, =products          // indirizzo array
            mov         w0, productSize         // dimensione prodotto
            mul         w0, w19, w0             // dimensione attuale array
            add         x20, x20, x0            // indirizzo fine ultimo prod

            // leggi campi da input
            readStr    prmtEan
            saveTo     x20, offsetEan, sizeEan

            readStr    prmtName
            saveTo     x20, offsetName, sizeName

            adr         x0, fmtTypes
            adr         x1, type1
            adr         x2, type2
            adr         x3, type3
            adr         x4, type4
            adr         x5, type5
            adr         x6, type6
            bl          printf

            readInt     prmtType
            str         w0, [x20, offsetType]

            readInt     prmtStock
            str         w0, [x20, offsetStock]

            readInt     prmtPrice
            str         w0, [x20, offsetPrice]

            // incrementa nProducts di 1 e salvalo
            add         w19, w19, #1
            ldr         x20, =nProducts
            str         w19, [x20]

            // salva la struttura appena modificata
            bl          save
            b           addReturn

didNotAdd:  adr         x0, addError
            bl          printf

addReturn:  ldp         x19, x20, [sp], #16
            mov         w0, wzr
            ldp         x29, x30, [sp], #16
            ret
            .size        addProduct, (. - addProduct)

/*****************************************************************************/
/* La funzione `remove` rimuove un elemento dalla struttura.                 */
/* Non prende argomenti e restituisce `void`.                                */

            .type       remove, %function
            .global     remove
remove:     stp         x29, x30, [sp, #-16]!

            ldr         w0, nProducts           // non fare niente se la
            cbz         w0, removeReturn        // tabella è vuota

            readInt     prmtIndex               // leggi posizione da input

            cmp         w0, #1                  // se indice < 1: termina
            blt         removeReturn

            ldr         w1, nProducts
            cmp         w0, w1                  // se indice > nProducts:
            bgt         removeReturn            // termina

            sub         w0, w0, #1              // posizone --> indice
            removeProduct
            bl          save

removeReturn:
            ldp         x29, x30, [sp], #16
            ret
            .size        remove, (. - remove)

/*****************************************************************************/
/* La funzione `swap` usa la macro `swapProducts` per scambiare due          */
/* elementi della tabella, in in base ad una scelta dell'utente.             */
/* Non prende argomenti e restituisce `void`.                                */

            .type       swap, %function
            .global     swap
swap:       stp         x29, x30, [sp, #-16]!
            stp         x19, x20, [sp, #-16]!

            ldr         w20, nProducts
            // leggi i due interi e controlla che siano nell'intervallo di
            // estremi [1, nProducts]
            readInt     prmtIndex
            mov         w19, w0                 // `readInt` sovrascrive tutto.
            cmp         w19, w20                // Controlla che il primo
            bgt         swapReturn              // numero dell'utente sia nel
            cmp         w19, #1                 // range consentito.
            blt         swapReturn

            readInt     prmtIndex               // fai il controllo anche per
            cmp         w0, w20                 // l'altra posizione
            bgt         swapReturn
            cmp         w0, #1
            blt         swapReturn

            cmp         w0, w19     // se l'utente ha dato due volte lo stesso
            beq         swapReturn  // numero: non fare niente

            // trasforma le posizioni in indici
            sub         w0, w0, #1              // w0 -= 1
            sub         w1, w19, #1             // w1 -= 1

            swapProducts                        // effettua lo scambio
            bl          save

swapReturn: mov         w0, wzr
            ldp         x19, x20, [sp], #16
            ldp         x29, x30, [sp], #16
            ret
            .size        swap, (. - swap)

/*****************************************************************************/
/* La funzione `removeDuplicatePrice` rimuove il primo duplicato rispetto al */
/* prezzo. Rimuove la prima riga il cui campo `Prezzo` è uguale a a quello   */
/* della riga successiva.                                                    */

            .type       removeDuplicatePrice, %function
            .global     removeDuplicatePrice
removeDuplicatePrice:
            stp         x29, x30, [sp, #-16]!

            mov         w1, productSize
            ldr         x2, =products

            mov         w0, #0                  // indice elemento precedente
            mul         w3, w1, w0              // offset elemento precedente
            add         x3, x2, x3              // indirizzo primo prodotto

            add         w6, w0, #1              // indice elemento successivo
            mul         w4, w1, w6              // offset elemento successivo
            add         x4, x2, x4              // indirizzo primo prodotto

            ldr         w7, nProducts
loopRemoveDuplcatePrice:
            cmp         w6, w7      // quando l'indice raggiunge productSize:
            bge         endLoopRemoveDuplicatePrice    // termina

            ldr         w9, [x3, offsetPrice]   // prezzo elemento precedente
            ldr         w10, [x4, offsetPrice]  // prezzo elemento successivo

ifDuplicatePrice:
            cmp         w9, w10                 // se i due prezzi sono uguali:
            bne         endIfDupicatePrice
            removeProduct                       // rimuovi il primo prodotto

endIfDupicatePrice:     // preparati all'iterazione successiva
            add         w0, w0, #1              // incrementa indice precedente
            add         w6, w6, #1              // incrementa indice seguente
            add         x3, x3, productSize
            add         x4, x4, productSize
            b           loopRemoveDuplcatePrice

endLoopRemoveDuplicatePrice:
            bl          save                    // salva array in file
            mov         w0, wzr
            ldp         x29, x30, [sp], #16
            ret
            .size       removeDuplicatePrice, (. - removeDuplicatePrice)

/*****************************************************************************/
/* La funzione `filters` è il centro operativo per i filtri.                 */
/* Da qui è gestita la selezione del filtro da parte dell'utente.            */
/* Se l'utente sceglie 0, oppure un numero diverso da n in [0, 1, 2], la tui */
/* torna al menù di selezione principale. Se l'opzione è corretta, questa    */
/* funzione prepara un set di argomenti e chiama una certa funzione filtro.  */
/* Non prende argomenti e restituisce `void`.                                */

            .type       filters, %function
            .global     filters
filters:    stp         x29, x30, [sp, #-16]!
            stp         x19, x20, [sp, #-16]!

filtersLoop:
            bl          printTable              // stampa la tabella

whichFilter:
            adr         x0, filtersOptions
            bl          printf
            readInt     promptFilters           // leggi opt da input
            mov         w19, w0

filtersOption0:
            cmp         w19, #0                 // se opt == 0:
            beq         filtersReturn           //     vai a filtersReturn

filtersOptions1:
            cmp         w19, #1                 // ### filtro per prezzo ###
            bne         filtersOption2          // se opt != 1 vai a opzione 2

            adr         x0, filterPriceMode     // chiedi come filtrare
            bl          printf
            readInt     promptFilters           // mode da passare in w2
            mov         w20, w0

            // non ha senso chiedere il prezzo se non ha scelto 1 o 2
            cmp         w20, wzr                // se l'utente ha scelto 0
            beq         whichFilter             // torna indietro

            // controlla che la scelta sia 1 o 2
            cmp         w20, #1
            beq         callFilterByPrice
            cmp         w20, #2
            beq         callFilterByPrice
            b           filtersOptions1         // richiedi come filtrare

callFilterByPrice:
            readInt     prmtPrice               // chiedi prezzo e
            mov         w1, w0                  // passalo in w1
            ldr         w0, nProducts
            sub         w0, w0, #1              // nprods -= 1 in w0
            mov         w2, w20                 // mode
            bl          filterByPrice

            //bl          save                  // salva una sola volta
            b           filtersLoop             // fatto, ripeti menù

filtersOption2:
            cmp         w19, #2                 // ### filtro per tipo ###
            bne         filtersLoop             // se opt != 2 vai richiedi
            bl          filterByType

            b           filtersLoop

filtersReturn:
/* chiede se si vuole mantenere il menù dei filtri permanenti:
   - se viene inserito 1 salva lo stato attuale e lo carica con la prossima
     istruzione
   - se viene inserito 0 non salva e carica lo stato precedente della tabella
*/
            adr         x0, fmtAgree
            bl          printf

            readInt     prmtAgree                           // legge l'input
            cmp         w0, #1
            beq         revertFilter
            bl          save

revertFilter:
            bl          load

            mov         w0, wzr
            ldp         x19, x20, [sp], #16
            ldp         x29, x30, [sp], #16
            ret
            .size       filters, (. - filters)

/*****************************************************************************/
/* La funzione `filterByPrice` filtra i prodotti che sono maggiori o minori  */
/* di un certo prezzo. Modalità e prezzo sono scelti dall'utente.            */
/* Argomenti:                                                                */
/*     (nProducts - 1) in w0                                                 */
/*     il prezzo scelto dall'utente in w1                                    */
/*     in w2 un intero che può essere 1 o 2 (ad 1 corrisponde <= a 2 >=)     */
/* Restituisce:                                                              */
/*     (nProducts - 1) se questo non è minore di zero, altrimenti            */
/*     `void`                                                                */

            .type       filterByPrice, %function
            .global     filterByPrice
filterByPrice:
            stp         x29, x30, [sp, #-16]!

filterByPriceBaseCase:
            cmp         w0, #0                  // quando l'indice è minore di
            blt         filterByPriceReturn     // zero: termina funzione

            // carica in w3 il prezzo dell'ultimo prodotto
            ldr         x4, =products           // inizio array
            mov         w5, productSize
            madd        x6, x0, x5, x4          // x6 = x4 + (x0 * x5)
            ldr         w3, [x6, offsetPrice]   // vai al prezzo del prodotto

lessOrEqualToMode:
            cmp         w2, #1                  // fino ad un certo prezzo
            bne         greaterOrEqualToMode

            cmp         w3, w1
            bgt         deleteProduct
            b           next

/* È certo che se in w2 non c'è 1, allora c'è 2 (vedi funzione `filters`)    */
greaterOrEqualToMode:
            cmp         w3, w1 // se (prezzo da lista < prezzo utente): elimina
            blt         deleteProduct // se strettamente minore: elimina
            b           next

deleteProduct:
            removeProduct

next:       sub         w0, w0, #1              // decrementa argomento indice
            bl          filterByPrice           // <-- chiamata ricorsiva -->

filterByPriceReturn:
            mov         w0, wzr                 // quando il caso base fallisce
            ldp         x29, x30, [sp], #16
            ret
            .size        filterByPrice, (. - filterByPrice)

/*****************************************************************************/
/* La funzione `filterByType` chiede all'utente uno dei tipi disponibili per */
/* cui filtrare la tabella. Successivamente scansiona la tabella ed elimina  */
/* ogni prodotto il cui tipo sia diverso da quello scelto dall'utente.       */
/* Non prende argomenti e restituisce `void`.                                */

            .type       filterByType, %function
            .global     filterByType
filterByType:
            stp         x29, x30, [sp, #-16]!

            adr         x0, fmtTypes
            adr         x1, type1
            adr         x2, type2
            adr         x3, type3
            adr         x4, type4
            adr         x5, type5
            adr         x6, type6
            bl          printf

            readInt    prmtType                 // chiedi tipo

            // controlla se il tipo è out of range
            cmp         w0, #1
            blt         filterByTypeEndLoop
            cmp         w0, #6
            bgt         filterByTypeEndLoop 
            mov         w1, w0

            ldr         w0, nProducts           // i = len(products)
            sub         w0, w0, #1              // i -= 1
            mov         w2, productSize
            adr         x3, products            // inizio struttura
            madd        x3, x2, x0, x3          // indirizzo ultimo elemento

filterByTypeLoop:
            cmp         w0, #0                  // quando i < 0
            blt         filterByTypeEndLoop     // rompi il loop

            ldr         w2, [x3, offsetType]    // vai al tipo del prodotto

filterByTypeIf:
            cmp         w1, w2      // se sono diversi rimuovi la riga
            beq         filterByTypeEndIf
            removeProduct

filterByTypeEndIf:
            sub         x3, x3, productSize     // vai al prodotto precedente
            sub         w0, w0, #1              // i--;
            b           filterByTypeLoop        // ripeti

filterByTypeEndLoop:
            //bl          save                  // salva una sola volta
            mov         w0, wzr
            ldp         x29, x30, [sp], #16
            ret
            .size        filterByType, (. - filterByType)

/*****************************************************************************/
/* Scambia la prima coppia di elementi che trova con quantità non ordinata   */
/* in modo crescente.                                                        */
/* Non prende argomenti.                                                     */
/* Restituisce 1 se è stato effettuato uno scambio, altrimenti 0.            */

            .type       sort, %function
            .global     sort
sort:       stp         x29, x30, [sp, #-16]!
            ldr         x19, [sp, #-16]!

            ldr         w7, nProducts
            mov         w10, wzr                // prodotto precedente
            add         w9, w10, #1             // prodotto corrente
            adr         x11, products

scanTable:  cmp         w9, w7                  // quando si raggiunge la fine
            bge         endScan                 // dell'array: termina

            // quantità corrente
            mov         w0, productSize
            // riga corrente = inidice corrente * productSize + products
            madd        x0, x9, x0, x11
            ldr         w1, [x0, offsetStock] 

            // quantità precedente
            mov         w2, productSize
            // riga precedente = inidice precedente * productSize + products
            madd        x2, x10, x2, x11
            ldr         w3, [x2, offsetStock]

            // controllo se la quantità precedente è maggiore della corrente
            cmp         w3, w1
            bgt         doTheSwap

            // vai al successivo
            add         w10, w10, #1            // indice prdotto precedente
            add         w9, w9, #1              // indice prdotto corrente
            b           scanTable

doTheSwap:  mov         w0, w9
            mov         w1, w10
            swapProducts
            mov         w19, #1
            b           sortReturn

endScan:    mov         w19, #0

sortReturn: bl          save
            mov         w0, w19
            ldr         x19, [sp], #16
            ldp         x29, x30, [sp], #16
            ret
            .size       sort, (. - sort)

/*****************************************************************************/
/* Riordina tutta la tabella per scorte in modo crescente                    */

            .type       bubbleSort, %function
            .global     bubbleSort
bubbleSort: stp         x29, x30, [sp, #-16]!

swapThem:   bl          sort
            cmp         w0, #1      // se c'è stato uno scambio ripeti
            beq         swapThem

            ldp         x29, x30, [sp], #16
            ret
            .size       bubbleSort, (. - bubbleSort)

/*****************************************************************************/
/* La funzione `meanPrice` calcola la media aritmetica dei prezzi.           */
/* Non prende argomenti e restituisce `void`.                                */

            .type       meanPrice, %function
            .global     meanPrice
meanPrice:  stp         x29, x30, [sp, #-16]!

            fmov        s0, wzr                 // somma
            mov         w1, wzr                 // indice
            ldr         w2, nProducts
            cmp         w2, wzr                 // se la tabella è vuota:
            beq         meanPriceReturn         //      termina
            adr         x3, products

sumLoop:    ldr         w4, [x3, offsetPrice]   // post-test loop
            ucvtf       s4, w4                  // n=products[w1][offsetPrice]

            fadd        s0, s0, s4              // somma += n
            add         w1, w1, #1              // w1 += 1
            add         x3, x3, productSize     // prodotto successivo

            cmp         w1, w2                  // finché indice < nProducts:
            blt         sumLoop                 //     ripeti

sumEndloop: ucvtf       s1, w1                  // converti indice in float
            fdiv        s0, s0, s1              // calcola la media

            fcvt        d0, s0                  // converti la media in double
            adr         x0, fmtMean             // stampa
            bl          printf

meanPriceReturn:
            ldp         x29, x30, [sp], #16
            ret
            .size       meanPrice, (. - meanPrice)

/*****************************************************************************/
/*                 _ __ ___   ___ _ __ ___   ___  _ __(_) __ _               */
/*                | '_ ` _ \ / _ \ '_ ` _ \ / _ \| '__| |/ _` |              */
/*                | | | | | |  __/ | | | | | (_) | |  | | (_| |              */
/*                |_| |_| |_|\___|_| |_| |_|\___/|_|  |_|\__,_|              */

            .bss
products:   .skip       nMaxProducts * productSize // alloca memoria per i dati

            // usati temporaneamente da scanf per la lettura da input
tmpStr:     .skip       128
tmpInt:     .skip       8

// ----------------------------------------------------------------------------
            .data
nProducts:  .word       0 // numero attuale di prodotti nella lista

            // struct product {};

            .equ        sizeEan, 14             // 13 caratteri + \0
            .equ        sizeName, 21            // 20 caratteri + \0
            .equ        sizeType, 4
            .equ        sizeStock, 4
            .equ        sizePrice, 4

            .equ        offsetEan, 0
            .equ        offsetName, (offsetEan + sizeEan)       // 0 + 14 = 14
            .equ        offsetType, (offsetName + sizeName)     // 14 + 17 = 31
            .equ        offsetStock, (offsetType + sizeType)    // 31 + 4 = 35
            .equ        offsetPrice, (offsetStock + sizeStock)  // 35 + 4 = 39

            .equ        productSize, 48  // 47 allineato al multiplo di 16 > 43
            .equ        nMaxProducts, 10 // numero massi di prodotti in lista

// ----------------------------------------------------------------------------
            .section    .rodata
header:     .ascii      "\n"
            .ascii      "                        ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n"
            .ascii      "                        ┃       Bit-a-Bit Store       ┃\n"
            .ascii      "                        ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n"
            .ascii      "┌─────┬───────────────┬──────────────────────┬──────────────┬────────┬────────┐\n"
            .ascii      "│  #  │     EAN       │       Prodotto       │     Tipo     │ Scorte │ Prezzo │\n"
            .asciz      "├─────┼───────────────┼──────────────────────┼──────────────┼────────┼────────┤\n"

fmtEntry:   .asciz      "│ %3d │ %-13s │ %-20s │ %-12s │ %6d │ %6d │\n"

footer:     .asciz      "└─────┴───────────────┴──────────────────────┴──────────────┴────────┴────────┘\n"

fmtTypes:   .asciz      "\n 👉 Scegli un tipo\n\n    1 - %s\n    2 - %s\n    3 - %s\n    4 - %s\n    5 - %s\n    6 - %s\n\n"
type1:      .asciz      "computer"
type2:      .asciz      "connettore"
type3:      .asciz      "network"
type4:      .asciz      "stampa/scan"
type5:      .asciz      "strumento"
type6:      .asciz      "componente"
noneType:   .asciz      "nessuno"

options:    .ascii      "\n 👉 Scegli un'azione\n\n"
            .ascii      "    0 - Esci\n"
            .ascii      "    1 - Aggiungi nuovo prodotto\n"
            .ascii      "    2 - Rimuovi prodotto\n"
            .ascii      "    3 - Applica filtro\n"
            .ascii      "    4 - Scambia prodotti\n"
            .ascii      "    5 - Rimuovi il primo di due prodotti consecutivi\n"
            .ascii      "        con lo stesso prezzo\n"
            .ascii      "    6 - Scambia primi due prodotti non ordinati per scorte\n"
            .ascii      "    7 - Ordina per scorte (in modo crescente)\n"
            .asciz      "    8 - Calcola la media decimale dei prezzi\n\n"

prmtMenu:   .asciz      "Azione (0-8) > "

scanInt:    .asciz      "%d"
scanStr:    .asciz      "%127s"

prmtIndex:  .asciz      "Numero prodotto (fuori range per annullare): "

// ------------------- servono per la funzione `addProduct` -------------------
prmtEan:    .asciz      "Ean: "
prmtName:   .asciz      "Prodotto (no spazi): "
prmtType:   .asciz      "Tipo (1-6): "
prmtStock:  .asciz      "Scorte: "
prmtPrice:  .asciz      "Prezzo: "

addError:   .ascii      "\n        ╔═════════════════════════════════════════════════════════════╗\n" 
            .ascii      "        ║ ⚠  Impossibile aggiungere prodotto. Memoria insufficiente.  ║\n"
            .ascii      "        ║    Rimuovere un prodotto esistente e riprovare.             ║\n"
            .asciz      "        ╚═════════════════════════════════════════════════════════════╝"

// ---------------------- servono per operazioni su file ----------------------
filename:   .string     "entries.dat"
fmtRead:    .string     "r"
fmtWrite:   .string     "w"

didNotSave: .ascii      "\n                      ╔════════════════════════════════╗\n"
            .ascii      "                      ║ ⚠  Impossibile salvere i dati. ║\n"
            .asciz      "                      ╚════════════════════════════════╝"

// -------------------- servono per la funzione `filters` ---------------------
filtersOptions:
            .ascii      "\n 👉 Scegli un filtro\n\n"
            .ascii      "    0 - Indietro\n"
            .ascii      "    1 - Filtra per prezzo\n"
            .asciz      "    2 - Filtra per tipo\n\n"

filterPriceMode:
            .ascii      "\n 👉 Scegli come filtrare\n\n"
            .ascii      "    0 - Indietro\n"
            .ascii      "    1 - Fino ad un certo prezzo\n"
            .asciz      "    2 - A partire da un certo prezzo\n\n"

promptFilters:
            .asciz      "Azione (0-2) > "

fmtAgree:   .ascii      "\n    ╔═════════════════════════════════════╗\n"
            .ascii      "    ║ Stai uscendo dal menù dei filtri.   ║\n"
            .ascii      "    ║ Vuoi rendere le modifiche applicate ║\n"
            .ascii      "    ║ permanenti?                         ║\n"
            .ascii      "    ║                                     ║\n"
            .ascii      "    ║       0 - Si           1 - No       ║\n"
            .asciz      "    ╚═════════════════════════════════════╝\n\n"

prmtAgree:  .asciz      "Azione (0-1) > "

// ---------------------------------------------------------------

fmtMean:    .ascii      "    ╔═══════════════════════════╗\n"
            .ascii      "    ║ Media dei prezzi: %7.2f ║\n"
            .asciz      "    ╚═══════════════════════════╝\n"

// FINE
