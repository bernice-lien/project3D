/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

// This module monitors the data from UART
// It also assembles and writes the data into the SRAM
module M1_SRAM_interface (
   input  logic		Clock,
   input  logic		Resetn, 
   input  logic   [15:0]   SRAM_read_data,
   input  logic		M1_start,
   
   output logic [17:0]	SRAM_address,
   output logic [15:0]	SRAM_write_data,
   output logic		SRAM_we_n,
   output logic 	M1_stop
);

M1_SRAM_state_type M1_SRAM_state;
// Initialize Multipliers
logic [31:0] M_a1, M_a2, M_ar, M_b1, M_b2, M_br, M_c1, M_c2, M_cr, M_d1, M_d2, M_dr;
logic [63:0] M_arl, M_brl, M_crl, M_drl;

assign M_arl = M_a1 * M_a2;
assign M_ar = M_arl[31:0];

assign M_brl = M_b1 * M_b2;
assign M_br = M_brl[31:0];

assign M_crl = M_c1 * M_c2;
assign M_cr = M_crl[31:0];

assign M_drl = M_d1 * M_d2;
assign M_dr = M_drl[31:0];

// Initialize U,V,Y registers and buffers
logic [7:0] Ureg[9:0];
logic [7:0] Vreg[9:0];
logic [7:0] Ubuff, Vbuff;
logic [7:0] Yeven, Yodd;

// Intialize calculation buffers
logic [31:0] U_calc; 
logic [31:0] V_calc; 


// Initialize R,G,B storage
logic [31:0] Re_accum, Ge_accum, Be_accum, Ro_accum, Go_accum, Bo_accum;
logic [7:0] Re_c, Ge_c, Be_c, Ro_c, Go_c, Bo_c;

assign Re_c = $signed(Re_accum[31]) ? 8'h00 : (|$signed(Re_accum[30:23])) ? 8'hFF : $signed(Re_accum[22:15]);
assign Ge_c =  $signed(Ge_accum[31]) ? 8'h00 : (|$signed(Ge_accum[30:23])) ? 8'hFF :  $signed(Ge_accum[22:15]);
assign Be_c = $signed(Be_accum[31]) ? 8'h00 : (|$signed(Be_accum[30:23])) ? 8'hFF : $signed(Be_accum[22:15]);
assign Ro_c = $signed(Ro_accum[31]) ? 8'h00 : (|$signed(Ro_accum[30:23])) ? 8'hFF : $signed(Ro_accum[22:15]);
assign Go_c = $signed(Go_accum[31]) ? 8'h00 : (|$signed(Go_accum[30:23])) ? 8'hFF : $signed(Go_accum[22:15]);
assign Bo_c = $signed(Bo_accum[31]) ? 8'h00 : (|$signed(Bo_accum[30:23])) ? 8'hFF : $signed(Bo_accum[22:15]);



// Initialize address offset
logic [17:0] SRAM_address_Y, SRAM_address_U, SRAM_address_V, SRAM_address_RGB;
 
// Initialize Flags
logic parity;
logic [7:0] leadout;
logic [1:0] writeoff;

