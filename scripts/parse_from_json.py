import json
import sys

if __name__ == '__main__':
	input_file = sys.argv[1]
	output_file = sys.argv[2]
	with open(input_file, 'r') as fin, open(output_file, 'w') as fout:
		for line in fin.readlines():
			stemmed = []
			try:
				data = json.loads(line)
				if data:
					for word in data[0]:
						stemmed.append(word['stem'])
					fout.write(' '.join(stemmed) + '\n')
				else:
					print("Empty.")
					fout.write('\n')
			except:
				fout.write(line.strip() + '\n')