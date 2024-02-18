import java.util.zip.Deflater;
import java.io.ByteArrayOutputStream;
import java.util.Arrays;

public class CompThread extends Thread {

    // flags for first and last block
    private boolean first_block;
    private boolean last_block;

    private byte[] dictionary;

    private byte[] block; // this block 
    private byte[] prev_block; // previous block

    private int block_size; // num of bytes in this block
    private int prev_block_size; // num of bytes in last block

    public byte[] output; // compressed output
    public int output_size; // size of compresssed output

    public boolean done = false; // flag to signify if thread has printed its output yet

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

    public void set_last() {
        this.last_block = true;
    }

    public void set_done() {
        done = true;
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
        
        // runs until the end of the compressor input
        while ((comp_bytes = compressor.deflate(output_buf, 0, output_buf.length, Deflater.SYNC_FLUSH)) > 0) {
            comp_stream.write(output_buf, 0, comp_bytes);
            output_size = output_size + comp_bytes;
        }

        // set output for this thread 
        output = comp_stream.toByteArray();
    }

    public void run() {
        this.compress(); 
    }
}