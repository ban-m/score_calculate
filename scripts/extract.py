#!/usr/bin/env python3
import ont_fast5_api.analysis_tools.event_detection
import ont_fast5_api.fast5_info
import itertools
from pathlib import Path
import sys
import json


class DataEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Data):
            return {
                'id': obj.read_id,
                # 'starts': obj.starts,
                # 'lengths': obj.lengths,
                'means': obj.means,
                # 'stdvs': obj.stdvs
            }
        else:
            print(obj)
            return json.JSONEncoder.default(self, obj)

class Data:
    def __init__(self, path, length):
        data = ont_fast5_api.analysis_tools.event_detection.EventDetectionTools(path).get_event_data()
        start = data[1]['start_time']
        self.read_id = data[1]['read_id']
        # self.starts = list(itertools.islice(map(lambda x: int(x[0]-start), data[0]), length)) 
        # self.lengths = list(itertools.islice(map(lambda x: int(x[1]), data[0]), length))
        self.means = list(itertools.islice(map(lambda x: float(x[2]), data[0]), length))
        # self.stdvs = list(itertools.islice(map(lambda x: float(x[3]), data[0]), length))
        
if __name__=='__main__':
    DATA_DIR=sys.argv[1]
    EVENT_LENGTH=int(sys.argv[2])
    OUTPUT=sys.argv[3]
    TAKE_NUM=120000
    print("Read from {}. Event length:{}.".format(DATA_DIR, EVENT_LENGTH))
    print("Read Out to {}".format(OUTPUT))
    directory = Path(DATA_DIR)
    with open(OUTPUT, 'w') as output: 
        result = list(itertools.islice(map(lambda file: Data(str(file), EVENT_LENGTH), directory.glob('*.fast5')), TAKE_NUM))
        records = {'records': result}
        json.dump(records, output, cls = DataEncoder)


