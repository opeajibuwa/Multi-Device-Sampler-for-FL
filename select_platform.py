import platform
import subprocess

def run_platform_specific_script(output_file):
    current_platform = platform.system().lower()

    if current_platform == 'windows':
        # Run the PowerShell script and redirect output to a text file
        subprocess.run(['powershell.exe', '.\\windows.ps1'], stdout=open(output_file, 'w'), stderr=subprocess.STDOUT)
    elif current_platform == 'linux':
        # Run the Linux shell script and redirect output to a text file
        subprocess.run(['bash', './linux.sh'], stdout=open(output_file, 'w'), stderr=subprocess.STDOUT)
    else:
        print(f"Unsupported platform: {current_platform}")

if __name__ == "__main__":
    output_file = 'output.txt'
    run_platform_specific_script(output_file)
