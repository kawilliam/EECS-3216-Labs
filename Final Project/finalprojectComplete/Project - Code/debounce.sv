module button_debounce (
	input logic clk, // Clock signal
	input logic rst, // Synchronous reset (e.g., rst_sync)
	input logic button, // Raw button input
	output logic pulse,
   output logic stable// Single-cycle pulse on rising edge (debounced)
	);
	
	// Step 1: Synchronize the raw button input to avoid metastability.
	logic button_sync1, button_sync2;
	always_ff @(posedge clk or posedge rst) begin
		if (rst) begin
			button_sync1 <= 1'b0;
			button_sync2 <= 1'b0;
		end
		else begin
			button_sync1 <= button;
			button_sync2 <= button_sync1;
		end
	end
	
	// Step 2: Debounce filter using a counter.
	localparam COUNTER_MAX = 20'hFFFFF;
	logic [19:0] counter;
	logic stable_button;
	
	always_ff @(posedge clk or posedge rst) begin
	if (rst) begin
		counter <= 0;
		stable_button <= button_sync2; // Assume initial state is stable
	end
	else begin
		if (button_sync2 != stable_button)
			counter <= 0; // Restart counter when a change is detected
		else if (counter < COUNTER_MAX)
			counter <= counter + 1;
		// Once stable for enough cycles, update the stable state.
		if (counter == COUNTER_MAX)
			stable_button <= button_sync2;
		end
	end

	// Step 3: Edge detector to generate a single pulse on the rising edge.
	logic stable_button_prev;
	
	always_ff @(posedge clk or posedge rst) begin
	if (rst) begin
		stable_button_prev <= 1'b0;
		pulse <= 1'b0;
	end
	else begin
		stable_button_prev <= stable_button;
		pulse <= (~stable_button_prev) & stable_button;
	end
end
	
	assign stable = stable_button;
	
endmodule