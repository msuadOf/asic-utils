# 一些碎碎念

首先，asyn fifo代码来源于
[FPGA基础知识极简教程（4）从FIFO设计讲起之异步FIFO篇](https://blog.csdn.net/Reborn_Lee/article/details/106619999)
[FPGA逻辑设计回顾（6）多比特信号的CDC处理方式之异步FIFO](https://reborn.blog.csdn.net/article/details/112081689)

网页copy如下：
---
写在前面
一开始是想既然是极简教程，就应该只给出FIFO的概念，没想到还是给出了同步以及异步FIFO的设计，要不然总感觉内容不完整，也好，自己设计的FIFO模块不用去担心因IP核跨平台不通用的缺陷！那我们开始吧。

个人微信公众号： FPGA LAB
个人博客首页
注：学习交流使用！
正文
同步FIFO回顾
上一篇博客讲了同步FIFO的概念以及同步FIFO的设计问题，并给出了同步FIFO的Verilog代码以及VHDL代码，并经过了行为仿真测试，链接如下：

FPGA基础知识极简教程（3）从FIFO设计讲起之同步FIFO篇

$clog2()系统函数使用
这里简单提一下，同步FIFO的代码中用到了一个系统函数$clog2()，这个系统函数的使用方法很简单：

parameter DATA_WIDTH = 8;
parameter DATA_DEPTH = 8;

reg [DATA_WIDTH - 1 : 0] fifo_buffer[0 : DATA_DEPTH - 1];

reg [$clog2(DATA_DEPTH) - 1 : 0] wr_pointer = 0;
reg [$clog2(DATA_DEPTH) - 1 : 0] rd_pointer = 0;

1
2
3
4
5
6
7
8
例如我定义了FIFO缓冲区的深度为DATA_DEPTH = 8，那么其地址（指针）位宽是多少呢？
这时候就可以使用系统函数$clog2()了，位宽可以表示为：

$clog2(DATA_DEPTH)                  // = 3;
1
指针就可以定义为：

reg [$clog2(DATA_DEPTH) - 1 : 0] wr_pointer = 0;
reg [$clog2(DATA_DEPTH) - 1 : 0] rd_pointer = 0;
1
2
综合属性控制资源使用
还有一点需要提的是，我们都知道在FPGA中FIFO的实现可以使用分布式资源或者BLOCK RAM，那么如何掌控呢？
当使用FIFO缓冲空间较小时，我们选择使用Distributed RAM；当使用FIFO缓冲空间较大时，我们选择使用BLOCK RAM资源；这是一般的选择原则。
我们可以通过在设计代码中加入约束条件来控制，之前有写过

Vivado 随笔（1） 综合属性之 ram_style & rom_style?

就上述同步FIFO而言，我们可以在缓冲区定义时候添加如下约束：

(*ram_style = "distributed"*) reg [DATA_WIDTH - 1 : 0] fifo_buffer[0 : DATA_DEPTH - 1];

或者：

(*ram_style = "block"*) reg [DATA_WIDTH - 1 : 0] fifo_buffer[0 : DATA_DEPTH - 1];

1
2
3
4
5
6
为了验证是否有用，我们在Vivado中进行验证如下：

当设计中使用BLOCK RAM约束：

(*ram_style = "block"*)reg [DATA_WIDTH - 1 : 0] fifo_buffer[0 : DATA_DEPTH - 1];
1
综合后的电路图如下，可见FIFO缓存区使用的资源为BLOCK RAM；

同时给出资源利用率报告：


可见存在BLOCK RAM ，由于我仅仅综合了一个同步FIFO，因此这个Block RAM一定是FIFO缓冲区消耗的。

当使用Distributed RAM约束时：

(*ram_style = "distributed"*)reg [DATA_WIDTH - 1 : 0] fifo_buffer[0 : DATA_DEPTH - 1];
1
综合后电路图FIFO缓冲区部分：


资源利用率情况；

可见 ，并未使用BLOCK RAM，而是使用了LUT RAM，也即分布式RAM。
综上，验证了这条约束的有效性。

异步FIFO设计
FIFO用途回顾
再设计异步FIFO电路之前，有必要说明一下FIFO的用途，上篇博文提到：

跨时钟域
FPGA或者ASIC设计内部电路多位数据在不同的时钟域交互，为了数据安全、正确、稳定交互，我们需要设计异步FIFO进行跨时钟域交互。正如之前博客所写：漫谈时序设计（1）跨时钟域是设计出来的，而非约束出来的！
我们在时序分析时候，通常都将跨时钟域路径进行伪路径约束，因此我们必须在设计时候解决跨时钟域数据传输问题，异步FIFO在此起到关键作用。

在将数据发送到芯片外之前将其缓冲（例如，发送到DRAM或SRAM）
缓冲数据以供软件在以后查看
存储数据以备后用
这三条大概讲的都是一个意思，总结起来就是FIFO可以起到数据缓冲或缓存的作用，例如突然数据，我们就需要先将其缓存起来，之后再从FIFO中读出出来进行处理，这样也可以保证数据不会丢失。

引用互联网上其他说法就是：数据写入过快，并且间隔时间长，也就是突发写入。那么通过设置一定深度的FIFO，可以起到数据暂存的功能，且使得后续处理流程平滑。

异步FIFO原理回顾
无论是同步FIFO还是异步FIFO，其大致原理都是一致的，先入先出自然不必多说，关于空满的判断都是通过读写指针之间的关系来判断；还有就是异步FIFO的指针需要进行一定的处理，例如格雷码处理，这样可以减小读指针同步到写指针时钟域，或者写指针同步到读指针时钟域时出现亚稳态的概率，这是因为格雷码每次只有一位变化，这样一位数据在进行跨时钟域传输的时候亚稳态出现的概率会大大减小。同步之后便进行对比，以此来判断FIFO的空满。
那异步FIFO如何判断空满呢？
回答这个问题之前，我想先统一的说明FIFO（同步或者异步）是如何判断空满的？

起始，读写指针都是0，FIFO一定为空；之后对FIFO进行一系列的读写操作，导致读写指针关系发生了变化，可以分为下面两种情况：

读比写要快，或者说读指针追写指针，如果追上了，也即二者再次相等，则FIFO读空；
写比读快，或者说写指针弯道超越追读指针，当写指针再次绕到读指针背后并与读指针重合，也即二者相等时，FIFO写满！
在同步FIFO中，我们使用计数的方式进行判断空满，运用的也是这个原理，写一个数据时，计数值加1，读出一个数据时，计数值减1，如下图：


我最喜欢用这幅图来分析FIFO，下面一行一行的分析：

第一行：写入1个数据，计数值为1；
第二行：写入5个数据，计数值为6；
第三行：读出3个数据，计数值为3；
第四行：写入3个数据，计数值为6；
第五行：写入2个数据，计数值为8，等于FIFO深度，则表示写满；
第六行：读出6个数据，计数值为2，表示还剩下两个数据缓存在FIFO中。
如果再接着读2个 数据，则计数值为0，FIFO就被读空了。

好了，我们分析完了同步FIFO是如何判断空满的，下面重点放在异步FIFO的原理上。

我曾写过一篇CDC问题的博客，谈到了异步FIFO的设计：
谈谈跨时钟域传输问题（CDC）

这篇博客中说，同步FIFO可以使用计数方式来判断空满，但是异步FIFO不能，因为写指针和读指针根本不在同一个时钟域，计数器无法处理这样的计数。
那么怎么处理呢？
博客里采用的方法是对读写指针的位宽多添1位，这样可以在读写指针相等时，表示FIFO空，而在写指针和读指针最高位不同，而其他位相等时，也即写指针大于读指针一个FIFO深度的数值，表示FIFO满，这不就是意味着写指针绕了一圈，又追上了读指针了吗？
恰是如此，用来解决不用计数而具体判断FIFO空满的问题。

这只是解决了判断空满的一个问题，也就是确定指针的关系！
那下一个问题就是如何判断？
由于读写指针不在同一个时钟域，二者需要同步到同一个时钟域后进行判断大小。

具体的操作就是在各自的时钟域内进行读写操作，同时：

判断是否写满时，需要将读指针转换成格雷码形式，再同步到写时钟域，与写指针比较，判断是否写满！
细心的人恐怕能否发现，这里存在的一个小插曲，当读指针转换成格雷码以及同步到写时钟域的过程中，读写指针可能还都在递增，这样的话，等同步后的读指针与写指针相等时（不包括最高位），实际的读指针可能已经变了，这样的话其实还有几个空间没有写满！但这样设计就有问题吗？没有问题！这叫保守设计，可以增加FIFO的安全性。
下面是判断是否写满的示意图：


上面是写满判断的情况，下面给出读空判断的可能情形分析：

当判断是否读空时，需要把写指针同步到读时钟域，具体过程是先将写指针转换为格雷码，再同步到读时钟域，之后和读指针比较，如果二者相等，则空标志置位！
还是和第一种情况有同样的插曲，当写指针转换成格雷码以及同步到读时钟域的过程中，写指针和读指针都可能还在递增，这样当二者判断相等的时候，则写指针可能还多写了几个空间，实际上并没有读空。
那问题来了，这样操作就有问题了吗？同样没有问题，这样也保证来了FIFO的安全，防止被读空。
下面给出手绘示意图：



到此，这一种设计方式的异步FIFO算是讲完了，下面就是设计的问题了。

异步FIFO设计
如果你认真分析了上述异步FIFO的实现方式，那么你会分分钟写出实现代码，我的版本如下：

`timescale 1ns / 1ps

// Engineer: Reborn Lee
// Module Name: asy_fifo
// https://blog.csdn.net/Reborn_Lee



module asy_fifo#(
	parameter DATA_WIDTH = 8,
	parameter DATA_DEPTH = 32
	)(
	input wr_clk,
	input wr_rst,
	input wr_en,
	input [DATA_WIDTH - 1 : 0] wr_data,
	output reg full,

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
 		else if( (rd_ptr_grr[$clog2(DATA_DEPTH) - 1 : 0] == wr_ptr_g[$clog2(DATA_DEPTH) - 1 : 0])
 			&& ( rd_ptr_grr[$clog2(DATA_DEPTH)] != wr_ptr_g[$clog2(DATA_DEPTH)] ) ) begin
 			full <= 1;
 		end
 		else full <= 0;
 	end





endmodule

1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
68
69
70
71
72
73
74
75
76
77
78
79
80
81
82
83
84
85
86
87
88
89
90
91
92
93
94
95
96
97
98
99
100
101
102
103
104
105
106
107
108
109
110
111
112
113
114
115
116
117
118
119
120
注意事项

读写指针宽度要是$clog2(DATA_DEPTH) + 1，定义的时候应该定义为：
reg [$clog2(DATA_DEPTH) : 0] wr_pointer = 0, rd_pointer = 0; 
1
其次，判断空的时候要拿转换为格雷码并且同步到读时钟域之后的写指针与读指针比较，比较代码如下：
always@(posedge rd_clk) begin
		if(rd_rst) empty <= 0;
		else if(wr_ptr_grr == rd_ptr_g) begin
			empty <= 1;
		end
		else empty <= 0;
 	end
1
2
3
4
5
6
7
一定要二者相等的下一个读周期empty信号为1；

对于满full信号，一定要用转换为格雷码且同步到写时钟域之后的读指针与转换为格雷码之后的写时钟比较，比较的条件是最高位不同，但是其他位相同。
always@(posedge wr_clk) begin
 		if(wr_rst) full <= 0;
 		else if( (rd_ptr_grr[$clog2(DATA_DEPTH) - 1 : 0] == wr_ptr_g[$clog2(DATA_DEPTH) - 1 : 0])
 			&& ( rd_ptr_grr[$clog2(DATA_DEPTH)] != wr_ptr_g[$clog2(DATA_DEPTH)] ) ) begin
 			full <= 1;
 		end
 		else full <= 0;
 	end
1
2
3
4
5
6
7
8
最后提出的是转换为格雷码的方式是组合逻辑的方式，即：
//wr_pointer and rd_pointer translate into gray code

	wire [$clog2(DATA_DEPTH) : 0] wr_ptr_g, rd_ptr_g; 

	assign wr_ptr_g = wr_pointer ^ (wr_pointer >>> 1);
	assign rd_ptr_g = rd_pointer ^ (rd_pointer >>> 1);
1
2
3
4
5
6
当然你用时序逻辑也可以哦。

异步FIFO仿真
我们对上述设计进行行为仿真，先给出我的测试文件：


`timescale 1ns/1ps
module asy_fifo_tb;
	parameter DATA_WIDTH = 8;
	parameter DATA_DEPTH = 16;

	reg wr_clk;
	reg wr_rst;
	reg wr_en;
	reg [DATA_WIDTH - 1 : 0] wr_data;
	wire full;

	reg rd_clk;
	reg rd_rst;
	reg rd_en;
	wire [DATA_WIDTH - 1 : 0] rd_data;
	wire empty;

	initial begin
		wr_clk = 0;
		forever begin
			#5 wr_clk = ~wr_clk;
		end
	end

	initial begin
		rd_clk = 0;
		forever begin
			#10 rd_clk = ~rd_clk;
		end
	end

	initial begin
		wr_rst = 1;
		rd_rst = 1;
		wr_en = 0;
		rd_en = 0;
		#30 
		wr_rst = 0;
		rd_rst = 0;

		//write data into fifo buffer
		@(negedge wr_clk) 
		wr_data = $random;
		wr_en = 1;

		repeat(7) begin
			@(negedge wr_clk) 
			wr_data = $random; // write into fifo 8 datas in all;
		end

		// read parts
		@(negedge wr_clk) 
		wr_en = 0;

		@(negedge rd_clk) 
		rd_en = 1;

		repeat(7) begin
			@(negedge rd_clk);  // read empty 
		end 
		@(negedge rd_clk)
		rd_en = 0;

		//write full
		# 150

		@(negedge wr_clk)
		wr_en = 1;
		wr_data = $random;

		repeat(15) begin
		@(negedge wr_clk)
			wr_data = $random;
		end

		@(negedge wr_clk)
		wr_en = 0;


		#50 $finish;





	end




	asy_fifo #(
			.DATA_WIDTH(DATA_WIDTH),
			.DATA_DEPTH(DATA_DEPTH)
		) inst_asy_fifo (
			.wr_clk  (wr_clk),
			.wr_rst  (wr_rst),
			.wr_en   (wr_en),
			.wr_data (wr_data),
			.full    (full),
			.rd_clk  (rd_clk),
			.rd_rst  (rd_rst),
			.rd_en   (rd_en),
			.rd_data (rd_data),
			.empty   (empty)
		);


endmodule

1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
57
58
59
60
61
62
63
64
65
66
67
68
69
70
71
72
73
74
75
76
77
78
79
80
81
82
83
84
85
86
87
88
89
90
91
92
93
94
95
96
97
98
99
100
101
102
103
104
105
106
107
108
109
仿真波形为：


仿真通过，且功能符合预期。

由于本博客写的时候有点长，几乎一天了，所以就到这里吧！不得不说的是，异步FIFO的实现方式肯定不只有这一种，还有很多其他实现方式，各位可以自行尝试。
后面如果有更多有关FIFO的有趣知识或者心得体会，我会继续补充！

参考资料
参考资料1
参考资料2
参考资料3
参考资料4
参考资料5
参考资料6
参考资料7
参考资料8
交个朋友
个人微信公众号：FPGA LAB；
FPGA/IC技术交流2020
————————————————
版权声明：本文为CSDN博主「李锐博恩」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/Reborn_Lee/article/details/106619999

