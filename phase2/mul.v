module mul(input signed [31:0] m, q, output [63:0] out);

    // **Step 1: Define Booth Encoding Data Structures**
    reg [2:0] bit_pairs [15:0];  // Each bit-pair stores 3-bit recoding for Booth's algorithm
    reg signed [32:0] hold [15:0]; // Temporarily stores intermediate values (with sign extension)
    reg signed [63:0] shifted_hold [15:0]; // Holds the shifted versions of partial products
    reg signed [63:0] sum = 0;  // Accumulator to sum the shifted partial products
    
    // **Step 2: Compute Two’s Complement of the Multiplicand**
    wire signed [32:0] neg_m;  // Extra bit to handle sign extension correctly
    assign neg_m = -m;  // Compute two's complement (negation) of multiplicand

    integer i;
    
    always@(m or q or neg_m) begin
        // **Step 3: Booth Encoding - Generate 3-bit Pairs**
        // Booth encoding uses a look-ahead mechanism: 
        // each pair consists of q[i+1], q[i], q[i-1] to determine operation

        // Initialize the first pair, considering an implicit 0 at q[-1] (hence 3 bits)
        bit_pairs[0] = {q[1], q[0], 1'b0}; 

        // Generate bit pairs for the remaining bits (pairs at every 2-bit interval)
        for(i = 1; i < 16; i = i + 1) begin
            bit_pairs[i] = {q[2*i+1], q[2*i], q[2*i-1]};
        end

        // **Step 4: Decode Booth Encoded Values into Partial Products**
        for(i = 0; i < 16; i = i + 1) begin
            case (bit_pairs[i])
                3'b001, 3'b010 :  hold[i] = {m[31], m}; // +M (multiplicand with sign extension)
                3'b011 : hold[i] = {m, 1'b0};          // +2M (shift left M once)
                3'b100 : hold[i] = {neg_m[31:0], 1'b0}; // -2M (shift left negated M once)
                3'b101, 3'b110 : hold[i] = neg_m;     // -M (negated multiplicand)
                default: hold[i] = 0;                 // 3'b000 and 3'b111 → No operation (0)
            endcase

            // **Step 5: Shift Partial Product Accordingly**
            // Shift hold[i] left by (2*i) bits to align the partial product in the final sum
            shifted_hold[i] = hold[i] << (2*i);
        end

        // **Step 6: Accumulate Partial Products**
        sum = shifted_hold[0];  // Initialize with the first partial product
        for(i = 1; i < 16; i = i + 1) begin
            sum = sum + shifted_hold[i];  // Accumulate the shifted values
        end
    end

    // **Step 7: Assign Output**
    assign out = sum;  // The final multiplication result (HI:LO)

endmodule
