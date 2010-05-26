#!/usr/bin/env python
# plot charts

import csv

from pylab import *

# data dict
data = dict()

reader = csv.reader(open('result/report.csv'), delimiter=',')
for row in reader:
    data[row[0]] = row[1:]

pos = arange(len(data)) + 0.5

benchitem = ["write", "index", "q30", "qall", "datasize"]

for i in xrange(len(benchitem)):
    val = []
    tit = []
    
    for k in data:
        val.append(float(data[k][i]))
        tit.append(k)
    
    figure(num=i, figsize=(6, 4), dpi=80)
    barh(pos, val, align='center')
    yticks(pos, tit)
    xlabel('Time')
    title('NoSQL Storage for Time Series Data: ' + benchitem[i])
    grid(True)
    savefig('result/' + benchitem[i] + '.png');

show()

