# Import packages
import pynput
from pynput.keyboard import Key
import time
import datetime
from datetime import timedelta
import pyperclip
import argparse
import os, sys, io
from pathlib import Path
from tkinter import *

# ------ Hardcode coordinates of different points on the screen ------
coords = {
'address_bar': (), 'screening_and_analysis': (), 'research': (), 'contributor': (), 
'refinitiv_streetevents': (), 
'start_date_candidate_1': (), 'start_date_candidate_2': (), 'end_date_candidate_1': (), 'end_date_candidate_2': (),
'number_of_conference_calls': (), 'next_page': (), 
'select_all_main': (),
'view_main': (),
'select_all_toc': (),
'view_toc': (),
'xls_icon_multiple_pages': (),
'xls_icon_one_page': (),
'reselect_thomsonone_window': ()
}

# ------ Read in command-line arguments ------
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Download conference calls from Thomson One, with date range = start_date - end_date. Code starts downloading most recent reports, and ends off with oldest reports, in sets of 4 days (i.e. code downloads backwards from end_date to start_date). Code will go past the start date if the number of days is not a multiple of 4. Enter arguments in the order listed below.')
    parser.add_argument('suffix', help="suffix indicating a particular data pull, e.g. if the folder is '01.1_pdf_2', the suffix is '2'; quotation marks around the string is optional.", type=str)
    parser.add_argument('start_year', help="start date of pull - year (e.g. 2021)", type=int)
    parser.add_argument('start_month', help="start date of pull - month (e.g. 1)", type=int)
    parser.add_argument('start_day', help="start date of pull - day (e.g. 1)", type=int)
    parser.add_argument('end_year', help="end date of pull - year (e.g. 2021)", type=int)
    parser.add_argument('end_month', help="end date of pull - month (e.g. 1)", type=int)
    parser.add_argument('end_day', help="end date of pull - day (e.g. 1)", type=int)
    parser.add_argument('output_pdf_folder', help="path of output folder containing pdf files", type=str)
    parser.add_argument('output_xls_folder', help="path of output folder containing xls files", type=str)
    args = parser.parse_args()
    suffix = args.suffix
    output_pdf_folder = Path(args.output_pdf_folder)
    output_xls_folder = Path(args.output_xls_folder) 

# ------ Print screen size and command-line arguments ------
# Get screen size
root = Tk()
monitor_height = root.winfo_screenheight()
monitor_width = root.winfo_screenwidth()
  
print("--- Screen size ---")
print("width x height: %d x %d (pixels)" %(monitor_width, monitor_height))
print("")

# Set initial and end date
date_start = datetime.date(year=args.end_year, month=args.end_month, day=args.end_day)
date_end = datetime.date(year=args.start_year, month=args.start_month, day=args.start_day)
date_start_current = date_end + timedelta(days = 1)

# Print command-line arguments
print("Data pull used:", suffix)
print("Start date:", date_start)
print("End date:", date_end)
print("Output pdf folder:", output_pdf_folder)
print("Output xls folder:", output_xls_folder)

# Open keyboard and mouse Controller
KB_enter = pynput.keyboard.Controller()
MS_enter = pynput.mouse.Controller()

# ------ Functions ------
def mouse_click(position, delay = 0):
    MS_enter.position = position
    MS_enter.click(pynput.mouse.Button.left, 1)
    time.sleep(delay)

def mouse_double_click(position, delay = 0):
    MS_enter.position = position
    MS_enter.click(pynput.mouse.Button.left, 2)
    time.sleep(delay)

def enter_string(string, delay = 0):
    KB_enter.type(string)
    time.sleep(delay)

def press_key(key, delay = 0):
    KB_enter.press(key)
    KB_enter.release(key)
    time.sleep(delay)

def close_window(delay = 0):
    with KB_enter.pressed(Key.alt):
        press_key(Key.f4)
    time.sleep(delay)

def expand_screen(delay = 0):
    with KB_enter.pressed(Key.cmd):
        press_key(Key.up)
    time.sleep(delay)

