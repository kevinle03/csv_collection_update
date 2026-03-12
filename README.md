1. in the PlatformIO project, open the folder 'src' and replace 'main.cpp' with 'main_timer.cpp'
2. Build and upload to the ESP32
3. run the new 'collection_csv_new.py' Python script
4. once the data has been collected, it will save to a .csv file
5. in 'stroke_count_new.m' in MATLAB, change the .csv file path in line 1 of the code to the .csv file you want
6. run the MATLAB code to get the stroke count and plot of the peaks

note: 'slow_fast_slow_fast_5each.csv' is a sample file of what the data collection would produce
