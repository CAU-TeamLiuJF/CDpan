#!/usr/bin/env python3

import copy
import os
import sys


# Screening threshold control function
def Rate(pairwise_list, threshold):
    # threshold = 0.95
    if float(pairwise_list[10]) / float(pairwise_list[6]) >= threshold:
        # if float(pairwise_list[9]) / float(pairwise_list[1]) >= threshold:
        return True
    return False


def Splicing(pairwise_list_list, threshold):
    # When there are multiple matches, try to merge
    # The sum of matched bases is less than the threshold, no need to merge
    pairwise_new = copy.deepcopy(pairwise_list_list[0])
    pairwise_new[10] = 0
    for line in pairwise_list_list:
        pairwise_new[10] += int(line[10])
    if not Rate(pairwise_new, threshold):
        return False

    # Bubble sort, adjust the order according to the matching position
    # Quick sort is troublesome and don’t want to write, anyway, it’s not useful to get this part
    counter = True
    while counter:
        counter = False
        for i in range(len(pairwise_list_list) - 1):
            if int(pairwise_list_list[i][7]) > int(pairwise_list_list[i+1][7]):
                pairwise_list_list[i], pairwise_list_list[i +
                                                          1] = pairwise_list_list[i+1], pairwise_list_list[1]
                counter = True

    # Try to merge
    pairwise_new = copy.deepcopy(pairwise_list_list[0])
    have_merged = False
    for i in range(1, len(pairwise_list_list)):
        if int(pairwise_list_list[i][7]) - int(pairwise_new[8]) < 100:
            if int(pairwise_list_list[i][7]) - int(pairwise_new[8]) > 0:
                pairwise_new[8] = pairwise_list_list[i][8]
                have_merged = True
            else:
                pass
        else:
            pairwise_new = copy.deepcopy(pairwise_list_list[i])
    # No need to compare thresholds for unmerged
    if have_merged:
        pairwise_new[10] = str(int(pairwise_new[8]) - int(pairwise_new[7]))
        if float(pairwise_new[10]) / float(pairwise_new[6]) >= 1:
            sys.stderr.write(
                "warning: there are some errors when merge those pairwises: \n")
            sys.stderr.write("\n".join([" ".join(x)
                             for x in pairwise_list_list]))
            sys.stderr.write("\n\n")
        return Rate(pairwise_new, threshold)
    else:
        return False


def Comparison(target_string, query_dict, threshold):
    # Match
    if target_string not in query_dict:
        return '0'

    for value in query_dict.get(target_string).values():
        if len(value) == 1:
            if Rate(value[0], threshold):
                return '1'
        elif len(value) > 1:
            for value_value in value:
                if Rate(value_value, threshold):
                    return '1'

            if Splicing(value, threshold):
                return '1'

    return '0'


def Arrange(paf_file, seq_list, location_dict, threshold):
    pad = {}
    with open(paf_file) as f:
        for line in f:
            line = line.rstrip('\n').split('\t')[:12]
            if line[5] not in pad:
                pad[line[5]] = {line[0]: [line]}
                continue

            if line[0] not in pad.get(line[5]):
                pad[line[5]][line[0]] = [line]
            else:
                pad[line[5]][line[0]].append(line)

    for i in range(len(seq_list)):
        com = Comparison(seq_list[i][0], pad, threshold)
        status = location_dict.get(seq_list[i][0], '')
        seq_list[i].append(f'{com}{status}')

    return seq_list


