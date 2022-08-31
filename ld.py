#!/usr/bin/env python3

# ld_file = sys.argv[1]
ld_file = "merge.ld"
output_file = "merge_output.snp"

windows = 10000  # 100kb
max_contig = 1000000  # 1Mb

contig = dict()
with open(ld_file) as f:
    for line in f:
        line = [x for x in line.rstrip('\n').split(' ') if x != '']
        # if line[3] == '24':
        # continue  # skip
        contig_name = line[2].split('_')[0]
        if contig_name not in contig:
            contig[contig_name] = [line]
        else:
            contig[contig_name].append(line)

contig_chromosome = dict()
for contig_name in contig:
    contig_snp = contig[contig_name]
    contig_window = [(x[3], str(int(x[4])//windows)) for x in contig_snp]
    contig_window = {x: contig_window.count(x) for x in contig_window}
    contig_window = sorted(list(contig_window.items()),
                           key=lambda x: x[1], reverse=True)
    contig_window.append((('0', '0'), 0))
    if len(contig_window) > 2:
        contig_window = contig_window[:2]
    # if contig_window[0][1] > 3 * contig_window[1][1]:
    #     contig_window[1] = (('0', '0'), 0)
    # if contig_window[0][0][0] == contig_window[1][0][0]:
    #     if abs(int(contig_window[1][0][1]) - int(contig_window[0][0][1])) < (max_contig / windows):
    #         contig_window[1] = (('0', '0'), 0)
    contig_chromosome[contig_name] = [
        (x[0][0], x[0][1], str(x[1])) for x in contig_window]

# f = open(f"{ld_file}_output.txt", 'w+')
f = open(f"{output_file}", 'w+')
for contig_name in contig_chromosome:
    contig_snp = contig_chromosome[contig_name]
    f.write("\t".join([contig_name,
                      f"chr{contig_snp[0][0]}" if contig_snp[0][0] != "23" else "chrX",
                       str(int(contig_snp[0][1]) * windows),
                       contig_snp[0][2],
                       f"chr{contig_snp[1][0]}" if contig_snp[1][0] != "23" else "chrX",
                       str(int(contig_snp[1][1]) * windows),
                       contig_snp[1][2]]) + '\n')
f.close()