def save_pdf_hotkey(delay = 0):
    with KB_enter.pressed(Key.shift, Key.ctrl):
        press_key('s')   
    time.sleep(delay)

# Generate ideal time-window strings to be typed into date (legacy function)
def get_dates(date_start_current, time_delta):
    date_end_current = date_start_current - timedelta(days=1)
    date_start_current = date_start_current - timedelta(days=time_delta)

    return [
    '{0:02d}/{1:02d}/{2:02d}'.format(date_start_current.month, date_start_current.day, date_start_current.year%100), 
    '{0:02d}/{1:02d}/{2:02d}'.format(date_end.month, date_end.day, date_end.year%100), 
    '{0}{1:02d}{2:02d}-{3}{4:02d}{5:02d}'.format(date_start_current.year, date_start_current.month, date_start_current.day, date_end_current.year, date_end_current.month, date_end_current.day)
    ]

def login_and_enter_query(date_start_current, date_end_current = 0, date_range_current = 0, get_new_dates = True):
    # Enter http://proxy.uchicago.edu/login/thomsonone"
    mouse_click(coords['address_bar'], 1)
    enter_string("http://proxy.uchicago.edu/login/thomsonone")
    press_key(Key.enter)

    # Go to: Screening & Analysis -> Research"
    mouse_click(coords['screening_and_analysis'], 1) 
    mouse_click(coords['research'], 1)

    # Set Contributor to 'REFINITIV STREETEVENTS'
    mouse_click(coords['contributor'], 0.5)
    enter_string("STREETEVENTS")
    time.sleep(1)
    mouse_click(coords['refinitiv_streetevents'],0.5)

    # Get dates
    if get_new_dates:
        date_start_current, date_end_current, date_range_current = get_dates(date_start_current, 4)

    ##### type in start date, and end date #####
    print('Current 4-day window:', date_range_current)

    # Type start date
    mouse_click(coords['start_date_candidate_1'],0.5)
    mouse_click(coords['start_date_candidate_2'],0.5)
    enter_string(date_start_current)
    time.sleep(0.5)

    # Type end date
    mouse_click(coords['end_date_candidate_1'],0.5)
    mouse_click(coords['end_date_candidate_2'],0.5)
    enter_string(date_end_current)
    time.sleep(0.5)
    
    # Search for conference calls and wait for results to display
    press_key(Key.enter) 
    time.sleep(3)

    return date_start_current, date_end_current, date_range_current

def get_number_of_conference_calls():
    pyperclip.copy("")
    mouse_double_click(coords['number_of_conference_calls'],0.5)
    with KB_enter.pressed(Key.ctrl):
        press_key('c')
    time.sleep(0.5)
    number_of_conference_calls = pyperclip.paste()
    return number_of_conference_calls

def get_number_of_pages_of_conf_calls(number_of_conference_calls):
    # 50 conf calls -> 1 page, 100 conf calls -> 2 pages
    if number_of_conference_calls % 50 == 0:
        number_of_pages_of_conf_calls = number_of_conference_calls // 50
    # 51 conf cals -> 2 pages, 101 conf calls -> 3 pages
    else:
        number_of_pages_of_conf_calls = number_of_conference_calls // 50 + 1
    return number_of_pages_of_conf_calls

# ------ Main loop ------
### Note: Before you run the code, open Internet Explorer.

print("Main loop starting in 3 seconds!")
time.sleep(3)
restarted_process = False

