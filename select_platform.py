import platform
import subprocess
import re
import json
import time
import shutil



def has_nvidia_gpu():
    # Use shutil.which to check if the nvidia-smi executable is in the PATH
    return shutil.which('nvidia-smi') is not None


def convert_json_windows(filename):
    # Specify the path to the input text file
    input_file_path = filename

    # Read the content from the file
    with open(input_file_path, 'r') as file:
        txt_content = file.read()

    if has_nvidia_gpu():
        # Define regex patterns to extract sections
        section_patterns = {
            'Static CPU Information': 'Static CPU Information:(.*?)Dynamic CPU Information:',
            'Dynamic CPU Information': 'Dynamic CPU Information:(.*?)Semi-Static Memory Information:',
            'Semi-Static Memory Information': 'Semi-Static Memory Information:(.*?)Dynamic Memory Information:',
            'Dynamic Memory Information': 'Dynamic Memory Information:(.*?)GPU Information:',
            'GPU Information': 'GPU Information:(.*?)GPU Running Processes:',
            'GPU Running Processes': 'GPU Running Processes:(.*?)Current Network Interface Information:',
            'Current Network Interface Information': 'Current Network Interface Information:(.*?)Network Performance Metrics:',
            'Network Performance Metrics': 'Network Performance Metrics:(.*?)Operating System Info:',
            'Operating System Info': 'Operating System Info:(.*?)Power/Battery Info:',
            'Power/Battery Info': 'Power/Battery Info:(.*?)$'
        }
    
    else:
        section_patterns = {
            'Static CPU Information': 'Static CPU Information:(.*?)Dynamic CPU Information:',
            'Dynamic CPU Information': 'Dynamic CPU Information:(.*?)Semi-Static Memory Information:',
            'Semi-Static Memory Information': 'Semi-Static Memory Information:(.*?)Dynamic Memory Information:',
            'Dynamic Memory Information': 'Dynamic Memory Information:(.*?)Current Network Interface Information:',
            'Current Network Interface Information': 'Current Network Interface Information:(.*?)Network Performance Metrics:',
            'Network Performance Metrics': 'Network Performance Metrics:(.*?)Operating System Info:',
            'Operating System Info': 'Operating System Info:(.*?)Power/Battery Info:',
            'Power/Battery Info': 'Power/Battery Info:(.*?)$'
        }
    

    # Initialize an empty dictionary to store the extracted data
    data = {}

    # Iterate through each section and extract information
    for section_name, pattern in section_patterns.items():
        section_content = re.search(pattern, txt_content, re.DOTALL).group(1).strip()

        # Special handling for "Dynamic Memory Information" and "GPU Running Processes"
        if section_name == "Dynamic Memory Information":
            # Extract each line as a separate item in a list
            process_lines = [line.strip() for line in section_content.split('\n') if line.strip() and line.strip() != '------------------------']
            # Convert each line to key-value pairs and add to a list
            section_data = [dict([line.split(':', 1)]) for line in process_lines]
        elif section_name == "GPU Running Processes":
            # Extract each line containing "PID" and "Process Name" as a separate item in a list
            section_data = [{"PID": match.group(1).strip(), "Process Name": match.group(2).strip()} for match in re.finditer(r'PID: (\d+)\nProcess Name: (.+)', section_content)]
        else:
            # Convert section content to key-value pairs
            section_data = {}
            for line in section_content.split('\n'):
                if ':' in line:
                    key, value = map(str.strip, line.split(':', 1))
                    section_data[key.lower()] = value

        # Add section data to the main dictionary
        data[section_name] = section_data

    # Convert dictionary to JSON
    json_data_windows = json.dumps(data, indent=4)

    # Save JSON to a file
    output_file_path = "output.json"
    with open(output_file_path, 'w') as output_file:
        output_file.write(json_data_windows)