def Location(idv_name, location_dir):
    file_location = os.path.join(location_dir, idv_name)
    location = {}

    with open(os.path.join(file_location, '2a.name')) as f:
        for line in f:
            seq = line.rstrip('\n').split(' ')

            status = 'A'
            contig = seq[0]
            chr = seq[2]
            left = (int(seq[4]) + int(seq[3])) // 2
            right = (int(seq[6]) + int(seq[5])) // 2

            if (left > right):
                left, right = right, left

            if (abs(right - left) > 500):
                status = 'N'
                chr = ''
                left = ''
                right = ''

            location[contig] = f':{status}:{chr}:{left}:{right}'

    with open(os.path.join(file_location, '2bleft.name')) as f:
        for line in f:
            seq = line.rstrip('\n').split(' ')

            status = 'L'
            contig = seq[0]
            chr = seq[2]
            left = (int(seq[4]) + int(seq[3])) // 2
            right = ''

            location[contig] = f':{status}:{chr}:{left}:{right}'

    with open(os.path.join(file_location, '2bright.name')) as f:
        for line in f:
            seq = line.rstrip('\n').split(' ')

            status = 'R'
            contig = seq[0]
            chr = seq[2]
            left = ''
            right = (int(seq[4]) + int(seq[3])) // 2

            location[contig] = f':{status}:{chr}:{left}:{right}'

    with open(os.path.join(file_location, '3.name')) as f:
        for line in f:
            seq = line.rstrip('\n').split(' ')

            status = 'U'
            contig = seq[0]
            chr = seq[1]
            left = ''
            right = ''

            location[contig] = f':{status}:{chr}:{left}:{right}'

    with open(os.path.join(file_location, '4.name')) as f:
        for line in f:
            seq = line.rstrip('\n').split(' ')

            status = 'N'
            contig = seq[0]
            chr = ''
            left = ''
            right = ''

            location[contig] = f':{status}:{chr}:{left}:{right}'

    with open(os.path.join(file_location, '5.name')) as f:
        for line in f:
            seq = line.rstrip('\n').split(' ')

            status = 'N'
            contig = seq[0]
            chr = ''
            left = ''
            right = ''

            location[contig] = f':{status}:{chr}:{left}:{right}'

    return location


threshold = 0.8
fasta, input_dir = sys.argv[1:3]

seq = []
with open(fasta) as f:
    for line in f:
        seq.append([line.rstrip('\n').split(' ')[0], 'PAS:LOCH:CHR:WEST:WEED'])

header = ['#Contig', 'FORMAT']
for idv_name in os.listdir(input_dir):
    loc = Location(idv_name, input_dir)
    seq = Arrange(os.path.join(input_dir, idv_name,
                  f'{idv_name}.aln.paf'), seq, loc, threshold)
    header.append(idv_name)

f = open(os.path.join(input_dir, 'compare.txt'), 'w+')
f.write('''##fileformat=CDpan,v3.0
##FORMAT=<ID=PAS,Type=Boolean,Description="Presence or absence of contig on sample">
##FORMAT=<ID=PAS,Value=1,Explanation="Contig is presence on sample">
##FORMAT=<ID=PAS,Value=0,Explanation="Contig is absence on sample">
##FORMAT=<ID=LOCH,Type=char,Description="The location of contig on chromosome">
##FORMAT=<ID=LOCH,Value=A,Explanation="The positions of a contig's two-ends that relative to the reference genome could be located">
##FORMAT=<ID=LOCH,Value=L,Explanation="The position of a contig's left-end that relative to the reference genome could be located">
##FORMAT=<ID=LOCH,Value=R,Explanation="The position of a contig's right-end that relative to the reference genome could be located">
##FORMAT=<ID=LOCH,Value=U,Explanation="The contig just could located in the chromosome relative to the reference genome">
##FORMAT=<ID=LOCH,Value=N,Explanation="The contig could not located the positions relative to the reference genome">
##FORMAT=<ID=CHR,Type=String,Description="Which chromosome contig is location, null for unknown">
##FORMAT=<ID=WEST,Type=Integer,Description="The position of a contig's left-end located, null for unknown">
##FORMAT=<ID=WEED,Type=Integer,Description="The position of a contig's right-end located, null for unknown">
''')
f.write('\t'.join(header) + '\n')
for line in seq:
    f.write('\t'.join(line) + '\n')
f.close()
