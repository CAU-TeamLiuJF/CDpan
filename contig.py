#!/usr/bin/env python3

from calendar import c
import copy

windows = 10000  # 100kb
max_contig = 1000000  # 1Mb


def LengthOfContig(contig_1_l, contig_1_r, contig_2_l, contig_2_r):
    if int(contig_1_r) < int(contig_2_l):
        return int(contig_2_l) - int(contig_1_r)
    elif int(contig_1_l) > int(contig_2_r):
        return int(contig_1_l) - int(contig_2_r)
    else:
        return 0


# ld_file = sys.argv[1]
# align_file = sys.argv[2]
# if len(sys.argv) > 3:
#     contig_name_file = sys.argv[3]
# else:
#     contig_name_file = None
ld_file = 'merge_output.snp'
align_file = 'out.20.txt'
contig_name_file = 'dispensable_genome.fasta.fai'

contig_ld = dict()
with open(ld_file) as f:
    for line in f:
        line = line.rstrip('\n').split('\t')
        line[0] = line[0].lstrip('DPS')
        contig_ld[line[0]] = line

f = open(align_file, 'r')
f.readline()  # first line is header

contig_align = dict()
for line in f:
    line = line.rstrip('\n').split('\t')
    if line[1] == 'chrY':
        continue
    line[0] = line[0].lstrip('DSP')
    if line[0] in contig_align:
        contig_align[line[0]].append(line)
    else:
        contig_align[line[0]] = [line]

f.close()

for contig in contig_align:
    if len(contig_align[contig]) > 3:
        contig_align[contig] = sorted(contig_align[contig],
                                      key=lambda x: float(x[-2]))[:3]

if contig_name_file != None:
    with open(contig_name_file) as f:
        contig_name = [x.rstrip('\n').split('\t')[0] for x in f.readlines()]
else:
    contig_name = list(contig_ld.keys()) + list(contig_align.keys())
    contig_name = list(set(contig_name))

contig_res = dict()
for contig in contig_name:
    if contig not in contig_ld and contig not in contig_align:
        continue
    elif contig in contig_ld and contig not in contig_align:
        if (contig_ld[contig][-1] == '0' and int(contig_ld[contig][3]) >= 3) or (contig_ld[contig][1] == contig_ld[contig][-3] and abs(int(contig_ld[contig][2])-int(contig_ld[contig][-2])) <= max_contig) or (int(contig_ld[contig][3]) >= 3*int(contig_ld[contig][-1])):
            contig_res[contig] = [contig_ld[contig][1],
                                  contig_ld[contig][2],
                                  str(int(contig_ld[contig][2])+windows)]
    elif contig not in contig_ld and contig in contig_align:
        if len(contig_align[contig]) == 1 or float(contig_align[contig][0][-2]) * 5 < float(contig_align[contig][1][-2]):
            contig_res[contig] = [contig_align[contig][0][1],
                                  contig_align[contig][0][8],
                                  contig_align[contig][0][9]]
    elif contig in contig_ld and contig in contig_align:
        for i in contig_align[contig]:
            for j in [1, 4]:
                if contig_ld[contig][j] == i[1] and LengthOfContig(contig_ld[contig][j+1],
                                                                   str(int(
                                                                       contig_ld[contig][j+1])+windows),
                                                                   i[8], i[9]) <= max_contig:
                    contig_res[contig] = [i[1], i[8], i[9]]
        if (contig_ld[contig][-1] == '0' and int(contig_ld[contig][3]) >= 3) or (contig_ld[contig][1] == contig_ld[contig][-3] and abs(int(contig_ld[contig][2])-int(contig_ld[contig][-2])) <= max_contig) or (int(contig_ld[contig][3]) >= 3*int(contig_ld[contig][-1])):
            contig_res[contig] = [contig_ld[contig][1],
                                  contig_ld[contig][2],
                                  str(int(contig_ld[contig][2])+windows)]

f = open(f"{align_file}_output.csv", 'w+')
for contig in contig_name:
    if contig in contig_ld:
        res = copy.copy(contig_ld[contig])
    else:
        res = [contig, '', '', '', '', '', '']
    if contig in contig_align:
        for i in contig_align[contig]:
            res.extend([i[1], i[8], i[9]])
        if len(contig_align[contig]) == 1:
            res.extend(['', '', '', '', '', ''])
        elif len(contig_align[contig]) == 2:
            res.extend(['', '', ''])
    else:
        res.extend(['', '', '', '', '', '', '', '', ''])
    if contig in contig_res:
        res.extend(contig_res[contig])
    else:
        res.extend(['', '', ''])
    f.write(",".join(res) + '\n')

f.close()
