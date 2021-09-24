import sys, os

full_file = sys.argv[1]
input_dir = sys.argv[2]
output_dir = sys.argv[3]
if len(sys.argv) > 4:
	suffix = sys.argv[4]
else:
	suffix = ""

all_files = sorted(os.listdir(input_dir))

with open(full_file) as f_full:
	for each_file in all_files:
		output_file = open(os.path.join(output_dir,each_file+suffix),'w')
		num_lines = len(open(os.path.join(input_dir,each_file)).readlines())
		count = 0
		while count < num_lines:
			output_file.write(f_full.readline())
			count += 1
		output_file.close()
