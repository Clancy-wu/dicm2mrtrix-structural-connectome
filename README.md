# The script processing DICOM data to MRtrix3
Hi, this is a script for building a brain structural connectivity matrix, via heudiconv and mrtrix3, from DICOM data to final connectome matrix.  
This script is created by Kang Wu, Dongzhimen Hospital of Beijing University of Chinese Medicine.  
If this helped you, please add a start and follow me.  

# Method to use
Method 1: You are recommended to run "sh Mrtrix_Script.sh", and all processes will be autimatically performed.  
However, you are required to input your sudo password during the processes (only one step requires), after Heudiconv steps finished.  
To avoid the extra input within the processes, method 2 and 3 can also be try.  
Method 2: type "sudo ./Mrtrix_Script.sh" and input your password begined the script.  

It seems that method2 will take bug in sometime, reportting "command not found". For safety use, I recommand you choose Method1.
Howver, in order to escape the root identity proces, I recommand you first use "sudo mkdir XX" or someting else, and then type "sh Mrtrix_Script.sh". Because the password will be remained for several minutes, you can run this script and drink an coffee and just wait.

# Details for the script
1. The script contains Heudiconv and Mrtrix3, which means both of the softwares are required to be installed in the computer.  
2. The BIDS format data created by Heudiconv is an right-limited file, so the sudo password is needed to perfrom the BIDS data through Mrtirx3, which is the reason that you shuold input the password during the processes (only one time required).   
Maybe i will update this script in the future (if possible).  
3. The script contains almost every recommended steps in the mrtrix3 document, except the distortion correction. Since my fMRI data includs only one non-zero b value, distortion correction cannot be performed and MSMT also cannot. Thus, a single tensor model was used in the script, and the linear registration as well as ACT is performed to minimize the influence of the absent distortion correction, which will make the result more reliable and reproductable.  

# Spplementary informations about the script
My computer CPU: i7-11700k  
Running time of the script: 6 hours  
Original size of the data files: 935MB  
Final size of the files: 11.5GB  
Ratio between the size of the orignial and the final: 12.6  
Files in the mid-proceeses: retained.  
With these mid-processes files, the TBSS and Result Visualization can easily be accomplished.  

My email address : clancy_wu@126.com

