import csv
import matplotlib.pyplot as plt
num_procs = 5
file_name = "mlfq5_16.csv"
data = [ [] for _ in range(num_procs)]

with open(file_name, "r") as file:
    reader = csv.reader(file)
    for line in reader:

        data[int(line[1])-4].append ([int(line[0]), int(line[2])])


for i in range(num_procs):
    plt.plot([ j[0] for j in data[i] ], [j[1] for j in data[i]], label = "PID:"+str(i+4))
plt.legend()
plt.show()