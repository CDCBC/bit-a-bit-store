// SPDX-License-Identifier: GPL-3.0-only
//
// bit-a-bit_store.s -- Single project source file
//
// Copyright © 2023  Silvio Bartolotta
// Copyright © 2023  Alfredo Carlino
// Copyright © 2023  Giorgio Carlino
// Copyright © 2023  Alessandro Cava
// Copyright © 2023  Mario D'Andrea <https://ormai.dev>

//                ____ ____  _   _ ____  ____   ___     _ _  _
//               / ___|  _ \| | | |  _ \|  _ \ / _ \   / | || |
//              | |  _| |_) | | | | |_) | |_) | | | |  | | || |_
//              | |_| |  _ <| |_| |  __/|  __/| |_| |  | |__   _|
//               \____|_| \_\\___/|_|   |_|    \___/   |_|  |_|

//                                 TECH STORE

/* Structure of this file                      (line)
       - macros
            - removeProduct________________________58
            - swapProducts_________________________87
            - readInt_____________________________124
            - readStr_____________________________138
            - saveTo______________________________150
       - functions and procedures
            - main________________________________171
            - load________________________________229
            - save________________________________267
            - printTable__________________________310
            - printTUI____________________________391
            - addProduct__________________________410
            - remove______________________________472
            - swap________________________________502
            - removeDuplicatePrice________________544
            - filters_____________________________595
            - filterByPrice_______________________685
            - filterByType________________________732
            - sort________________________________790
            - bubbleSort__________________________842
            - meanPrice___________________________858
       - memory
           - .bss_________________________________895
           - .data________________________________903
           - .rodata______________________________924
*/

