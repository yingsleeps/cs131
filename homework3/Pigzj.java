import java.io.IOException;
import java.io.ByteArrayOutputStream;
import java.util.zip.CRC32;
import java.util.ArrayList;

// write_int and write _short functions from messadmin code to write integers to a byte array 
// and trailer code inspired by messadmin
// credit: https://github.com/MessAdmin/MessAdmin-Core

public class Pigzj {
    public final static int BLOCK_SIZE = 131072; // 128 KiB
    public final static int DICT_SIZE = 32768; // 32 KiB 
    // available processors 
    public static int PROCESSORS;

    private static final byte[] default_header = new byte[]{31, -117, 8, 0, 0, 0, 0, 0, 0, -1};

    private static CRC32 crc = new CRC32(); 
    private static long total_len = 0; 

    private static boolean reuse = false; 
    public static volatile ArrayList<byte[]> blocks = new ArrayList<byte[]>(); // list to keep track of all blocks

    // parse the arguments
    private static void parse_args (String[] args) {
        // no options case
        if (args.length == 0) {
            // set to default
            PROCESSORS = Runtime.getRuntime().availableProcessors();
        } 
        // correct options case
        else if (args.length == 2 && args[0].equals("-p")) {
            try {
                int p_arg = Integer.parseInt(args[1]); 

                // check if too many processors
                if (p_arg > 4 * (Runtime.getRuntime().availableProcessors())) {
                    System.err.println("Error: Too many processors specified.");
                    System.exit(1);
                }

                PROCESSORS = p_arg;
            } catch (Exception err) {
                // catch non num -p arg
                System.err.println("Error: Incorrect arguments :(");
                System.exit(1);
            }
            
        } 
        // incorrect options case
        else {
            System.err.println("Error: Incorrect arguments :(");
            System.exit(1);
        }
    }

	 // writes integer in Intel byte order to a byte array, starting at a
	 // given offset.
    private static void write_int (int i, byte[] buf, int offset) throws IOException {
		write_short(i & 0xffff, buf, offset);
		write_short((i >> 16) & 0xffff, buf, offset + 2);
	}


	// writes short integer in Intel byte order to a byte array, starting
	// at a given offset
	private static void write_short (int s, byte[] buf, int offset) throws IOException {
		buf[offset] = (byte)(s & 0xff);
		buf[offset + 1] = (byte)((s >> 8) & 0xff);
	}

    private static synchronized void join_thread (ArrayList<CompThread> threads, byte[] block, int next, int block_num, int block_size) throws Exception {
        // wait a thread to terminate
        CompThread curr_t = threads.get(next);
        curr_t.join(); 
        curr_t.set_done();
        System.out.write(curr_t.output, 0, curr_t.output_size); // write out its output

        // create new thread for this next block + start it
        threads.add(new CompThread(block, blocks.get(block_num - 1), block_size, BLOCK_SIZE, false));
        threads.get(block_num).start();
    }

    private static void join_threads (ArrayList<CompThread> threads) throws Exception {
        threads.forEach(t -> {
            try {
                if (!t.done) {
                    t.join();
                    System.out.write(t.output, 0, t.output_size);
            }} catch (InterruptedException e) {
                System.err.println("Error: Something went wrong joining the threads.");
                System.exit(1);
            }
        });
    } 

    public static void main(String[] args) throws Exception {
        ArrayList<CompThread> threads = new ArrayList<CompThread>(); // list of all threads -- max length is PROCESSORS
        int block_num = 0; // index of current block
        int next = 0; // first thread to wait for once we run out of processors

        byte [] block = new byte[BLOCK_SIZE];
        ByteArrayOutputStream input_stream = new ByteArrayOutputStream(); // buffer to hold input bytes
        int bytes_read = 0;
        int bytes_sofar = 0; // keep track of how many bytes we've read so far (might take multiple reads to read one block)

        // buffer for trailer bytes - 8 total bytes
        byte[] trailer = new byte[8];

        parse_args(args); // parse options
        
        System.out.write(default_header); // write out header before compressed data

        // check that writes are possible 
        if (System.out.checkError()) {
            System.err.println("Error: Could not write to stdout.");
            System.exit(1);
        }

        // read until no more input 
        while ((bytes_read = System.in.read(block)) > 0) {
            // if we have enough bytes to fill a full block
            if (bytes_sofar + bytes_read >= BLOCK_SIZE) {
                // write out the full block
                input_stream.write(block, 0, BLOCK_SIZE - bytes_sofar);

                // update the crc with this block
                crc.update(input_stream.toByteArray(), 0, BLOCK_SIZE);

                // update blocks list with this block
                blocks.add(input_stream.toByteArray());

                // dispatch a thread to compress this block
                if (!reuse) { // check if we are reusing threads yet
                    // first block - no prev block
                    if (block_num == 0) {
                        threads.add(new CompThread(input_stream.toByteArray(), new byte[0], BLOCK_SIZE, 0, true));
                        threads.get(block_num).start();
                    } else {
                        threads.add(new CompThread(input_stream.toByteArray(), blocks.get(block_num - 1), BLOCK_SIZE, BLOCK_SIZE, false));
                        threads.get(block_num).start();
                    }
                } else { 
                    // need to wait for currently running threads to finish
                    join_thread(threads, input_stream.toByteArray(), next, block_num, BLOCK_SIZE);
                    next++;
                }
                
                // reset the input_stream to receive a new block
                input_stream.reset();
                
                // update bytes_sofar to be the bytes leftover in block after taking the block out
                bytes_sofar = (bytes_read + bytes_sofar) - BLOCK_SIZE; 

                // write the leftover bytes to input_stream
                input_stream.write(block, BLOCK_SIZE - bytes_sofar, bytes_sofar);

                // check if we need to reuse threads 
                if (block_num == PROCESSORS - 1) {
                    reuse = true;
                }
                
                // increment the thread_num to use a new thread for next block
                block_num++; 
            } else {
                // keep track of how many bytes was read 
                bytes_sofar = bytes_sofar + bytes_read; 
                // write the bytes written so far, to be collected into a block later
                input_stream.write(block, 0, bytes_read);
            }

            // keep track of total length read
            total_len = total_len + bytes_read;
        }

        // check if we have leftover bytes in input_stream -- this becomes last block
        if (bytes_sofar > 0) {
            // update crc with last block
            crc.update(input_stream.toByteArray(), 0, bytes_sofar);

            // update blocks array with last block
            blocks.add(input_stream.toByteArray());

            // dispatch thread to compress this last block
            if (!reuse) { // check if we are reusing threads yet
                // first block - no prev block
                if (block_num == 0) {
                    threads.add(new CompThread(input_stream.toByteArray(), new byte[0], bytes_sofar, 0, true));
                    threads.get(block_num).set_last();
                    threads.get(block_num).start();
                } else {
                    threads.add(new CompThread(input_stream.toByteArray(), blocks.get(block_num - 1), bytes_sofar, BLOCK_SIZE, false));
                    threads.get(block_num).start();
                }
            } else { 
                // need to wait for currently running threads to finish
                join_thread(threads, input_stream.toByteArray(), next, block_num, bytes_sofar);
            }
        } else if (blocks.size() > 0) {
            threads.get(blocks.size() - 1).set_last();
        }

        // join all threads + write out each of their outputs
        join_threads(threads);
        
        // write trailer after all the compressed data
        write_int((int) crc.getValue(), trailer, 0);
        write_int((int) total_len, trailer, 4);
        System.out.write(trailer);
    }
}