def convert_json_linux(filename):
    # Specify the path to the input text file (Linux)
    input_file_path_linux = filename

    # Read the content from the Linux file
    with open(input_file_path_linux, 'r') as file_linux:
        linux_content = file_linux.read()

    if has_nvidia_gpu():
        # Define regex patterns to extract sections
        section_patterns = {
        'Static CPU Information': 'Static CPU Information:(.*?)Dynamic CPU Information:',
        'Dynamic CPU Information': 'Dynamic CPU Information:(.*?)Semi-Static Memory Information:',
        'Semi-Static Memory Information': 'Semi-Static Memory Information:(.*?)Dynamic Memory Information:',
        'Dynamic Memory Information': 'Dynamic Memory Information:(.*?)List of Top 10 Processes by Memory Utilization:',
        'List of Top 10 Processes by Memory Utilization': 'List of Top 10 Processes by Memory Utilization:(.*?)GPU Information:',
        'GPU Information': 'GPU Information:(.*?)Network Interface Information:',
        'Network Interface Information': 'Network Interface Information:(.*?)Network Performance Metrics:',
        'Network Performance Metrics': 'Network Performance Metrics:(.*?)Operating System \(OS\) Info:',
        'Operating System (OS) Info': 'Operating System \(OS\) Info:(.*?)Battery/Power Info:',
        'Battery/Power Info': 'Battery/Power Info:(.*?)(?:$|$)',
        }
    
    else:
        section_patterns = {
        'Static CPU Information': 'Static CPU Information:(.*?)Dynamic CPU Information:',
        'Dynamic CPU Information': 'Dynamic CPU Information:(.*?)Semi-Static Memory Information:',
        'Semi-Static Memory Information': 'Semi-Static Memory Information:(.*?)Dynamic Memory Information:',
        'Dynamic Memory Information': 'Dynamic Memory Information:(.*?)List of Top 10 Processes by Memory Utilization:',
        'List of Top 10 Processes by Memory Utilization': 'List of Top 10 Processes by Memory Utilization:(.*?)GPU Information:',
        'GPU Information': 'GPU Information:(.*?)Network Interface Information:',
        'Network Interface Information': 'Network Interface Information:(.*?)Network Performance Metrics:',
        'Network Performance Metrics': 'Network Performance Metrics:(.*?)Operating System \(OS\) Info:',
        'Operating System (OS) Info': 'Operating System \(OS\) Info:(.*?)Battery/Power Info:',
        'Battery/Power Info': 'Battery/Power Info:(.*?)(?:$|$)',
        }
        

    # Initialize an empty dictionary to store the extracted data (Linux)
    data_linux = {}

    # Iterate through each section and extract information (Linux)
    for section_name, pattern in section_patterns.items():
        match = re.search(pattern, linux_content, re.DOTALL)
        
        # Check if a match is found
        if match:
            section_content = match.group(1).strip()

            # Special handling for "List of Top 10 Processes by Memory Utilization"
            if section_name == "List of Top 10 Processes by Memory Utilization":
                # Extract each line as a separate item in a list
                process_lines_linux = [line.strip() for line in section_content.split('\n') if line.strip()]
                # Convert each line to key-value pairs and add to a list
                section_data_linux = []
                for line in process_lines_linux:
                    parts = line.split(': ', 1)
                    if len(parts) == 2:
                        key, value = map(str.strip, parts)
                        section_data_linux.append({key.lower(): value})
            else:
                # Convert section content to key-value pairs
                section_data_linux = {}
                for line in section_content.split('\n'):
                    if ':' in line:
                        key, value = map(str.strip, line.split(':', 1))
                        section_data_linux[key.lower()] = value

            # Add section data to the main dictionary (Linux)
            data_linux[section_name] = section_data_linux
        else:
            print(f"No match found for section: {section_name}")
            print(f"Unmatched content: {linux_content}")

    # Convert dictionary to JSON (Linux)
    json_data_linux = json.dumps(data_linux, indent=4)

    # Save JSON to a file (Linux)
    output_file_path_linux = "linux_output.json"
    with open(output_file_path_linux, 'w') as output_file_linux:
        output_file_linux.write(json_data_linux)

def run_platform_specific_script(output_file):
    current_platform = platform.system().lower()

    if current_platform == 'windows':
        # Run the PowerShell script and redirect output to a text file
        subprocess.run(['powershell.exe', '.\\windows.ps1'], stdout=open(output_file, 'w'), stderr=subprocess.STDOUT)
        time.sleep(90)
        convert_json_windows("output.txt")
        print("Windows system info extracted and a JSON output file is generated!")

    elif current_platform == 'linux':
        # Run the Linux shell script and redirect output to a text file
        subprocess.run(['bash', './linux.sh'], stdout=open(output_file, 'w'), stderr=subprocess.STDOUT)
        time.sleep(90)
        convert_json_linux("output.txt")
        print("Linux system info extracted and a JSON output file is generated!")

    else:
        print(f"Unsupported platform: {current_platform}")


if __name__ == "__main__":
    output_file = 'output.txt'
    run_platform_specific_script(output_file)
