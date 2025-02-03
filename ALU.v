timescale 1ns/1ps

module ALU (
    input         clk,
    input         reset,
    input  [31:0] A,
    input  [31:0] B,
    input  [3:0]  ALUControl,
    input         start,      // Assert to launch a new operation
    output reg [31:0] ALUResult,
    output reg [31:0] HI,
    output reg [31:0] LO,
    output reg        busy    // High when a multi-cycle operation is in progress
);

  // State encoding for the multi-cycle operations
  localparam IDLE = 2'b00,
             MULT = 2'b01,
             DIV  = 2'b10,
             DONE = 2'b11;
  
  reg [1:0] state;
  
  // Registers used for Booth’s multiplication
  reg [63:0] product;
  reg [5:0]  count;           // 6 bits to count from 0 to 32 (for 32 iterations)
  reg [31:0] multiplicand;

  // Combinational ALU operations (immediate, one cycle)
  // These are executed when we are in the IDLE state and start is asserted
  always @(*) begin
    // Default assignment in case none of the operations are selected.
    ALUResult = 32'b0;
    case (ALUControl)
      4'b0000: ALUResult = A + B;           // ADD
      4'b0001: ALUResult = A - B;           // SUB
      4'b0010: ALUResult = A & B;           // AND
      4'b0011: ALUResult = A | B;           // OR
      4'b0100: ALUResult = ~A;              // NOT
      4'b0101: ALUResult = A << 1;          // Logical shift left by 1
      4'b0110: ALUResult = A >> 1;          // Logical shift right by 1
      4'b0111: ALUResult = A >>> 1;         // Arithmetic shift right by 1
      // Rotate Left: wrap-around bits using OR of shifted parts.
      4'b1000: ALUResult = (A << B) | (A >> (32 - B));
      // Rotate Right:
      4'b1001: ALUResult = (A >> B) | (A << (32 - B));
      default: ALUResult = 32'b0;
    endcase
  end

  // Sequential block: handles multi-cycle operations (Multiplication and Division)
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state       <= IDLE;
      busy        <= 1'b0;
      count       <= 6'd0;
      product     <= 64'd0;
      HI          <= 32'd0;
      LO          <= 32'd0;
      ALUResult   <= 32'd0;
    end
    else begin
      case (state)
        IDLE: begin
          busy <= 1'b0;
          // Wait for a new operation to be started
          if (start) begin
            case (ALUControl)
              // Booth’s Multiplication: multi-cycle operation.
              4'b1010: begin
                busy         <= 1'b1;
                state        <= MULT;
                count        <= 6'd0;
                // Initialize product: upper half zero, lower half holds the multiplier.
                product      <= {32'd0, B};
                multiplicand <= A;
              end
              // Division: for this example, we perform it combinationally.
              4'b1011: begin
                busy <= 1'b1;
                state <= DIV;
              end
              // For all other operations we simply update ALUResult (already computed combinationally).
              default: begin
                busy  <= 1'b0;
                state <= DONE; // Go to DONE to complete one-cycle operation.
              end
            endcase
          end
        end

        // MULT state: perform Booth’s algorithm iteratively.
        MULT: begin
          if (count < 32) begin
            // Use a temporary variable to hold the next value of product.
            reg [63:0] temp;
            temp = product;
            case (product[1:0])
              2'b01: temp[63:32] = product[63:32] + multiplicand; // Add multiplicand
              2'b10: temp[63:32] = product[63:32] - multiplicand; // Subtract multiplicand
              default: ; // No operation otherwise.
            endcase
            // Perform arithmetic right shift on the entire 64-bit register.
            // Note: The arithmetic shift (>>>) propagates the sign bit.
            product <= temp >>> 1;
            count   <= count + 1;
          end
          else begin
            // After 32 iterations, assign the final product.
            HI    <= product[63:32];
            LO    <= product[31:0];
            busy  <= 1'b0;
            state <= DONE;
          end
        end

        // DIV state: perform division operation.
        DIV: begin
          // In this simple example we perform division in one clock cycle.
          if (B != 0) begin
            LO <= A / B;
            HI <= A % B;
          end
          else begin
            // Indicate an error condition.
            HI <= 32'hFFFFFFFF;
            LO <= 32'hFFFFFFFF;
          end
          busy  <= 1'b0;
          state <= DONE;
        end

        // DONE state: finalize the operation, then return to idle.
        DONE: begin
          state <= IDLE;
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule