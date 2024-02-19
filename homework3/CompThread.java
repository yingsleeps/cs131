import java.util.zip.Deflater;
import java.io.ByteArrayOutputStream;
import java.util.Arrays;

public class CompThread extends Thread {

    // flags for first and last block
    private boolean first_block;
    private volatile boolean last_block;

    private byte[] dictionary;

    private byte[] block; // this block 
    private byte[] prev_block; // previous block

    private int block_size; // num of bytes in this block
    private int prev_block_size; // num of bytes in last block

    public byte[] output; // compressed output
    public int output_size; // size of compresssed output

    public volatile boolean done = false; // flag to signify if thread has printed its output yet

    // constructor
    public CompThread (byte[] block, byte[] prev_block, int block_size, int prev_block_size, boolean first_block) {
        this.block = block;
        this.prev_block = prev_block;
        this.block_size = block_size;
        this.prev_block_size = prev_block_size;
        this.first_block = first_block;

        if (prev_block_size > Pigzj.DICT_SIZE) {
            dictionary = Arrays.copyOfRange(prev_block, prev_block_size - Pigzj.DICT_SIZE, prev_block_size);
        }
    }

    // indicate this block is the last one to compress 
    public void set_last() {
        this.last_block = true;
    }

    // used to clear memory
    public void clear() {
        output = null; 
    }

    private synchronized void set_done() {
        done = true;
        notify();
    }

    public void compress() {
        // initialize deflater 
        Deflater compressor = new Deflater(Deflater.DEFAULT_COMPRESSION, true);

        if (!first_block) {
            compressor.setDictionary(dictionary); // set dictionary if not the first block
        }

        compressor.setInput(block, 0, block_size); // set input to be this block

        if (last_block) {
            compressor.finish(); // only call on final block
        }

        // set up buffers to store the compressed data
        byte[] output_buf = new byte[2 * Pigzj.BLOCK_SIZE]; 
        ByteArrayOutputStream comp_stream = new ByteArrayOutputStream();
        int comp_bytes;
        
        // runs until all input is compressed
        while ((comp_bytes = compressor.deflate(output_buf, 0, output_buf.length, Deflater.SYNC_FLUSH)) > 0) {
            comp_stream.write(output_buf, 0, comp_bytes);
            output_size = output_size + comp_bytes; // keep track of compressed data size
        }

        // set output for this thread 
        output = comp_stream.toByteArray();

        // set done flag - indicates compression is over
        set_done();
    }

    public void run() {
        this.compress(); 
    }
}