// MACROS

            // Removes the product with index in w0
            .macro      removeProduct
            stp         x0, x1, [sp, #-16]!
            stp         x2, x3, [sp, #-16]!

            ldr         w2, nProducts
            sub         w2, w2, w0              // nProducts - index

            mov         w3, productSize
            mul         w1, w0, w3              // offset = index * productSize

            ldr         x0, =products
            add         x0, x0, x1              // [dest] products[w0]
            add         x1, x0, x3              // [src]  products[w0 + productSize]
            mul         w2, w2, w3              // byte to copy (48)
            bl          memcpy

            // Computes and saves the new value of nProducts
            ldr         x0, =nProducts
            ldr         w1, [x0]
            sub         w1, w1, #1              // nProducts -= 1
            str         w1, [x0]

            ldp         x2, x3, [sp], #16
            ldp         x0, x1, [sp], #16
            .endm



            .macro      swapProducts
            // Swaps two products with indices in w0 and s1 by using memcpy fom libc
            stp         x19, x20, [sp, #-16]!
            stp         x21, x22, [sp, #-16]!
            sub         sp, sp, productSize     // increase the sp by 48 bytes

            mov         w19, w0
            mov         w20, w1
            ldr         x21, =products
            mov         w22, productSize

            // 1. Copy the product with index in w0 on the stack (w0 -> stack)
            mov         x0, sp                  // [dest] stack pointer
            madd        x1, x19, x22, x21       // [src]  products[w0]
            mov         w2, productSize         // bytes to copy (48)
            bl          memcpy

            // 2. Copy the product with index in w1 in w0 (w1 -> w0)
            madd        x0, x19, x22, x21       // [dest] products[w0]
            madd        x1, x20, x22, x21       // [src]  products[w1]
            mov         w2, productSize         // bytes  to copy (48)
            bl          memcpy

            // 4. Copy the product on the stack in w1 (stack -> w1)
            madd        x0, x20, x22, x21       // [dest] products[w1]
            mov         x1, sp                  // [src]  stack pointer
            mov         w2, productSize         // bytes to copy (48)
            bl          memcpy

            add         sp, sp, productSize     // decrement the sp by 48 bytes
            ldp         x21, x22, [sp], #16
            ldp         x19, x20, [sp], #16
            .endm



            // Reads an integer from standard input and saves it at tmpInt
            .macro      readInt prompt
            adr         x0, \prompt
            bl          printf

            adr         x0, scanInt
            adr         x1, tmpInt
            bl          scanf

            ldr         x0, tmpInt
            .endm



            // Reads a string from standard input and saves it at dest
            .macro      readStr prompt dest
            adr         x0, \prompt
            bl          printf

            adr         x0, scanStr
            adr         x1, tmpStr
            bl          scanf
            .endm



            // Saves a string from tmpStr to the address in item
            .macro      saveTo item, offset, size
            add         x0, \item, \offset      // address from which to copy
            ldr         x1, =tmpStr             // string to copy
            mov         x2, \size               // length of the string in bytes
            bl          strncpy

            add         x0, \item, \offset + \size - 1 // clean up the memory
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

            bl          load                    // 1. Load from the file

begin:      bl          printTUI                // 2. Print the TUI

noTUI:      readInt     prmtMenu                // 3. Read the option

            // 4. Controlla opzione
option0:    cmp         w0, #0                  // Option 0: quit
            beq         return

option1:    cmp         w0, #1                  // Option 1: add item
            bne         option2
            bl          addProduct

option2:    cmp         w0, #2                  // Option 2: remove item
            bne         option3
            bl          remove

option3:    cmp         w0, #3                  // opzione 3: filtri
            bne         option4
            bl          filters

option4:    cmp         w0, #4                  // Option 3: swap items
            bne         option5
            bl          swap

option5:    cmp         w0, #5                  // Options 5: remove duplicate
            bne         option6
            bl          removeDuplicatePrice

option6:    cmp         w0, #6                  // Option 6: sort first two items
            bne         option7
            bl          sort

option7:    cmp         w0, #7                  // Option 7: sort by stocks
            bne         option8
            bl          bubbleSort

option8:    cmp         w0, #8                  // Option 8: floating point
            bne         noOption                //           average
            bl          meanPrice               // Print the mean and not the
            b           noTUI                   // table

noOption:   b           begin                   // 5. Repeat

return:     mov         w0, wzr                 // 6. Terminate
            ldp         x29, x30, [sp], #16
            ret
            .size        main, (. - main)

// (procedure) Loads the contents of a file named 'entries.dat' at the address
// of the label 'products'.
            .type       load, %function
load:       stp         x29, x30, [sp, #-16]!
            str         x19, [sp, #-16]!

            adr         x0, filename
            adr         x1, fmtRead
            bl          fopen                   // open the file for read

            cmp         x0, xzr                 // if fopen returns NULL we
            beq         loadReturn              // bail out, otherwise
            mov         x19, x0                 // copy in x19 the FILE pointer

            ldr         x0, =nProducts          // address to save
            mov         x1, #4                  // item size in bytes
            mov         x2, #1                  // number of elements
            mov         x3, x19                 // file stream pointer
            bl          fread

            // loads the actual items from the file
            ldr         x0, =products
            mov         x1, productSize
            mov         x2, nMaxProducts
            mov         x3, x19
            bl          fread

            mov         x0, x19                 // close the file a which the
            bl          fclose                  // address in x0 points to

loadReturn: ldr         x19, [sp], #16
            ldp         x29, x30, [sp], #16
            ret
            .size       load, (. - load)

// (procedure) Stores the data at the label 'products' in a file named
// 'entries.dat'.
            .type       save, %function
save:       stp         x29, x30, [sp, #-16]!
            str         x19, [sp, #-16]!

            adr         x0, filename
            adr         x1, fmtWrite
            bl          fopen                   // open the file
            // if the call to fopen returns NULL bail out
            cmp         x0, xzr
            beq         couldNotSave
            mov         x19, x0     // if it goes well, copy in x19 the pointer

            // write the number of lines in the list
            ldr         x0, =nProducts          // address from which to save
            mov         x1, #4                  // item size
            mov         x2, #1                  // number of items
            mov         x3, x19                 // file pointer
            bl          fwrite

            // write products in the file
            ldr         x0, =products
            mov         x1, productSize
            mov         x2, nMaxProducts
            mov         x3, x19
            bl          fwrite

            mov         x0, x19
            bl          fclose                  // close the file
            b           saveReturn              // success -> terminate

couldNotSave: // handle error
            adr         x0, didNotSave
            bl          printf

saveReturn: ldr         x19, [sp], #16
            ldp         x29, x30, [sp], #16
            ret
            .size       save, (. - save)

// Prints the table

            .type       printTable, %function
            .global     printTable
printTable: stp         x29, x30, [sp, #-16]!
            stp         x19, x20, [sp, #-16]!
            str         x21, [sp, #-16]!

            adr         x0, header              // Table header
            bl          printf

            mov         w19, wzr                // index
            ldr         x20, =products          // address of the struct
            ldr         w21, nProducts          // number of products in memory

loopRows:   cmp         w19, w21
            beq         endLoopRows // if index >= nProducts: break

            adr         x0, fmtEntry            // line format
            add         w1, w19, #1             // #
            add         x2, x20, offsetEan      // id
            add         x3, x20, offsetName     // product

            // the type field is a number, to which we associate a string
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

endIfType:  ldr         w5, [x20, offsetStock]  // stocks

            ldr         w6, [x20, offsetPrice]  // price
            bl          printf                  // print line

            add         w19, w19, #1            // increment index
            add         x20, x20, productSize   // go to the next product
            b           loopRows

endLoopRows:
            adr         x0, footer              // close the table
            bl          printf

            mov          w0, #0
            ldr         x21, [sp], #16
            ldp         x19, x20, [sp], #16
            ldp         x29, x30, [sp], #16
            ret
            .size        printTable, (. - printTable)

// (procedure) Prints the user interface with the options and the table.
            .type       printTUI, %function
            .global     printTUI
printTUI:   stp         x29, x30, [sp, #-16]!

            bl          printTable              // print the table

            adr         x0, options
            bl          printf

            mov         w0, wzr
            ldp         x29, x30, [sp], #16
            ret
            .size       printTUI, (. - printTUI)

// (procedure) Add a new product whose fields are read from standard input.
// It also writes in the file.
            .type       addProduct, %function
            .global     addProduct
addProduct: stp         x29, x30, [sp, #-16]!
            stp         x19, x20, [sp, #-16]!

            ldr         w19, nProducts          // number of products in memory

            cmp         w19, nMaxProducts       // if we reached the max number
            bge         didNotAdd               // of products: bail out

            ldr         x20, =products          // struct array address
            mov         w0, productSize         // size of each item
            mul         w0, w19, w0             // array size right now
            add         x20, x20, x0            // last product end address

            // read fields from standard input
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

            // increment nProducts by 1 and save it
            add         w19, w19, #1
            ldr         x20, =nProducts
            str         w19, [x20]

            // save the structure just modified
            bl          save
            b           addReturn

didNotAdd:  adr         x0, addError
            bl          printf

addReturn:  ldp         x19, x20, [sp], #16
            mov         w0, wzr
            ldp         x29, x30, [sp], #16
            ret
            .size        addProduct, (. - addProduct)

// (procedure) Removes a product from the array
            .type       remove, %function
            .global     remove
remove:     stp         x29, x30, [sp, #-16]!

            ldr         w0, nProducts           // if the table is empty:
            cbz         w0, removeReturn        // do nothing

            readInt     prmtIndex               // read the position from input

            cmp         w0, #1                  // if index < 1: bail out
            blt         removeReturn

            ldr         w1, nProducts
            cmp         w0, w1                  // if index > nProducts:
            bgt         removeReturn            // bail out

            sub         w0, w0, #1              // from position to index
            removeProduct
            bl          save

removeReturn:
            ldp         x29, x30, [sp], #16
            ret
            .size        remove, (. - remove)

// (procedure) Swaps two items in the table after prompting the user.
            .type       swap, %function
            .global     swap
swap:       stp         x29, x30, [sp, #-16]!
            stp         x19, x20, [sp, #-16]!

            ldr         w20, nProducts
            // read the two integers and check that they are valid
            readInt     prmtIndex
            mov         w19, w0                 // `readInt` needs w0
            cmp         w19, w20                // Check that the first user
            bgt         swapReturn              // provided integer is in the
            cmp         w19, #1                 // valid range.
            blt         swapReturn

            readInt     prmtIndex               // now check the other number
            cmp         w0, w20
            bgt         swapReturn
            cmp         w0, #1
            blt         swapReturn

            cmp         w0, w19     // if the user gave the same number twice:
            beq         swapReturn  // do nothing

            // transform the position in indices
            sub         w0, w0, #1              // w0 -= 1
            sub         w1, w19, #1             // w1 -= 1

            swapProducts                        // do the swap
            bl          save

swapReturn: mov         w0, wzr
            ldp         x19, x20, [sp], #16
            ldp         x29, x30, [sp], #16
            ret
            .size        swap, (. - swap)

// Removes the first item that has the same value for the price field of the
// item in the next row.
            .type       removeDuplicatePrice, %function
            .global     removeDuplicatePrice
removeDuplicatePrice:
            stp         x29, x30, [sp, #-16]!

            mov         w1, productSize
            ldr         x2, =products

            mov         w0, #0                  // previous item index
            mul         w3, w1, w0              // previous item offset
            add         x3, x2, x3              // first item address

            add         w6, w0, #1              // next item index
            mul         w4, w1, w6              // next item offset
            add         x4, x2, x4              // first item address

            ldr         w7, nProducts
loopRemoveDuplcatePrice:
            cmp         w6, w7      // when the index reaches productSize:
            bge         endLoopRemoveDuplicatePrice    // bail out

            ldr         w9, [x3, offsetPrice]   // previous item price
            ldr         w10, [x4, offsetPrice]  // next item price

ifDuplicatePrice:
            cmp         w9, w10                 // if the two prices are the
            bne         endIfDupicatePrice      // same
            removeProduct                       // remove the first product

endIfDupicatePrice:     // prepare for the next iteration
            add         w0, w0, #1              // increment previous index
            add         w6, w6, #1              // increment next index
            add         x3, x3, productSize
            add         x4, x4, productSize
            b           loopRemoveDuplcatePrice

endLoopRemoveDuplicatePrice:
            bl          save                    // save the array in the file
            mov         w0, wzr
            ldp         x29, x30, [sp], #16
            ret
            .size       removeDuplicatePrice, (. - removeDuplicatePrice)


// (procedure) Manages the filters. Manages the filter selection from the user.
// If the user chooses 0, or a number other than 0, 1, 2, the interface goes
// back to the main menu. If the user inserts a correct option, this functions
// prepares a set of parameters and calls the respective filter function.
            .type       filters, %function
            .global     filters
filters:    stp         x29, x30, [sp, #-16]!
            stp         x19, x20, [sp, #-16]!

filtersLoop:
            bl          printTable              // print the table

whichFilter:
            adr         x0, filtersOptions
            bl          printf
            readInt     promptFilters           // read the option from
            mov         w19, w0                 // standard input

filtersOption0:
            cmp         w19, #0                 // if the option is 0:
            beq         filtersReturn           //     bail out

filtersOptions1:
            cmp         w19, #1                 // ### filter by price ###
            bne         filtersOption2          // if option != 1 go to option 2

            adr         x0, filterPriceMode     // ask how to filter
            bl          printf
            readInt     promptFilters           // mode to pass in w2
            mov         w20, w0

            // it doesn't make sense to ask the price if the user chose 1 or 2
            cmp         w20, wzr                // if the user choose 0
            beq         whichFilter             // go back

            // check that the choice was 1 or 2
            cmp         w20, #1
            beq         callFilterByPrice
            cmp         w20, #2
            beq         callFilterByPrice
            b           filtersOptions1         // ask how to filter

callFilterByPrice:
            readInt     prmtPrice               // ask for a price and put it
            mov         w1, w0                  // in w1
            ldr         w0, nProducts
            sub         w0, w0, #1              // nprods -= 1 in w0
            mov         w2, w20                 // mode
            bl          filterByPrice

            //bl          save                  // save only one time
            b           filtersLoop             // done, repeat menu

filtersOption2:
            cmp         w19, #2                 // ### filter by type ###
            bne         filtersLoop             // if option != 2 ask again
            bl          filterByType

            b           filtersLoop

filtersReturn:
// asks the user whether to apply the filter permanently
// - if the user types 1 saves the effects of the filters
// - if the users types 0 reloads the previous state of the table
            adr         x0, fmtAgree
            bl          printf

            readInt     prmtAgree                           // read input
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

// Filters the products that are greater or smaller of a some price. Mode and
// price are chosen by the user. Takes:
//   - (nProducts - 1) in w0
//   - the prices chosen by the user in w1
//   - an integer that can be 1 or 2 in w1 (1 for '<=' and 2 for '>=')
// Returns: (nProducts - 1) if it is not smaller than zero, otherwise nothing


            .type       filterByPrice, %function
            .global     filterByPrice
filterByPrice:
            stp         x29, x30, [sp, #-16]!

filterByPriceBaseCase:
            cmp         w0, #0                  // if the index < 0:
            blt         filterByPriceReturn     // bail out

            // load in w3 the price of the last product
            ldr         x4, =products           // array address
            mov         w5, productSize
            madd        x6, x0, x5, x4          // x6 = x4 + (x0 * x5)
            ldr         w3, [x6, offsetPrice]   // go to the product price

lessOrEqualToMode:
            cmp         w2, #1                  // until some price
            bne         greaterOrEqualToMode

            cmp         w3, w1
            bgt         deleteProduct
            b           next

// We know that if w2 doesn't contain 1, then it contains 2 (see 'filters')
greaterOrEqualToMode:
            cmp         w3, w1 // if (list price < user price): remove
            blt         deleteProduct
            b           next

deleteProduct:
            removeProduct

next:       sub         w0, w0, #1              // decrease index argument
            bl          filterByPrice           // <-- recursive call -->

filterByPriceReturn:
            mov         w0, wzr                 // when the base case fails
            ldp         x29, x30, [sp], #16
            ret
            .size        filterByPrice, (. - filterByPrice)

// (procedure) Asks the user one of the available ways to filter the table.
// Then scans the table and removes any product whose type differs from the one
// chosen by the user.
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

            readInt    prmtType                 // ask type

            // check whether the type is in range
            cmp         w0, #1
            blt         filterByTypeEndLoop
            cmp         w0, #6
            bgt         filterByTypeEndLoop 
            mov         w1, w0

            ldr         w0, nProducts           // i = len(products)
            sub         w0, w0, #1              // i -= 1
            mov         w2, productSize
            adr         x3, products            // array start
            madd        x3, x2, x0, x3          // address of last item

filterByTypeLoop:
            cmp         w0, #0                  // when i < 0
            blt         filterByTypeEndLoop     // break from the loop

            ldr         w2, [x3, offsetType]    // go to the product type

filterByTypeIf:
            cmp         w1, w2      // if they differ remove the line
            beq         filterByTypeEndIf
            removeProduct

filterByTypeEndIf:
            sub         x3, x3, productSize     // go to the previous product
            sub         w0, w0, #1              // i--;
            b           filterByTypeLoop        // repeat

filterByTypeEndLoop:
            //bl          save                  // save only one time
            mov         w0, wzr
            ldp         x29, x30, [sp], #16
            ret
            .size        filterByType, (. - filterByType)


// Swaps the first pair of items whose stocks field is not sorted in increasing
// order. Returns 1 if a swap happened, 0 otherwise.
            .type       sort, %function
            .global     sort
sort:       stp         x29, x30, [sp, #-16]!
            ldr         x19, [sp, #-16]!

            ldr         w7, nProducts
            mov         w10, wzr                // previous product
            add         w9, w10, #1             // current product
            adr         x11, products

scanTable:  cmp         w9, w7                  // when we reach the end of the
            bge         endScan                 // array: termina

            // current quantity
            mov         w0, productSize
            // current row = current index * productSize + products
            madd        x0, x9, x0, x11
            ldr         w1, [x0, offsetStock]

            // previous quantity
            mov         w2, productSize
            // previous row = previous index * productSize + products
            madd        x2, x10, x2, x11
            ldr         w3, [x2, offsetStock]

            // check whether the previous quantity is bigger than the current
            cmp         w3, w1
            bgt         doTheSwap

            // go to the next
            add         w10, w10, #1            // previous product index
            add         w9, w9, #1              // current product index
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

// Sort the full table by stocks in increasing order
            .type       bubbleSort, %function
            .global     bubbleSort
bubbleSort: stp         x29, x30, [sp, #-16]!

swapThem:   bl          sort
            cmp         w0, #1      // if there was a swap repeat
            beq         swapThem

            ldp         x29, x30, [sp], #16
            ret
            .size       bubbleSort, (. - bubbleSort)

// (procedure) Computes the floating point average of the prices.
            .type       meanPrice, %function
            .global     meanPrice
meanPrice:  stp         x29, x30, [sp, #-16]!

            fmov        s0, wzr                 // sum
            mov         w1, wzr                 // index
            ldr         w2, nProducts
            cmp         w2, wzr                 // if the table is empty:
            beq         meanPriceReturn         //      bail out
            adr         x3, products

sumLoop:    ldr         w4, [x3, offsetPrice]   // post-test loop
            ucvtf       s4, w4                  // n=products[w1][offsetPrice]

            fadd        s0, s0, s4              // sum += n
            add         w1, w1, #1              // w1 += 1
            add         x3, x3, productSize     // next product

            cmp         w1, w2                  // until index < nProducts:
            blt         sumLoop                 //     repeat

sumEndloop: ucvtf       s1, w1                  // convert index to float
            fdiv        s0, s0, s1              // compute the mean

            fcvt        d0, s0                  // convert the mean to double
            adr         x0, fmtMean             // print
            bl          printf

meanPriceReturn:
            ldp         x29, x30, [sp], #16
            ret
            .size       meanPrice, (. - meanPrice)

// MEMORY

            .bss
products:   .skip       nMaxProducts * productSize // allocate memory for data

            // used temporarily by scanf to read from standard input
tmpStr:     .skip       128
tmpInt:     .skip       8

// ----------------------------------------------------------------------------
            .data
nProducts:  .word       0 // current number of products in the list

            // struct product {...};

            .equ        sizeEan, 14             // 13 chars + \0
            .equ        sizeName, 21            // 20 chars + \0
            .equ        sizeType, 4
            .equ        sizeStock, 4
            .equ        sizePrice, 4

            .equ        offsetEan, 0
            .equ        offsetName, (offsetEan + sizeEan)       // 0 + 14 = 14
            .equ        offsetType, (offsetName + sizeName)     // 14 + 17 = 31
            .equ        offsetStock, (offsetType + sizeType)    // 31 + 4 = 35
            .equ        offsetPrice, (offsetStock + sizeStock)  // 35 + 4 = 39

            .equ        productSize, 48  // 47 aligned to the multiple of 16 > 43
            .equ        nMaxProducts, 10 // max number of products in the list

// ----------------------------------------------------------------------------
            .section    .rodata
header:     .ascii      "\n"
            .ascii      "                        ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\n"
            .ascii      "                        ┃       Bit-a-Bit Store       ┃\n"
            .ascii      "                        ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n"
            .ascii      "┌─────┬───────────────┬──────────────────────┬──────────────┬────────┬────────┐\n"
            .ascii      "│ #   │ EAN           │ Product              │ Type         │ Stocks │ Price  │\n"
            .asciz      "├─────┼───────────────┼──────────────────────┼──────────────┼────────┼────────┤\n"

fmtEntry:   .asciz      "│ %3d │ %-13s │ %-20s │ %-12s │ %6d │ %6d │\n"

footer:     .asciz      "└─────┴───────────────┴──────────────────────┴──────────────┴────────┴────────┘\n"

fmtTypes:   .asciz      "\n 👉 Choose a type\n\n    1 - %s\n    2 - %s\n    3 - %s\n    4 - %s\n    5 - %s\n    6 - %s\n\n"
type1:      .asciz      "computer"
type2:      .asciz      "connector"
type3:      .asciz      "network"
type4:      .asciz      "print/scan"
type5:      .asciz      "tool"
type6:      .asciz      "component"
noneType:   .asciz      "none"

options:    .ascii      "\n 👉 Choose an action\n\n"
            .ascii      "    0 - Quit\n"
            .ascii      "    1 - Add a new product\n"
            .ascii      "    2 - Remove a product\n"
            .ascii      "    3 - Apply a filter\n"
            .ascii      "    4 - Swap two products\n"
            .ascii      "    5 - Remove the first of two consecutive products\n"
            .ascii      "        with the same price\n"
            .ascii      "    6 - Swap the first two products not sorted by stocks\n"
            .ascii      "    7 - Sort by stocks in incresing order\n"
            .asciz      "    8 - Compute the floating point price average\n\n"

prmtMenu:   .asciz      "Action (0-8) > "

scanInt:    .asciz      "%d"
scanStr:    .asciz      "%127s"

prmtIndex:  .asciz      "Product position (out of range to cancel): "

// used by 'addProduct'
prmtEan:    .asciz      "EAN: "
prmtName:   .asciz      "Product (no spaces): "
prmtType:   .asciz      "Type (1-6): "
prmtStock:  .asciz      "Stocks: "
prmtPrice:  .asciz      "Price: "

addError:   .ascii      "\n           ╔═══════════════════════════════════════════════════════╗\n" 
            .ascii      "           ║ ⚠  Couldn't add product because we are out of memory. ║\n"
            .ascii      "           ║         Remove an exising product and try again.      ║\n"
            .asciz      "           ╚═══════════════════════════════════════════════════════╝"

// used for file operations
filename:   .string     "entries.dat"
fmtRead:    .string     "r"
fmtWrite:   .string     "w"

didNotSave: .ascii      "\n                              ╔════════════════════════╗\n"
            .ascii      "                              ║ ⚠  Couldn't save data. ║\n"
            .asciz      "                              ╚════════════════════════╝"

// used by 'filters'
filtersOptions:
            .ascii      "\n 👉 Choose a filter\n\n"
            .ascii      "    0 - Go back\n"
            .ascii      "    1 - Filter by price\n"
            .asciz      "    2 - Filter by type\n\n"

filterPriceMode:
            .ascii      "\n 👉 Choose how to filter\n\n"
            .ascii      "    0 - Go back\n"
            .ascii      "    1 - Until a certain price\n"
            .asciz      "    2 - From a certain price\n\n"

promptFilters:
            .asciz      "Action (0-2) > "

fmtAgree:   .ascii      "\n    ╔════════════════════════════════════╗\n"
            .ascii      "    ║ You are about to leave the filters ║\n"
            .ascii      "    ║    menu. Do you want to make the   ║\n"
            .ascii      "    ║         changes permanent?         ║\n"
            .ascii      "    ║                                    ║\n"
            .ascii      "    ║       0 - Yes          1 - No      ║\n"
            .asciz      "    ╚════════════════════════════════════╝\n\n"

prmtAgree:  .asciz      "Action (0-1) > "

// ---

fmtMean:    .ascii      "    ╔════════════════════════╗\n"
            .ascii      "    ║ Average price: %7.2f ║\n"
            .asciz      "    ╚════════════════════════╝\n"

// END
