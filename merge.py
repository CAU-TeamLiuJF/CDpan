#!/usr/bin/env python3

from heapq import merge
import re
import numpy as np
from scipy import stats
from collections import Counter

max_contig = 10000  # 1Mb

# input_file = sys.argv[1]
input_file = "compare_0.8.txt_Cov4x"

f = open(input_file, 'r')
f.readline()
out = list()
for line in f:
    contig_name = re.search("^\d+", line).group()
    if "A" in line:
        line = [x.split(":") for x in line.rstrip("\n").split(" ") if "A" in x]
        chr = stats.mode([x[2] for x in line])[0][0]
        line = [x for x in line if x[2] == chr]
        out.append(",".join([contig_name,
                             chr,
                             str(round(np.median([int(x[3]) for x in line]))),
                             str(round(np.median([int(x[4]) for x in line])))
                             ]) + "\n")
    elif "L" in line and "R" in line:
        line = [x.split(":")
                for x in line.rstrip("\n").split(" ")
                if "L" in x or "R" in x]
        line_l = [x for x in line if x[1] == "L"]
        line_r = [x for x in line if x[1] == "R"]
        chr = list(set([x
                        for x in [x[2] for x in line_l]
                        if x in [x[2] for x in line_r]]))
        if len(chr) == 0:
            out.append(f"{contig_name},,,\n")
            continue
        chr_num = Counter([x[2] for x in line])
        chr_num_max = max([chr_num.get(x) for x in chr])
        chr = [x for x in chr if chr_num.get(x) == chr_num_max]
        length_tmp = max_contig
        chr_tmp = ''
        r_location_tmp = 0
        l_location_tmp = 0
        for i in chr:
            tmp_l = np.median([int(x[3]) for x in line_l if x[2] == i])
            tmp_r = np.median([int(x[4]) for x in line_r if x[2] == i])
            if abs(tmp_r - tmp_l) <= length_tmp:
                length_tmp = abs(tmp_r - tmp_l)
                chr_tmp = i
                r_location_tmp = tmp_l
                l_location_tmp = tmp_r
        if chr_tmp == '':
            out.append(f"{contig_name},,,\n")
        else:
            if r_location_tmp < l_location_tmp:
                [r_location_tmp, l_location_tmp] = [
                    l_location_tmp, r_location_tmp]
            out.append(",".join([contig_name,
                                 chr_tmp,
                                 str(round(l_location_tmp)),
                                 str(round(r_location_tmp))
                                 ]) + "\n")
    else:
        out.append(f"{contig_name},,,\n")

f.close()

f = open(f"{input_file}_output.csv", 'w+')
for line in out:
    f.write(line)

f.close()
