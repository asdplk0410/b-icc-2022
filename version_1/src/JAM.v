module JAM (
input CLK,
input RST,
output reg [2:0] W,
output reg [2:0] J,
input [6:0] Cost,
output reg [3:0] MatchCount,
output reg [9:0] MinCost,
output reg Valid );

localparam IDLE  = 4'd0;
localparam ADDR  = 4'd4;
localparam RECV  = 4'd1;
localparam CALC  = 4'd2;
localparam TEMP   = 4'd3;
localparam SORT1 = 4'd5;
localparam SORT2 = 4'd6;
localparam SORT3 = 4'd7;
localparam SORT4 = 4'd8;
localparam OUT = 4'd9;

reg [3:0] ps, ns; 
reg [3:0] index_i;
reg [2:0] permu [0:7]; // permutation
reg [9:0] cost_acc;

wire flag;
reg [2:0] index_p;

reg [2:0] min_max;
reg [2:0] index_mm;

reg flag_fst_swap;

wire flag_done;

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
    IDLE: ns = ADDR;
    ADDR: ns = RECV;
    RECV: ns = CALC;
    CALC: ns = (index_i == 4'd8) ? TEMP : ADDR;
    TEMP: ns = (flag_done) ? OUT : SORT1;
    SORT1: ns = (flag) ? SORT2 : SORT1;
    SORT2: ns = (index_mm == index_p) ? SORT3 : SORT2;
    SORT3: ns = SORT4;
    SORT4: ns = ADDR;
    default: ns = IDLE;
    endcase 
end

assign flag_done = (permu[0] == 3'd7 && permu[1] == 3'd6 && permu[2] == 3'd5 && permu[3] == 3'd4 && permu[4] == 3'd3 && permu[5] == 3'd2 && permu[6] == 3'd1) ? 1'd1 : 1'd0;

integer i;
always@(posedge CLK or posedge RST) begin
    if(RST) begin
        for (i = 0;i < 8;i = i + 1) begin
           permu[i] <= i; 
        end
    end
    else if(ps == SORT3)
    begin
        permu[index_p] <= permu[min_max];
        permu[min_max] <= permu[index_p];
    end
    else if(ps == SORT4)
    begin
        case (index_p)
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

always@(posedge CLK or posedge RST) begin
    if(RST) begin
        min_max <= 3'd7;
    end
    else if(ps == SORT2)
    begin
        if(flag_fst_swap)
        begin
            if(permu[index_mm] > permu[index_p] && permu[index_mm] <= permu[min_max])
            begin
                min_max <= index_mm;
            end
        end
        else
        begin
            if(permu[index_mm] > permu[index_p])
            begin
                min_max <= index_mm;
            end
        end
    end
    else if(ps == ADDR)
    begin
        min_max <= 3'd7;
    end
end

always@(posedge CLK or posedge RST) begin
    if(RST)
    begin
        flag_fst_swap <= 1'd0;
    end
    else if(ps == SORT2)
    begin
        if(permu[index_mm] > permu[index_p])
        begin
            flag_fst_swap <= 1'd1;
        end
    end
    else if(ps == ADDR)
    begin
        flag_fst_swap <= 1'd0;
    end
end


assign flag = (permu[index_p] > permu[index_p-1]) ? 1'd1 : 1'd0;

always@(posedge CLK or posedge RST) begin
    if(RST)
    begin
        index_p <= 3'd7;
    end
    else if(ps == SORT1)
    begin
        index_p <= index_p - 1'd1;
    end
    else if(ps == ADDR)
    begin
        index_p <= 3'd7;
    end
end

always@(posedge CLK or posedge RST) begin
    if(RST)
    begin
        index_mm <= 3'd7;
    end
    else if(ps == SORT2)
    begin
        index_mm <= index_mm - 1'd1;
    end
    else if(ps == ADDR)
    begin
        index_mm <= 3'd7;
    end
end

always@(posedge CLK or posedge RST) begin
    if(RST)
    begin
        index_i <= 3'd0;
    end
    else if(ps == ADDR) 
    begin
        index_i <= index_i + 1'd1;
    end
    else if(ps == SORT1) 
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
        J <= permu[index_i[2:0]];
    end
end

always@(posedge CLK or posedge RST) begin
    if(RST) begin
        cost_acc <= 10'd0;
    end
    else if(ps == CALC)
    begin
        cost_acc <= cost_acc + Cost;
    end
    else if(ps == SORT1)
    begin
        cost_acc <= 10'd0;
    end
end

// reg [9:0] MinCost_temp;

always@(posedge CLK or posedge RST) begin
    if(RST) begin
        MinCost <= {10{1'd1}};
    end
    else if(ps == TEMP)
    begin
        MinCost <= (MinCost > cost_acc) ? cost_acc : MinCost;
    end
end

always@(posedge CLK or posedge RST) begin
    if(RST) begin
        MatchCount <= 5'd1;
    end
    else if(ps == TEMP)
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

// output
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