while date_start >= date_start_current:
    # Login and query with a 4-day time-window
    if restarted_process:
        print("Restarted process")
        date_start_current, date_end_current, date_range_current = login_and_enter_query(date_start_current, date_end_current, date_range_current, get_new_dates = False)
        restarted_process = False
    else:
        print("Continuing process")
        date_start_current, date_end_current, date_range_current = login_and_enter_query(date_start_current, get_new_dates = True)
    
    # Get number of conference calls and number of pages of conference calls to scroll through
    try:
        number_of_conference_calls = get_number_of_conference_calls()
        if number_of_conference_calls == "query":
            number_of_conference_calls = 0
        number_of_conference_calls = int(number_of_conference_calls)
        number_of_pages_of_conf_calls = get_number_of_pages_of_conf_calls(number_of_conference_calls)
        print("Number of conference calls:", number_of_conference_calls)
        print("Number of pages of conference calls:", number_of_pages_of_conf_calls)
    except ValueError: 
        print("Error occurred when trying to turn number of conference calls into int, restarting process")
        restarted_process = True
        continue
    
    # Loop over each page
    for current_page in range(number_of_pages_of_conf_calls):
        print("Currently at page", current_page + 1, "/", number_of_pages_of_conf_calls)

        # Get filepaths
        output_pdf_filename = date_range_current + '_' + str(current_page + 1) + '.pdf'
        output_xls_filename = date_range_current + '_' + str(current_page + 1) + '.xls'
        output_pdf_filepath = Path(output_pdf_folder / output_pdf_filename)
        output_xls_filepath = Path(output_xls_folder / output_xls_filename)

        # If pdf and xls already exists, skip page
        if os.exists(output_pdf_filepath) and os.exists(output_xls_filepath):
            print("Pdf and xls of current page already exists, skipping page")
            mouse_click(coords['next_page'], 5) 
            print("Finished page", current_page, "/", number_of_pages_of_conf_calls)
            continue
        
        # Else, select all reports and download the missing pdf and/or xls
        mouse_click(coords['select_all_main'], 1)

        # Get the pdf
        if os.exists(output_pdf_filepath):
            print("pdf already exists, skipping pdf:", output_pdf_filepath)
        else:
            print("pdf does not exist, downloading pdf:", output_pdf_filepath)

            # View -> Select all -> View
            mouse_click(coords['view_main'], 3)
            mouse_click(coords['select_all_toc'], 1)
            mouse_click(coords['view_toc'], 6)
            expand_screen(2)

            # if no new file is downloaded, keep rerunning the process up to the stop limit
            attempt = 1
            while not(os.path.exists(output_pdf_filepath)):
                # Stop limit
                print('Saving xls: attempt', attempt)
                if attempt > 5: 
                    print('Reached 5 attempts, pausing process for 1 minute for manual fix')
                    time.sleep(60)
                if attempt > 10: 
                    print('Reached max number of attempts (10), restarting process')
                    restarted_process = True
                    break
                attempt = attempt + 1
                
                # Save 
                save_pdf_hotkey()
                # Type the file name
                enter_string(str(output_pdf_filepath), 0.5)
                press_key(Key.enter, 10)
                close_window(5)
 
            # Close the inner and outer windows
            print('Closing the window')
            close_window(1)
            close_window(1)
            mouse_click(coords['reselect_thomsonone_window'],2) 

        # Get the xls
        if os.exists(output_xls_filepath):
            print("xls already exists, not downloading xls:", output_xls_filepath)
        else:
            print("xls does not exist, downloading xls:", output_xls_filepath)

            # If no new file is downloaded, keep rerunning the process up to the stop limit
            attempt = 1
            while not(os.exists(output_xls_filepath)):
                # Stop limit
                print('Saving xls: attempt', attempt)
                if attempt > 5: 
                    print('Reached 5 attempts, pausing process for 1 minute for manual fix')
                    time.sleep(60)
                if attempt > 10: 
                    print('Reached max number of attempts (10), restarting process')
                    restarted_process = True
                    break
                attempt = attempt + 1

                # Click on the excel icon
                if number_of_pages_of_conf_calls > 1:
                    mouse_click(coords['xls_icon_multiple_pages'], 1)
                else:
                    mouse_click(coords['xls_icon_one_page'], 1)

                # Save -> save as
                mouse_click(coords['xls_save_more_options'], 0.5)
                mouse_click(coords['xls_save_as'], 1)
                # Type the file name
                enter_string(str(output_xls_filepath), 0.5)
                press_key(Key.enter, 1)

        # De-select the reports
        mouse_click(coords['select_all_main'], 1)
        # Go to next page
        mouse_click(coords['next_page'], 2.5)

        print("Finished page", current_page + 1, "/", number_of_pages_of_conf_calls)  

# ------ Summary ------
print("")
print("Finished main loop!")