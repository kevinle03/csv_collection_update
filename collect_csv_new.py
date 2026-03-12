import serial
import time
import numpy as np
import csv
from datetime import datetime

port = 'COM11'
baud = 921600 # 115200
ser = serial.Serial(port, baud, timeout=1)
filename = datetime.now().strftime('%Y%m%d%H%M%S')+"_imu.csv"
header = ['time_us', 'time_dif_us', 'data_type', 'value_1', 'value_2', 'value_3', 'value_4']
# data_type=0 means linear acceleration
# data_type=1 means game rotation vector
with open(filename, mode='w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(header)
    print(f"Logging data to {filename}. Press Ctrl+C to stop.")
    try:
        while True:
            line = ser.readline().decode('utf-8').strip()
            if line:
                try:
                    row = np.fromstring(line, sep=',').tolist()
                    if len(row) < 7:
                        row.append(0)
                    writer.writerow(row)
                except ValueError:
                    continue
    except KeyboardInterrupt:
        print("\nLogging stopped.")
    finally:
        ser.close()