

module asyn_fifo#(
	parameter DATA_WIDTH = 8,
	parameter DATA_DEPTH = 32
	)(

    //write ports    
	input wr_clk,
	input wr_rst,
	input wr_en,
	input [DATA_WIDTH - 1 : 0] wr_data,
	output reg full,
    
    //read ports
	input rd_clk,
	input rd_rst,
	input rd_en,
	output reg [DATA_WIDTH - 1 : 0] rd_data,
	output reg empty

    );


	// define FIFO buffer 
	reg [DATA_WIDTH - 1 : 0] fifo_buffer[0 : DATA_DEPTH - 1];

	//define the write and read pointer and 
	//pay attention to the size of pointer which should be greater one to normal

	reg [$clog2(DATA_DEPTH) : 0] wr_pointer = 0, rd_pointer = 0; 

	//write data to fifo buffer and wr_pointer control
	always@(posedge wr_clk) begin
		if(wr_rst) begin
			wr_pointer <= 0;
		end
		else if(wr_en) begin
			wr_pointer <= wr_pointer + 1;
			fifo_buffer[wr_pointer] <= wr_data;
		end

	end

	//read data from fifo buffer and rd_pointer control
	always@(posedge rd_clk) begin
		if(rd_rst) begin
			rd_pointer <= 0;
		end
		else if(rd_en) begin
			rd_pointer <= rd_pointer + 1;
			rd_data <= fifo_buffer[rd_pointer];
		end

	end

	//wr_pointer and rd_pointer translate into gray code

	wire [$clog2(DATA_DEPTH) : 0] wr_ptr_g, rd_ptr_g; 

	assign wr_ptr_g = wr_pointer ^ (wr_pointer >>> 1);
	assign rd_ptr_g = rd_pointer ^ (rd_pointer >>> 1);



	//wr_pointer after gray coding synchronize into read clock region
	reg [$clog2(DATA_DEPTH) : 0] wr_ptr_gr, wr_ptr_grr, rd_ptr_gr, rd_ptr_grr; 

	always@(rd_clk) begin
		if(rd_rst) begin
			wr_ptr_gr <= 0;
			wr_ptr_grr <= 0;
		end
		else begin
			wr_ptr_gr <= wr_ptr_g;
			wr_ptr_grr <= wr_ptr_gr;
		end
	end


	//rd_pointer after gray coding synchronize into  write clock region
	always@(wr_clk) begin
		if(wr_rst) begin
			rd_ptr_gr <= 0;
			rd_ptr_grr <= 0;
		end
		else begin
			rd_ptr_gr <= rd_ptr_g;
			rd_ptr_grr <= rd_ptr_gr;
		end
	end

	// judge full or empty

	always@(posedge rd_clk) begin
		if(rd_rst) empty <= 0;
		else if(wr_ptr_grr == rd_ptr_g) begin
			empty <= 1;
		end
		else empty <= 0;
 	end

 	always@(posedge wr_clk) begin
 		if(wr_rst) full <= 0;
 		else if( (rd_ptr_grr[$clog2(DATA_DEPTH) - 2 : 0] == wr_ptr_g[$clog2(DATA_DEPTH) - 2 : 0])
 			&& ( rd_ptr_grr[$clog2(DATA_DEPTH)] != wr_ptr_g[$clog2(DATA_DEPTH)] ) && ( rd_ptr_grr[$clog2(DATA_DEPTH) - 1] != wr_ptr_g[$clog2(DATA_DEPTH) - 1] ) ) begin
 			full <= 1;
 		end
 		else full <= 0;
 	end


//对写满的限制
always@(posedge wr_clk or posedge wr_rst) begin
    if(wr_rst) begin
        wr_pointer <= 0;
    end
    else if(wr_en) begin
        if(!((rd_ptr_grr[$clog2(DATA_DEPTH) - 2 : 0] == wr_ptr_g[$clog2(DATA_DEPTH) - 2 : 0])
 			&& ( rd_ptr_grr[$clog2(DATA_DEPTH)] != wr_ptr_g[$clog2(DATA_DEPTH)] ) && ( rd_ptr_grr[$clog2(DATA_DEPTH) - 1] != wr_ptr_g[$clog2(DATA_DEPTH) - 1] ))) begin
            wr_pointer <= wr_pointer + 1;
        end
        else begin
            wr_pointer <= wr_pointer;
        end
    end
    else  begin
        wr_pointer <= wr_pointer;
    end

end

//对读空的限制
always@(posedge rd_clk or posedge rd_rst) begin
    if(rd_rst) begin
        rd_pointer <= 0;
    end
    else if(rd_en) begin
        if(wr_ptr_grr != rd_ptr_g) begin
            rd_pointer <= rd_pointer + 1;
        end
        else begin
            rd_pointer <= rd_pointer;
        end
    end
    else  begin
        rd_pointer <= rd_pointer;
    end

end


endmodule



