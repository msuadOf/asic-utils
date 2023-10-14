package fifo

import chisel3._
import chisel3.util._

class asyncFifo(width: Int, depth: Int) extends RawModule {
  val io = IO(new Bundle {
    // Write Port
    val dataIn = Input(UInt(width.W))
    val writeEn = Input(Bool())
    val writeClk = Input(Clock())
    val full = Output(Bool())
    // read Port
    val dataOut = Output(UInt(width.W))
    val readEn = Input(Bool())
    val readClk = Input(Clock())
    val empty = Output(Bool())
    // reset
    val systemRst = Input(Bool())
  })
  val ram = SyncReadMem(1 << depth, UInt(width.W))
  val writeToReadPtr = Wire(UInt((depth + 1).W))
  val readToWritePtr = Wire(UInt((depth + 1).W))

  // Write Clock Domain
  withClockAndReset(io.writeClk, io.systemRst) {
    val binaryWritePtr = RegInit(0.U((depth + 1).W))
    val binaryWritePtrNext = Wire(UInt((depth + 1).W))
    val grayWritePtr = RegInit(0.U((depth + 1).W))
    val grayWritePtrNext = Wire(UInt((depth + 1).W))

    val isFull = RegInit(false.B)
    val fullValue = Wire(Bool())
    val grayReadPtrDelay0 = RegNext(readToWritePtr)
    val grayReadPtrDelay1 = RegNext(grayReadPtrDelay0)

    // decimal Write ptr jump direction
    binaryWritePtrNext := binaryWritePtr + (io.writeEn && !isFull).asUInt
    binaryWritePtr := binaryWritePtrNext

    // binary to gray
    grayWritePtrNext := (binaryWritePtrNext >> 1) ^ binaryWritePtrNext
    grayWritePtr := grayWritePtrNext
    writeToReadPtr := grayWritePtr

    // write full judge
    fullValue := (grayWritePtrNext === Cat(
      ~grayReadPtrDelay1(depth, depth - 1),
      grayReadPtrDelay1(depth - 2, 0)
    ))
    isFull := fullValue
    when(io.writeEn && !isFull) {
      ram.write(binaryWritePtr(depth - 1, 0), io.dataIn)
    }
    io.full := isFull
  }

  // Write Clock Domain
  withClockAndReset(io.readClk, io.systemRst) {
    val binaryReadPtr = RegInit(0.U((depth + 1).W))
    val binaryReadPtrNext = Wire(UInt((depth + 1).W))
    val grayReadPtr = RegInit(0.U((depth + 1).W))
    val grayReadPtrNext = Wire(UInt((depth + 1).W))

    val isEmpty = RegInit(false.B)
    val emptyValue = Wire(Bool())
    val grayWritePtrDelay0 = RegNext(writeToReadPtr)
    val grayWritePtrDelay1 = RegNext(grayWritePtrDelay0)

    // decimal Read ptr jump direction
    binaryReadPtrNext := binaryReadPtr + (io.readEn && !isEmpty).asUInt
    binaryReadPtr := binaryReadPtrNext

    // binary to gray
    grayReadPtrNext := (binaryReadPtrNext >> 1) ^ binaryReadPtrNext
    grayReadPtr := grayReadPtrNext
    readToWritePtr := grayReadPtr

    // Read Empty judge
    emptyValue := (grayReadPtrNext === grayWritePtrDelay1)
    isEmpty := emptyValue
    io.dataOut := ram.read(binaryReadPtr(depth - 1, 0), io.readEn && !isEmpty)
    io.empty := isEmpty
  }

}
object top extends App {
  (new chisel3.stage.ChiselStage)
    .emitVerilog(new asyncFifo(8, 4), Array("--target-dir", "gen"))
}

