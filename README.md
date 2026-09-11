# Systolic-Array-AI-Inference-Engine-
This project will help me solidify my understanding of a systolic array AI engine. It will utilize 256 Processing Elements to do the core computation of matrix multiplication. This design will also utilize DMA engines, FSM controller and SRAM streamers to help finalize the design. 

# Design Specifications

- matrix equation = C = AxB
- Array size: 16x16 PEs
- PE count: 256 PEs
- Data type for input: signed INT8 (signed 8 bit integer)
- Data type for product: signed INT16 (signed 16 bit integer)
- Data type for output: signed INT32 (signed 32 bit integer)
- Clock Target: TBD
- skew: FIFO registers/shift registers on row A and column B

## Processing Element Design
The primary role of the processing element is to perform matrix multiplication within a systolic array architecture. When clear_acc is 1 or set to high, it will set the accumulator register to zero so it is no longer in an unknown state so that the computation can start or start a new set of computations. Each PE, which will be designed to be modular, will receive INT8 inputs A_in from the left and B_in from the top. After receiving the A_in and B_in whenever valid_in is 1 or high, it will do the dot product or A_in x B_in. It will then continue to accumulate the value by doing the summation of the product as long as valid_in is 1 or set to high. It will also be responsible to send the A_in and B_in to its neighboring PEs so that they can then get the values at a later clock cycle. When output_enable is 1 or set to high it is expected to start "Draining" the PEs and send C_out into either the PE below it in the 16x16 grid or to send it to a SRAM streamer to collect the output. 

## Finite State Machine Design
