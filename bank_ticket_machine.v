module bank_ticket_machine (
    input clk,
    input reset,
    input customer_request,
    input [3:0] officer_request, // For up to 4 officers
    input [1:0] service_type,    // Service type input
    output reg [6:0] ticket_display, // 7-segment display for ticket number
    output reg [6:0] desk_display,   // 7-segment display for desk number
    output wire [3:0] waiting_customers_display, // Number of waiting customers
    output reg [6:0] letter_display, // 7-segment display for the prefix based on service type
	 output reg [6:0] handle_ticket_number_display, // Display for ticket number being handled
	 output reg [6:0] handle_ticket_letter_display // Display for ticket letter being handled
);

    // State encoding for FSM
    parameter IDLE = 2'b00;
    parameter DISPENSE = 2'b01;
    parameter HANDLE_REQUEST = 2'b10;

    reg [1:0] current_state, next_state;
    reg [3:0] service1_count, service2_count, service3_count;
    reg [3:0] ticket_number;
    reg [3:0] waiting_customers;
    reg [1:0] current_desk;
	 reg [1:0] pre_service_type;
	 reg [3:0] pre_officer_request;
	 
	 reg [5:0] ticket_queue [0:15]; // 16-depth FIFO for ticket numbers 6bit 2 bit for letter 4 bit for ticket number
    integer head, tail; // Pointers for FIFO
    
    // FSM: State transition
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // FSM: Next state logic and output logic (Mealy)
    always @(*) begin
	     if (reset) begin
			  // Default outputs
			  next_state = current_state;
			  ticket_display = 7'b0000000;
			  desk_display = 7'b0000000;
			  letter_display = 7'b0000000;
		  end else
			  case (current_state)
					IDLE: begin
						 if (customer_request) begin
							  next_state = DISPENSE;
							  pre_service_type = service_type;
						 end else if (officer_request != 4'b0000) begin
							  next_state = HANDLE_REQUEST;
							  pre_officer_request = officer_request;
						 end
					end
					
					DISPENSE: begin
						 // Outputs based on service_type and current counts
						 case (pre_service_type)
							  2'b00: begin
									ticket_number = service1_count;
									letter_display = 7'b1110111; // A
							  end
							  2'b01: begin
									ticket_number = service2_count;
									letter_display = 7'b0011111; // b
							  end
							  2'b10: begin
									ticket_number = service3_count;
									letter_display = 7'b1001110; // C
							  end
							  default: begin
									ticket_number = 4'b0000;
									letter_display = 7'b0000000;
							  end
						 endcase
						 
						 ticket_display = ticket_to_seg(ticket_number);

						 if (officer_request != 4'b0000) begin
							  next_state = HANDLE_REQUEST;
							  pre_officer_request = officer_request;
						 end else if (!customer_request) begin
							  next_state = IDLE;
						 end
					end
					
					HANDLE_REQUEST: begin
						 // Determine current desk based on officer_request
						 case (pre_officer_request)
							  4'b0001: current_desk = 2'b00; // Desk 0
							  4'b0010: current_desk = 2'b01; // Desk 1
							  4'b0100: current_desk = 2'b10; // Desk 2
							  4'b1000: current_desk = 2'b11; // Desk 3
							  default: current_desk = 2'b00; // Default desk
						 endcase

						 desk_display = desk_to_seg(current_desk);

						 if (customer_request) begin
							  next_state = DISPENSE;
							  pre_service_type = service_type;
						 end else if (officer_request == 4'b0000) begin
							  next_state = IDLE;
							  desk_display = 7'b0000000;
							  pre_officer_request = officer_request;
						 end
					end
					
					default: next_state = IDLE;
			  endcase
    end

    // Ticket Counter Management
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            service1_count <= 4'b0000;
            service2_count <= 4'b0000;
            service3_count <= 4'b0000;
            waiting_customers <= 4'b0000;
			   head = 0;
			   tail = 0;
        end else begin
            if (next_state == DISPENSE) begin
				    if ((tail + 1) % 16 != head) begin // Check if queue is not full
						 case (pre_service_type)
							  2'b00: begin
									service1_count = service1_count + 1;
									ticket_queue[tail] = {pre_service_type, service1_count};
									tail = (tail + 1) % 16;
							  end
							  2'b01: begin
									service2_count = service2_count + 1;
									ticket_queue[tail] = {pre_service_type, service2_count};
									tail = (tail + 1) % 16;
							  end
							  2'b10: begin
									service3_count = service3_count + 1;
									ticket_queue[tail] = {pre_service_type, service3_count};
									tail = (tail + 1) % 16;
							  end
						 endcase
						 waiting_customers <= waiting_customers + 1;
					end
            end else if (next_state == HANDLE_REQUEST && head!=tail) begin
                waiting_customers <= waiting_customers - 1;
					 case (ticket_queue[head][5:4])
					     2'b00: begin
						      handle_ticket_number_display = ticket_to_seg(ticket_queue[head][3:0]);
								handle_ticket_letter_display = 7'b1110111; // A
						  end
                    2'b01: begin
						      handle_ticket_number_display = ticket_to_seg(ticket_queue[head][3:0]);
								handle_ticket_letter_display = 7'b0011111; // b
						  end
                    2'b10: begin
						      handle_ticket_number_display = ticket_to_seg(ticket_queue[head][3:0]);
								handle_ticket_letter_display = 7'b1001110; // C
						  end
                endcase
					 head = (head + 1) % 16;
            end
        end
    end

    assign waiting_customers_display = waiting_customers;

    // Function to convert ticket number to 7-segment display
    function [6:0] ticket_to_seg;
        input [3:0] num;
        begin
            case (num)
                4'b0000: ticket_to_seg = 7'b1111110; // 0
                4'b0001: ticket_to_seg = 7'b0110000; // 1
                4'b0010: ticket_to_seg = 7'b1101101; // 2
                4'b0011: ticket_to_seg = 7'b1111001; // 3
                4'b0100: ticket_to_seg = 7'b0110011; // 4
                4'b0101: ticket_to_seg = 7'b1011011; // 5
                4'b0110: ticket_to_seg = 7'b1011111; // 6
                4'b0111: ticket_to_seg = 7'b1110000; // 7
                4'b1000: ticket_to_seg = 7'b1111111; // 8
                4'b1001: ticket_to_seg = 7'b1111011; // 9
                default: ticket_to_seg = 7'b0000000; // All segments off
            endcase
        end
    endfunction

    // Function to convert desk number to 7-segment display
    function [6:0] desk_to_seg;
        input [1:0] num;
        begin
            case (num)
                2'b00: desk_to_seg = 7'b1111110; // Desk 0
                2'b01: desk_to_seg = 7'b0110000; // Desk 1
                2'b10: desk_to_seg = 7'b1101101; // Desk 2
                2'b11: desk_to_seg = 7'b1111001; // Desk 3
                default: desk_to_seg = 7'b0000000; // All segments off
            endcase
        end
    endfunction

endmodule