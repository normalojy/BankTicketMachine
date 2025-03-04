# BankTicketMachine
A Verilog-based bank ticket machine using FSM and FIFO to manage customer queues and service requests.

## Objective
To design and implement a digital bank ticketing system that efficiently manages customer queues and service allocation using Verilog HDL.

## Features
- Supports 3 different bank services with unique ticket prefixes.
- Handles up to 4 bank officers.
- 16 depth FIFO-based queue management.
- 7-segment display for ticket and desk numbers.
- Functional verification using ModelSim.

## How It Works
1. Customers request a ticket based on the selected service type.
2. The machine assigns a ticket number and updates the queue.
3. Bank officers request the next ticket, and the assigned ticket is displayed.
4. FIFO ensures proper queue management.

## Files
- bank_ticket_machine.v - Main Verilog Code

## FLowchart
![Bank Ticket Machine FLowchart](https://github.com/user-attachments/assets/82ab77ec-a5df-47fb-be19-4237df8f2dd5)
