module JAM (
input CLK,
input RST,
output reg [2:0] W,
output reg [2:0] J,
input [6:0] Cost,
output reg [3:0] MatchCount,
output reg [9:0] MinCost,
output reg Valid );

localparam IDLE = 2'd0;
localparam RECV = 2'd1;
localparam SORT = 2'd2;
localparam OUT  = 2'd3;

localparam SORT0 = 3'd0;
localparam SORT1 = 3'd1;
localparam SORT2 = 3'd2;
localparam SORT3 = 3'd3;
localparam DONE  = 3'd4;

reg [1:0] ps, ns;
reg [2:0] ps_sort, ns_sort;
reg [4:0] index_i;
reg [2:0] permu [0:7], permu_temp [0:7]; // permutation
reg [9:0] cost_acc;

reg [2:0] pivot;

reg [2:0] min_max;
reg [2:0] index_mm;

reg flag_fst_swap;

wire flag_done;
wire [3:0] mode;

//state switch
always@(posedge CLK or posedge RST) begin
    if(RST) begin
        ps <= IDLE;
    end
    else begin
        ps <= ns;
    end
end

//next state logic
always@(*) begin
    case(ps)
    IDLE: ns = RECV;
    RECV: ns = (index_i == 4'd8) ? SORT : RECV;
    SORT: ns = (flag_done && ps_sort == DONE) ? OUT : RECV;
    default: ns = IDLE;
    endcase 
end

assign flag_done = (permu[0] == 3'd7 && permu[1] == 3'd6 && permu[2] == 3'd5 && permu[3] == 3'd4 && permu[4] == 3'd3 && permu[5] == 3'd2 && permu[6] == 3'd1) ? 1'd1 : 1'd0;
assign mode = (pivot < 3'd1) ? 4'd9 : 4'd8;

//state switch 
always@(posedge CLK or posedge RST) begin
    if(RST) begin
        ps_sort <= DONE;
    end
    else begin
        ps_sort <= ns_sort;
    end
end

//next state logic
always@(*) begin
    case(ps_sort)
    SORT0: ns_sort = (index_mm == pivot) ? SORT1 : SORT0;
    SORT1: ns_sort = SORT2;
    SORT2: ns_sort = DONE;
    DONE:  ns_sort = (ps == SORT) ? SORT0 : DONE;
    default: ns_sort = DONE;
    endcase 
end

integer i;
always@(posedge CLK or posedge RST) begin
    if(RST) begin
        for (i = 0;i < 8;i = i + 1) begin
           permu[i] <= i; 
        end
    end
    else if(ps_sort == SORT1)
    begin
        permu[pivot] <= permu[min_max];
        permu[min_max] <= permu[pivot];
    end

    else if(ps_sort == SORT2)
    begin
        case (pivot)
            3'd0:
            begin
                permu[1] <= permu[7];
                permu[7] <= permu[1];
                permu[2] <= permu[6];
                permu[6] <= permu[2];
                permu[3] <= permu[5];
                permu[5] <= permu[3];
            end
            3'd1:
            begin
                permu[2] <= permu[7];
                permu[7] <= permu[2];
                permu[3] <= permu[6];
                permu[6] <= permu[3];
                permu[4] <= permu[5];
                permu[5] <= permu[4];
            end
            3'd2: 
            begin
                permu[3] <= permu[7];
                permu[7] <= permu[3];
                permu[6] <= permu[4];
                permu[4] <= permu[6];
            end
            3'd3: 
            begin
                permu[4] <= permu[7];
                permu[7] <= permu[4];
                permu[5] <= permu[6];
                permu[6] <= permu[5];
            end
            3'd4:
            begin 
                permu[5] <= permu[7];
                permu[7] <= permu[5];
            end
            3'd5:
            begin
                permu[6] <= permu[7];
                permu[7] <= permu[6];
            end 
        endcase
    end
end

genvar g;
generate
for(g=0;g<8;g=g+1)begin
	always @(posedge CLK or posedge RST) begin
		if(RST)
        begin
			permu_temp[g] <= g;
		end
		else if(ps == SORT) 
        begin
			permu_temp[g] <= permu[g]; 
		end
	end
end
endgenerate

always@(posedge CLK or posedge RST) begin
    if(RST) begin
        min_max <= 3'd7;
    end
    else if(ps_sort == SORT0)
    begin
        if(flag_fst_swap)
        begin
            if(permu[index_mm] > permu[pivot] && permu[index_mm] <= permu[min_max])
            begin
                min_max <= index_mm;
            end
        end
        else
        begin
            if(permu[index_mm] > permu[pivot])
            begin
                min_max <= index_mm;
            end
        end
    end
    else if(ps_sort == DONE)
    begin
        min_max <= 3'd7;
    end
end

always@(posedge CLK or posedge RST) begin
    if(RST)
    begin
        flag_fst_swap <= 1'd0;
    end
    else if(ps == RECV)
    begin
        if(permu[index_mm] > permu[pivot])
        begin
            flag_fst_swap <= 1'd1;
        end
    end
    else if(ps == SORT)
    begin
        flag_fst_swap <= 1'd0;
    end
end

always@(posedge CLK or posedge RST) begin
    if(RST)
    begin
        index_mm <= 3'd7;
    end
    else if(ps == RECV)
    begin
        index_mm <= (index_mm == pivot) ? index_mm : index_mm - 1'd1;
    end
    else if(ps == SORT)
    begin
        index_mm <= 3'd7;
    end
end

always@(posedge CLK or posedge RST) begin
    if(RST)
    begin
        pivot <= 3'd7;
    end
    else if(ps == SORT)
    begin
        if(permu[7] > permu[6])begin
            pivot <= 3'd6;
        end
        else if(permu[6] > permu[5])begin
            pivot <= 3'd5;
        end
        else if(permu[5] > permu[4])begin
            pivot <= 3'd4;
        end
        else if(permu[4] > permu[3])begin
            pivot <= 3'd3;
        end
        else if(permu[3] > permu[2])begin
            pivot <= 3'd2;
        end
        else if(permu[2] > permu[1])begin
            pivot <= 3'd1;
        end
        else if(permu[1] > permu[0])begin
            pivot <= 3'd0;
        end
    end
end

////////////////////////////////////////////////////////////////////////////////////////////////
// input data
always@(posedge CLK or posedge RST) begin
    if(RST)
    begin
        index_i <= 3'd0;
    end
    else if(ps == RECV) 
    begin
        index_i <= index_i + 1'd1;
    end
    else if(ps == SORT) 
    begin
        index_i <= 3'd0;
    end
end

always@(posedge CLK or posedge RST) begin
    if(RST)
    begin
        W <= 3'd0;
    end
    else if(ps == RECV) 
    begin
        W <= index_i[2:0];
    end
end

always@(posedge CLK or posedge RST) begin
    if(RST)
    begin
        J <= 3'd0;
    end
    else if(ps == RECV) 
    begin
        J <= permu_temp[index_i[2:0]];
    end
end

////////////////////////////////////////////////////////////////////////////////////////////////
// Calculate
always@(posedge CLK or posedge RST) begin
    if(RST) begin
        cost_acc <= 10'd0;
    end
    else if(ps == RECV || ps == SORT)
    begin
        cost_acc <= (index_i > 4'd1 && index_i < mode + 2) ? cost_acc + Cost : 10'd0;
    end
end

always@(posedge CLK or posedge RST) begin
    if(RST) begin
        MinCost <= {10{1'd1}};
    end
    else if(ps == RECV)
    begin
        if(index_i == 3'd0 && cost_acc != 10'd0)
            MinCost <= (MinCost > cost_acc) ? cost_acc : MinCost;
    end   
end

always@(posedge CLK or posedge RST) begin
    if(RST) begin
        MatchCount <= 5'd1;
    end
    else if(ps == RECV)
    begin
        if(index_i == 3'd0)
        begin
            if(MinCost > cost_acc)
            begin
                MatchCount <= 5'd1;
            end
            else if(MinCost == cost_acc)
            begin
                MatchCount <= MatchCount + 5'd1;
            end
        end
    end
end

////////////////////////////////////////////////////////////////////////////////////////////////
// Output data
always@(posedge CLK or posedge RST) begin
    if(RST) begin
        Valid <= 1'd0;
    end
    else if(ps == OUT)
    begin
        Valid <= 1'd1;
    end
end

endmodule


