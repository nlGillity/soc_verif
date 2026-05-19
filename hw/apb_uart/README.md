# APB UART 

Блок представляет собой реализацию UART 16550. Доступ к регистрам UART со стороны процессора осуществляется по APB3 интерфейсу. 

# Описание регистров

Для программирования APB UART используется набор 8-битных регистров, описание которых представлено ниже.

## Register map
 RegisterName | Offset |Access | Reset Value | Description | 
 --- | --- | --- | --- | --- | 
 RBR | 0x0 | r | 0x0 | Receiver Buffer Register |
 THR | 0x0 | w | 0x0 | Transmitter Holding Register |
 DLL | 0x0 | rw | 0x0 | Divisor Latch, LSB. It's accessable when DLAB bit is set |
 IER | 0x1 | rw | 0x0 | Interrupt Enable Register |
 DLM | 0x1 | rw | 0x0 | Divisor Latch, MSB. It's accessable when DLAB bit is set |
 IIR | 0x2 | r | 0xC0 | Interrupt Identification Register |
 FCR | 0x2 | w | 0x0 | FIFO Control Register |
 LCR | 0x3 | rw | 0x0 | Line Control Register |
 LSR | 0x5 | r | 0x60 | Line Status Register |

## Receiver Buffer Register

 Name | Bits |Access | Reset Value | Description
 --- | --- | --- | --- | --- | 
 Rx Data | [7:0] | r | 0x0 | Read Character from Rx FIFO |


## Transmitter Holding Register

 Name | Bits |Access | Reset Value | Description
 --- | --- | --- | --- | --- | 
 Tx Data | [7:0] | w | 0x0 | Write Character to TX FIFO |

## Divisor Latch
The Divisor Latch is a 16-bit register, whose most
significant byte is hold in DLM and its least
significant byte is hold in DLL. The access to these
two registers, located at addresses 1 and 0
respectively, is conditioned to the value of the DLAB
bit in LCR register

### Divisor Latch, LSB

 Name | Bits |Access | Reset Value | Description
 --- | --- | --- | --- | --- | 
 DLL | [7:0] | rw | 0x0 | LSB in Divisor Latch |

### Divisor Latch, MSB

 Name | Bits |Access | Reset Value | Description
 --- | --- | --- | --- | --- | 
 DLM | [7:0] | rw | 0x0 | MSB in Divisor Latch |
 

## Interrupt Enable Register

 Name | Bits |Access | Reset Value | Description
 --- | --- | --- | --- | --- | 
  Data Ready | [0] | rw | 0x0 | Set an interrupt when:  Trigger level reached (Trigger Level field in FCR)  |
  THR empty flag | [1] | rw | 0x0 | Set an interrupt when: Tx FIFO is empty |
  Error flag | [2] | rw | 0x0 | Set an interrupt when: overrun error, parity error, framing error or break interrupt

## Interrupt Identification Register

 Name | Bits |Access | Reset Value | Description
 --- | --- | --- | --- | --- | 
  Data Ready | [3:0] | r | 0x0 | Contatins Id for interrupt:  0b0001 - Errorflag int on 0b0010 - Received data available 0b0100 - THR empty |
  Reserved | [7:4] | r | 0xC | - |

## FIFO Control Register

 Name | Bits |Access | Reset Value | Description
 --- | --- | --- | --- | --- | 
 Rx FIFO Clear | [1] | w | 0x0 | if bit is set, reset Rx FIFO  |
 Tx FIFO clear | [2] | w | 0x0 |  if bit is set, reset Tx FIFO|
 Trigger Level | [7:6] | w | 0x0 | The number of items in the Rx FIFO at which the interrupt is initiated: 0b0 - 1 0b1 - 4 0b10 - 8 0b11 - 14 |

 ## Line Control Register

  Name | Bits |Access | Reset Value | Description
 --- | --- | --- | --- | --- | 
 Len bits| [1:0] | rw | 0x0 | Count of Data bits 0b0 - 5 0b01 - 6 0b10 - 7 0b11 - 8 |
 Stop bits| [2] | rw | 0x0 | Count of Stop bits 0b0 - 1 0b1 - 2 |
 Parity  check| [3] | rw | 0x0 | Use Parity bit if this bit is set |
 DLAB  | [7] | rw | 0x0 | Divisor Latch Access Bit, DLL/DLM accessable when this bit is one|


## Line Status Register

 Name | Bits |Access | Reset Value | Description
 --- | --- | --- | --- | --- | 
 Data availabe flag | [0] | rw | 0x0 | Rx FIFO is not empty|
 Parity Error flag | [2] | rw | 0x0 | Parity error detected|
 Transmitter FIFO empty flag| [5] | rw | 0x0 | Tx FIFO is empty|
 Transmitter Empty  flag| [6] | rw | 0x0 |  Tx FIFO is empty and Uart Tx is in IDLE state |

 