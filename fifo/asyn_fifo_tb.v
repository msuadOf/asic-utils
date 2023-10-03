

module asyn_fifo_tb(

    );

    parameter DATA_WIDTH = 8;
    parameter DATA_DEPTH = 16;

    //write ports    
	reg wr_clk;
	reg wr_rst;
	reg wr_en;
	reg [DATA_WIDTH - 1 : 0] wr_data;
	wire full;
    
    //read ports
	reg rd_clk;
	reg rd_rst;
	reg rd_en;
	wire [DATA_WIDTH - 1 : 0] rd_data;
	wire empty;



    initial begin
        wr_clk = 0;
        forever begin
            #2 wr_clk = ~wr_clk;
        end
    end

    initial begin
        rd_clk = 0;
        forever begin
            #5 rd_clk = ~rd_clk;
        end
    end

    initial begin
        wr_rst = 1'b1;
        rd_rst = 1'b1;
        wr_en = 1'b0;
        rd_en = 1'b0;

        #10
        wr_rst = 0;
        rd_rst = 0;

        #10
        wr_en = #(0.2) 1'b1;
        wr_data = #(0.2) $random; 
        repeat(5) begin
            @(posedge wr_clk);
                wr_data = #(0.2) $random;  
        end

        @(posedge wr_clk); 
        wr_en = #(0.2) 1'b0;
        wr_data = #(0.2) $random;

        #10
        rd_en = #(0.2) 1'b1;
        repeat(5) begin
            @(posedge rd_clk);  
        end

        @(posedge rd_clk);
        rd_en = #(0.2) 1'b0;


        #10
        wr_en = #(0.2) 1'b1;
        wr_data = #(0.2) $random; 
        repeat(16) begin
            @(posedge wr_clk);  
                wr_data = #(0.2) $random;
        end
        @(posedge wr_clk); 
        wr_en = #(0.2) 1'b0;
        wr_data = #(0.2) $random;                


    end




asyn_fifo#(
    .DATA_WIDTH ( DATA_WIDTH ),
    .DATA_DEPTH ( DATA_DEPTH )
)u_asyn_fifo(
    .wr_clk     ( wr_clk     ),
    .wr_rst     ( wr_rst     ),
    .wr_en      ( wr_en      ),
    .wr_data    ( wr_data    ),
    .full       ( full       ),
    .rd_clk     ( rd_clk     ),
    .rd_rst     ( rd_rst     ),
    .rd_en      ( rd_en      ),
    .rd_data    ( rd_data    ),
    .empty      ( empty      )
);





endmodule

