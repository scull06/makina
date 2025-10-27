// ALU 16-bit word
module Alu16 (
        input wire [15:0] A,
        input wire [15:0] B,
        input wire [4:0] ALUCtrl,
        output reg [15:0] Result
    );

    always @(*) begin
        case (ALUCtrl)
            5'b00000 :
                Result = A + B;                         //ADD Dst A B
            5'b00001 :
                Result = A - B;                         //SUB Dst A B
            5'b00010 :
                Result = A & B;                         //AND Dst A B
            5'b00011 :
                Result = A | B;                         //OR  Dst A B
            5'b00100 :
                Result = A ^ B;                         //XOR Dst A B
            5'b00101 :
                Result = A * B;                         //MUL Dst A B
            5'b00111 :
                Result = A / B;                         //DIV Dst A B
            5'b01000 :
                Result = ~A;                            //NOT Dst A B
            5'b01001 :
                Result = A % B;                         //MOD Dst A B
            5'b01010 :
                Result = B;                             //LDI Dst B
            5'b01100 :
                Result = (A == B) ? 16'b0000_0000_0000_0001 : 16'b0;     //CEQ Dst A B
            5'b01101 :
                Result = (A != B) ? 16'b0000_0000_0000_0001 : 16'b0;     //CNE Dst//CNQ Dst A B
            5'b01110 :
                Result =( A > B) ?  16'b0000_0000_0000_0001 : 16'b0;      //CGT Dst A B
            5'b01111 :
                Result = (A < B) ?  16'b0000_0000_0000_0001 : 16'b0;      //CLT Dst A B
            5'b10000 :
                Result = (A >= B) ? 16'b0000_0000_0000_0001 : 16'b0;     //CGE Dst A B
            5'b10001 :
                Result =( A <= B) ? 16'b0000_0000_0000_0001 : 16'b0;     //CLE Dst A B
            //CLE Dst A B

            default:
                Result = 16'b0;
        endcase
    end
endmodule
