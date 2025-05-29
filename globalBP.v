`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.02.2025 20:25:11
// Design Name: 
// Module Name: GlobalPerceptronBranchPredictor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module globalBP #(
    parameter N = 8,  // Number of history bits
    parameter M = 16  // Number of perceptrons
)(
    input clk,
    input reset,
    input [N-1:0] program_counter, // PC selects the input branch
    input branch_outcome,          // Actual branch outcome (0/1)
    output reg prediction          // Predicted branch outcome (0/1)
);

    reg signed [N:0] weights [0:M-1][0:N]; // Weight matrix [M perceptrons][N+1 weights]
    reg signed [N-1:0] branch_history; // Global history register
    reg signed [N:0] dot_product;
    wire [N-1:0] index; // XOR index for perceptron selection
    integer i,j;

    // Compute perceptron index using XOR (Step 1)
    assign index = (program_counter ^ branch_history) % M;

    // Initialize weights
    initial begin
        for (i = 0; i < M; i = i + 1) begin
            for (j = 0; j <= N; j = j + 1) begin
                weights[i][j] = 0; // Initialize all weights
            end
        end
        branch_history = 0;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < M; i = i + 1) begin
                for (j = 0; j <= N; j = j + 1) begin
                    weights[i][j] <= 0;
                end
            end
            branch_history <= 0; // Ensure branch history is reset
        end else begin
            // Step 2 & 3: Compute dot product
            dot_product = weights[index][0]; // Bias weight
            for (i = 0; i < N; i = i + 1) begin
                dot_product = dot_product + (branch_history[i] ? weights[index][i+1] : -weights[index][i+1]);
            end
            
            // Step 4: Make prediction
            prediction <= (dot_product >= 0) ? 1'b1 : 1'b0;
            
            // Step 5: Train perceptron if prediction was incorrect
            if (prediction != branch_outcome || dot_product < 2) begin
                weights[index][0] <= weights[index][0] + (branch_outcome ? 1 : -1);
                for (i = 0; i < N; i = i + 1) begin
                    weights[index][i+1] <= weights[index][i+1] + ((branch_outcome == branch_history[i]) ? 1 : -1);
                end
            end
            
            // Update global branch history
            branch_history <= {branch_history[N-2:0], branch_outcome};
        end
    end
endmodule