// Receive data from UART
always_ff @ (posedge Clock or negedge Resetn) begin
	if (~Resetn) begin
		SRAM_we_n <= 1'b1;
		SRAM_write_data <= 16'd0;
		SRAM_address <= 18'd0;
        M1_stop <= 1'b0;
        SRAM_address_Y <= 18'd0;
        SRAM_address_U <= 18'd13824;
        SRAM_address_V <= 18'd20736;
        SRAM_address_RGB <= 18'd220672;
		M1_SRAM_state <= M1_IDLE;
        parity <= 1'b0;
        leadout <= 8'b0; 
        writeoff <= 2'd2;
        Ureg[0]<=8'b0;
        Ureg[1]<=8'b0;
        Ureg[2]<=8'b0;
        Ureg[3]<=8'b0;
        Ureg[4]<=8'b0;
        Ureg[5]<=8'b0;
        Ureg[6]<=8'b0;
        Ureg[7]<=8'b0;
        Ureg[8]<=8'b0;
        Ureg[9]<=8'b0;
        Vreg[0]<=8'b0;
        Vreg[1]<=8'b0;
        Vreg[2]<=8'b0;
        Vreg[3]<=8'b0;
        Vreg[4]<=8'b0;
        Vreg[5]<=8'b0;
        Vreg[6]<=8'b0;
        Vreg[7]<=8'b0;
        Vreg[8]<=8'b0;
        Vreg[9]<=8'b0;
        Ubuff<=8'b0;
        Vbuff<=8'b0;
        Yeven<=8'b0;
        Yodd<=8'b0;
        U_calc<=32'b0; 
        V_calc<=32'b0; 
	end else begin

        case (M1_SRAM_state)
        
        M1_IDLE: begin
            if (M1_start == 1'b1) begin
                // Calling U address
                SRAM_we_n <= 1'b1;
                SRAM_address <= SRAM_address_U;
                leadout <= 8'b0;
                writeoff <= 2'd2;
                M1_SRAM_state <= M1_LEAD_IN0;
            end
        end
    
    //********************************************* Lead In  *********************************************//
        M1_LEAD_IN0: begin
            // Calling V address and incrementing U address
            SRAM_address <= SRAM_address_V;
            SRAM_address_U <= SRAM_address_U + 18'd1;
            M1_SRAM_state <= M1_LEAD_IN1;
        end

        M1_LEAD_IN1: begin
            // Calling U address and incrementing V address
            SRAM_address <= SRAM_address_U;
            SRAM_address_V <= SRAM_address_V + 18'd1;

            M1_SRAM_state <= M1_LEAD_IN2;
        end
        // Start Reading Data U0,U1

        M1_LEAD_IN2: begin
            // Calling V address and incrementing U address
            SRAM_address <= SRAM_address_V;
            SRAM_address_U <= SRAM_address_U + 18'd1;
            // Loading U value from SRAM to shift register
            Ureg[0] <= SRAM_read_data[15:8];
            Ureg[1] <= SRAM_read_data[15:8];
            Ureg[2] <= SRAM_read_data[15:8];
            Ureg[3] <= SRAM_read_data[15:8];
            Ureg[4] <= SRAM_read_data[15:8];
            Ureg[5] <= SRAM_read_data[7:0];


            M1_SRAM_state <= M1_LEAD_IN3;
        end

        M1_LEAD_IN3: begin
            // Calling U address and incrementing V address
            SRAM_address <= SRAM_address_U;
            SRAM_address_V <= SRAM_address_V + 18'd1;
            // Loading V value from SRAM to shift register
            Vreg[0] <= SRAM_read_data[15:8];
            Vreg[1] <= SRAM_read_data[15:8];
            Vreg[2] <= SRAM_read_data[15:8];
            Vreg[3] <= SRAM_read_data[15:8];
            Vreg[4] <= SRAM_read_data[15:8];
            Vreg[5] <= SRAM_read_data[7:0];
           

            M1_SRAM_state <= M1_LEAD_IN4;
        end

        M1_LEAD_IN4: begin
            // Calling V address and incrementing U address
            SRAM_address <= SRAM_address_V;
            SRAM_address_U <= SRAM_address_U + 18'd1;
            // Loading old U value from SRAM to shift register
            Ureg[6] <= SRAM_read_data[15:8];
            Ureg[7] <= SRAM_read_data[7:0]; 


            M1_SRAM_state <= M1_LEAD_IN5;
        end  

        M1_LEAD_IN5: begin
            // Calling Y address and incrementing V address
            SRAM_address <= SRAM_address_Y;
            SRAM_address_V <= SRAM_address_V + 18'd1;
            // Loading V value from SRAM to shift register
            Vreg[6] <= SRAM_read_data[15:8];
            Vreg[7] <= SRAM_read_data[7:0];
        
            M1_SRAM_state <= M1_LEAD_IN6;
        end

        M1_LEAD_IN6: begin
            // Increment Y address
            SRAM_address_Y <= SRAM_address_Y + 18'd1;
            // Loading U value from SRAM to shift register
            Ureg[8] <= SRAM_read_data[15:8];
            Ureg[9] <= SRAM_read_data[7:0];    


            M1_SRAM_state <= M1_LEAD_IN7;
        end
        M1_LEAD_IN7: begin  
            // Disable write enable for the first two cycles only if precedding state is lead in
            if (writeoff != 2'd0) begin
                SRAM_we_n <= 1'd1;
                writeoff <= writeoff - 1'd1;
            end else begin
                SRAM_we_n <= 1'd0; 
                // Load Be_accum & Ro_accum to Be,Ro 
                SRAM_write_data <= {Be_accum, Ro_accum};
                SRAM_address_RGB <= SRAM_address_RGB + 18'b1;
                // Loading address for next state
                SRAM_address <= SRAM_address_RGB;
            end

            // Loading V value from SRAM to shift register            
            Vreg[8] <= SRAM_read_data[15:8];
            Vreg[9] <= SRAM_read_data[7:0];

            // 36*U -98*U -233*U +528*U
            U_calc <= M_ar - M_br -M_cr + M_dr;
            M1_SRAM_state <= M1_CC0; 
        end    

    //********************************************* Common Case *********************************************//
        M1_CC0: begin
            if (writeoff != 2'd0) begin
                SRAM_we_n <= 1'd1;
                writeoff <= writeoff - 1'd1;
            end else begin
                SRAM_we_n <= 1'd0; 
                
                //Load Go_accum, Bo_accum to Go, Bo
                SRAM_write_data <= {Go_c, Bo_c};
                SRAM_address <= SRAM_address_RGB;
                SRAM_address_RGB <= SRAM_address_RGB + 18'b1;
            end

            //1815*U+1815*U+528*U-233*U
            U_calc <= U_calc + M_ar + M_br + M_cr - M_dr;
            // Save read Y values to Y buffs
            Yeven <= SRAM_read_data[15:8];
            Yodd <= SRAM_read_data[7:0];
            M1_SRAM_state <= M1_CC1;            
        end

        M1_CC1: begin

            SRAM_we_n <= 1'd1; 

            //-98+36, U calc finished
            U_calc <= (U_calc - M_ar + M_br + 32'd2048);
            // ** PERFORM division by 4096 and addition by 2048 CHANGE
        
            //36-98
            V_calc <= M_cr - M_dr;


            M1_SRAM_state <= M1_CC2;
        end

        M1_CC2: begin
            //-233+528+1815+1815
            V_calc <= V_calc - M_ar + M_br + M_cr + M_dr;
            if (parity == 1'b0) begin
                SRAM_address <= SRAM_address_U;
            end

            M1_SRAM_state <= M1_CC3;
        end
        
        M1_CC3: begin
            //528-233-98+36
            V_calc <= V_calc + M_ar - M_br - M_cr + M_dr + 32'd2048; 
            if (parity == 1'b0) begin
                SRAM_address <= SRAM_address_V;
            end
            M1_SRAM_state <= M1_CC4;
        end
        M1_CC4: begin
            //-12845
            //-26640
            //52298
            //38142
            SRAM_address <= SRAM_address_Y;
            Re_accum <= (M_dr + M_cr + 32'd16384);
            Ge_accum <= (M_dr - M_ar - M_br + 32'd16384);
            Be_accum <= M_dr + 32'd16384;

            M1_SRAM_state <= M1_CC5; 
        end
        M1_CC5: begin
            
            //66093
            //38142
            Be_accum <= (Be_accum + M_ar);
            Ro_accum <= M_dr + 32'd16384;
            Go_accum <= M_dr + 32'd16384;
            Bo_accum <= M_dr + 32'd16384;
            if (leadout >= 8'd90) begin
                Ureg[0] <= Ureg[1];
                Ureg[1] <= Ureg[2];
                Ureg[2] <= Ureg[3];
                Ureg[3] <= Ureg[4];
                Ureg[4] <= Ureg[5];
                Ureg[5] <= Ureg[6];
                Ureg[6] <= Ureg[7];
                Ureg[7] <= Ureg[8];
                Ureg[8] <= Ureg[9];
            end else begin
                // Read U every other CC
                if (parity == 1'b0) begin
                    SRAM_address_U <= SRAM_address_U + 1'b1;
                    
                    // Shifting U shift registers
                    Ureg[0] <= Ureg[1];
                    Ureg[1] <= Ureg[2];
                    Ureg[2] <= Ureg[3];
                    Ureg[3] <= Ureg[4];
                    Ureg[4] <= Ureg[5];
                    Ureg[5] <= Ureg[6];
                    Ureg[6] <= Ureg[7];
                    Ureg[7] <= Ureg[8];
                    Ureg[8] <= Ureg[9];
                    Ureg[9] <= SRAM_read_data[15:8];    

                    Ubuff <= SRAM_read_data[7:0];        
                
                end else begin 
                    Ureg[0] <= Ureg[1];
                    Ureg[1] <= Ureg[2];
                    Ureg[2] <= Ureg[3];
                    Ureg[3] <= Ureg[4];
                    Ureg[4] <= Ureg[5];
                    Ureg[5] <= Ureg[6];
                    Ureg[6] <= Ureg[7];
                    Ureg[7] <= Ureg[8];
                    Ureg[8] <= Ureg[9];
                    Ureg[9] <= Ubuff;                 
                end
            end

            M1_SRAM_state <= M1_CC6;
        end
        M1_CC6: begin

            SRAM_we_n <= 1'd0; 
            
            // -12845
            //-26640
            //52298
            //66093
            //Load Re_accum, Ge_accum to Re, Ge
            Ro_accum <= Ro_accum+M_cr;
            Go_accum <= Go_accum-M_ar-M_br;
            Bo_accum <= Bo_accum+M_dr;
            SRAM_address <= SRAM_address_RGB;
            SRAM_write_data <= { $unsigned(Re_c), $unsigned(Ge_c) };
            SRAM_address_RGB <= SRAM_address_RGB + 18'b1;
            if (leadout >= 8'd90) begin
                    SRAM_address_V <= SRAM_address_V + 1'b1;
                    Vreg[0] <= Vreg[1];
                    Vreg[1] <= Vreg[2];
                    Vreg[2] <= Vreg[3];
                    Vreg[3] <= Vreg[4];
                    Vreg[4] <= Vreg[5];
                    Vreg[5] <= Vreg[6];
                    Vreg[6] <= Vreg[7];
                    Vreg[7] <= Vreg[8];
                    Vreg[8] <= Vreg[9];
            end else begin
                // Read V every other CC
                if (parity == 1'b0) begin
                    // Shfiting V shift registers
                    Vreg[0] <= Vreg[1];
                    Vreg[1] <= Vreg[2];
                    Vreg[2] <= Vreg[3];
                    Vreg[3] <= Vreg[4];
                    Vreg[4] <= Vreg[5];
                    Vreg[5] <= Vreg[6];
                    Vreg[6] <= Vreg[7];
                    Vreg[7] <= Vreg[8];
                    Vreg[8] <= Vreg[9];
                    Vreg[9] <= SRAM_read_data[15:8]; 

                    Vbuff <= SRAM_read_data[7:0];
                end else begin 
                    Vreg[0] <= Vreg[1];
                    Vreg[1] <= Vreg[2];
                    Vreg[2] <= Vreg[3];
                    Vreg[3] <= Vreg[4];
                    Vreg[4] <= Vreg[5];
                    Vreg[5] <= Vreg[6];
                    Vreg[6] <= Vreg[7];
                    Vreg[7] <= Vreg[8];
                    Vreg[8] <= Vreg[9];
                    Vreg[9] <= Vbuff; 
                end
                parity <= ~parity;
            end

            // Change parity after CC is finished
            leadout <= leadout + 1'b1;

            if (leadout >= 95) begin
                M1_SRAM_state <= M1_LO0;
            end else begin
                M1_SRAM_state <= M1_CC7;
            end
        end
        M1_CC7: begin
            // Disable write enable for the first two cycles only if precedding state is lead in
            SRAM_address_Y <= SRAM_address_Y + 1'b1;
            if (writeoff != 2'd0) begin
                SRAM_we_n <= 1'd1;
                writeoff <= writeoff - 1'd1;
            end else begin
                SRAM_we_n <= 1'd0; 

                // 36*U -98*U -233*U +528*U
                U_calc <= M_ar - M_br -M_cr + M_dr;

                // Load Be_accum & Ro_accum to Be,Ro 
                SRAM_write_data <= {Be_c, Ro_c};
                // Loading address for next state
                SRAM_address <= SRAM_address_RGB;
                SRAM_address_RGB <= SRAM_address_RGB + 18'b1;

            end
            // Save read Y values to Y buffs
            Yeven <= SRAM_read_data[15:8];
            Yodd <= SRAM_read_data[7:0];
            M1_SRAM_state <= M1_CC0;
        end

    //********************************************* Lead Out *********************************************//

        M1_LO0: begin
            SRAM_we_n <= 1'd0; 
            SRAM_address <= SRAM_address_RGB;
            SRAM_address_RGB <= SRAM_address_RGB + 18'b1;
            SRAM_write_data <= {Be_c, Ro_c};
          
            M1_SRAM_state <= M1_LO1;
        end
        M1_LO1: begin
            SRAM_write_data <= {Go_c, Bo_c};
            SRAM_address <= SRAM_address_RGB;
            SRAM_address_RGB <= SRAM_address_RGB + 18'b1;
          
            M1_SRAM_state <= M1_IDLE;
        end
        M1_LO2: begin

        end
        default: M1_SRAM_state <= M1_IDLE;
        endcase
		
	end
end

// an always comb for multiplication
always_comb begin : MULTI

    M_a1 = 32'd0;
    M_a2 = 32'd0;
    M_b1 = 32'd0;
    M_b2 = 32'd0;
    M_c1 = 32'd0;
    M_c2 = 32'd0;
    M_d1 = 32'd0;
    M_d2 = 32'd0;

    case (M1_SRAM_state)
    M1_LEAD_IN7: begin
        M_a1 = 32'd36;
        M_a2 = {24'b0,Ureg[0]};
        M_b1 = 32'd98;
        M_b2 = {24'b0,Ureg[1]};
        M_c1 = 32'd233;
        M_c2 = {24'b0,Ureg[2]};
        M_d1 = 32'd528;
        M_d2 = {24'b0,Ureg[3]};
    end

    M1_CC0: begin
        M_a1 = 32'd1815;
        M_a2 ={24'b0,Ureg[4]};
        M_b1 = 32'd1815;
        M_b2 = {24'b0,Ureg[5]};
        M_c1 = 32'd528;
        M_c2 = {24'b0,Ureg[6]};
        M_d1 = 32'd233;
        M_d2 = {24'b0,Ureg[7]};
    end

    M1_CC1: begin
        M_a1 = 32'd98;
        M_a2 = {24'b0,Ureg[8]};
        M_b1 = 32'd36;
        M_b2 = {24'b0,Ureg[9]};
        M_c1 = 32'd36;
        M_c2 = {24'b0,Vreg[0]};
        M_d1 = 32'd98;
        M_d2 = {24'b0,Vreg[1]};
    end

    M1_CC2: begin
        M_a1 = 32'd233;
        M_a2 = {24'b0,Vreg[2]};
        M_b1 = 32'd528;
        M_b2 = {24'b0,Vreg[3]};
        M_c1 = 32'd1815;
        M_c2 = {24'b0,Vreg[4]};
        M_d1 = 32'd1815;
        M_d2 = {24'b0,Vreg[5]};
    end

    M1_CC3: begin
        M_a1 = 32'd528;
        M_a2 = {24'b0,Vreg[6]};
        M_b1 = 32'd233;
        M_b2 = {24'b0,Vreg[7]};
        M_c1 = 32'd98;
        M_c2 = {24'b0,Vreg[8]};
        M_d1 = 32'd36;
        M_d2 = {24'b0,Vreg[9]};       
    end

    M1_CC4: begin
        M_a1 = 32'd12845;
        M_a2 = {24'b0,Ureg[4]} - 32'd128;
        M_b1 = 32'd26640;
        M_b2 = {24'b0,Vreg[4]} - 32'd128;
        M_c1 = 32'd52298;
        M_c2 = {24'b0,Vreg[4]} - 32'd128;
        M_d1 = 32'd38142;
        M_d2 = {24'b0,(Yeven - 8'd16)};        
    end

    M1_CC5: begin
        M_a1 = 32'd66093;
        M_a2 = {24'b0,Ureg[4]} - 32'd128;
        M_d1 = 32'd38142;
        M_d2 = {24'b0,(Yodd - 8'd16)};
    end

    M1_CC6: begin
        M_a1 = 32'd12845;
        M_a2 = {20'b0,U_calc[31:12]} - 32'd128;
        M_b1 = 32'd26640;
        M_b2 = {20'b0,V_calc[31:12]} - 32'd128;
        M_c1 = 32'd52298;
        M_c2 = {20'b0,V_calc[31:12]} - 32'd128;
        M_d1 = 32'd66093;
        M_d2 = {20'b0,U_calc[31:12]} - 32'd128;        
    end

    M1_CC7: begin
        M_a1 = 32'd36;
        M_a2 = {24'b0,Ureg[0]};
        M_b1 = 32'd98;
        M_b2 = {24'b0,Ureg[1]};
        M_c1 = 32'd233;
        M_c2 = {24'b0,Ureg[2]};
        M_d1 = 32'd528;
        M_d2 = {24'b0,Ureg[3]};
    end
    endcase
end


endmodule
