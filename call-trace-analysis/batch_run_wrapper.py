#!/usr/bin/env python2

import os
import sys
import argparse
import subprocess
import progressbar

"""
Example cmd:
python batch_run_wrapper.py -b ~/work/afl-pt/afl-2.42b/test_progs/libpng-1.6.31/obj-callchain/readpng -d ~/Desktop/libpng-qemu-2017-09-24/ -o ~/Desktop/libpng-qemu-2017-09-24-calltrace -e "cat AFL_FILE | /home/farshaq/work/afl-pt/afl-2.42b/test_progs/libpng-1.6.31/obj-callchain/readpng"


If the program takes input from stdin:
"cat AFL_FILE | /home/farshaq/work/afl-pt/afl-2.42b/test_progs/libpng-1.6.31/obj-callchain/readpng"

If the program takes input from file:
"/home/farshaq/work/afl-pt/afl-2.42b/test_progs/libpng-1.6.31/obj-callchain/readpng AFL_FILE"

"""


def usage():
    print "Usage: python {0} -b BINARY -d CORPUS_DIR -o OUTPUT -e CMD [-t TIMEOUT]" % sys.argv[0]
    print "do pip install progressbar2"

def main():
    exit_success = 0
    exit_failure = 1
    cargs = parse_cmdline()
    return not process_test_cases(cargs)

def get_callchain(target_bin, seed_path, cov_cmd, tmp_out, timeout='3000'):
    #return a string of call ids 
    SUCCESS = 0
    cov = ''
    new_env = os.environ.copy()
    new_env["CALL_TRACE_FILE"] = ".tmp_call_trace."+tmp_out
    if '|' in cov_cmd:
        cov_cmd = cov_cmd[cov_cmd.rindex('|')+1:]+' < '+ seed_path
    else:
        cov_cmd = cov_cmd.replace('AFL_FILE', seed_path)
    g_cmd = ['timeout', str(int(timeout)/1000), cov_cmd]
    g_cmd = ' '.join(g_cmd)
    nullfd = open(os.devnull, 'w')
    r = subprocess.Popen(g_cmd, shell=True, env = new_env, stdout=nullfd, stderr=nullfd)
    r.wait()
    # with open(".tmp_call_trace."+tmp_out, 'r') as f:
    with open(".tmp_call_trace."+tmp_out, 'r') as f:
        cov = f.read()
    f.close()
    nullfd.close()
    return cov



def writeout_callchain_file(chain_list, out_file=None):

    if out_file is not None:
        with open(out_file, 'w') as f:
            f.write('\n'.join(list(chain_list)))
            f.close()



def process_test_cases(args):
    callchain_list = []

    if args.crash_mode == "No":
        all_inputs = os.listdir(args.corpus_dir+"/queue/")
        #calculate how many inputs/callchains we will have
        input_num = len(all_inputs) 
    else:
        all_inputs = os.listdir(args.corpus_dir+"/crashes/")
        #calculate how many crashes/callchains we will have
        input_num = len(all_inputs) 



    bar = progressbar.ProgressBar(max_value=input_num)
    bar_count = 0
    #1 collect callchain for each input
    #1.1 for each input run instrumented binary with corresponding cmdline
    #2 update the callchain_list
    if args.crash_mode == "No":
        _in_queue = "{0}/queue/".format(os.path.dirname(args.corpus_dir))
    else:
        _in_queue = "{0}/crashes/".format(os.path.dirname(args.corpus_dir))

    if not os.path.exists(_in_queue):
        print _in_queue, "not exist"
        sys.exit(-1)
    tout = 3000
    if args.timeout is not None:
        tout = args.timeout 
    for _c in range(input_num):
        seed_path = "%s/%s"%(_in_queue, all_inputs[_c])
        r_chain = get_callchain(args.target_binary, seed_path, str(args.coverage_cmd), args.out_file, tout)
        callchain_list.append(r_chain)

        bar_count += 1
        bar.update(bar_count)
    
    writeout_callchain_file(callchain_list, out_file=args.out_file)



def parse_cmdline():

    p = argparse.ArgumentParser()

    p.add_argument("-e", "--coverage-cmd", type=str, required=True,
            help="Set command to exec (including args, and assumes afl instrumentation support)")
    p.add_argument("-b", "--target-binary", type=str, required=True,
            help="Instrumented binary with llvm-call-chain pass")
    p.add_argument("-d", "--corpus-dir", type=str, required=True,
            help="Path to directory that contains all the corpus generated by a fuzzer")
    p.add_argument("-c", "--crash-mode", type=str, required=False,
                   help="analyze the crashes instead of full corpus [Yes/No]",
                   default="No")
    p.add_argument("-t", "--timeout", type=int, required=False,
            help="Path to directory that contains all the corpus generated by a fuzzer")
    p.add_argument("-o", "--out-file", type=str, required=True,
                   help="File to store accumlated call chains, one input per line (recommend to put in ramdisk)",
                   default='/tmp/.outout')

    return p.parse_args()

if __name__ == "__main__":
    main()
    sys.exit(0)

