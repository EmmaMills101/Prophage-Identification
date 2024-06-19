# Prophage-Identification
Prophage Identification workflow for 154 ST131 E. coli Genomes DOI: 10.1101/2023.12.11.571174

# Workflow for identifying and comparing prophage sequences from bacterial genomes using Phastest (https://phastest.ca/databases) and shell scripts on a Linux Machine

# Step 1: Installation
Install phastest on machine using intructions detailed here: https://phastest.ca/databases

# Step 2: Setting up analysis
Move all assemblies to screen to ~/slurm-docker-cluster/phastest_inputs

# Step 3: Running phastest
Navigate to ~/phastest_inputs on command line and run phastest on assemblies with flags for phage annotation only to decrease computation time. Below is an example of the command. If running on multiple assemblies, create a bash script based on the command below, replacing the assembly ID

    % docker compose run phastest -i fasta -s DVT1282.fasta --yes --phage-only -m lite

    Note: If running phastest on multiple assemblies on a linux machine, you may need to bypass     sudo authorization or you will have to input your password for each genome screen. To           bypass sudo, follow these directions: https://askubuntu.com/questions/477551/how-can-i-use-     docker-without-sudo)

# Step 4: Prefixing unlabeled results
Phastest output for each assembly will be in ~/slurm-docker-cluster/phastest-app-docker/JOBS. For this analysis, the region_DNA.txt and summary.txt contain the nucleotide sequences and genomic information of the prophages identified in the assemblies, respectively. Below are details on these files. You will notice that these files are not prefixed with the assembly ID, therefore if we concantenate them you cannot disentagle the results. To add a prefix to these files based on assembly id, navigate to ~/JOBS (where the phastest outputs are) and run the shell script "rename_files.sh"
    % sh rename_files.sh 

Note: region_DNA.txt contain the nucleotide sequences of each prophage identified in that assembly by Phastest. The prophages are separated by ">" and the numbering correspondes to the numbers found in "Main" column in the summary.txt file. The summary.txt file contains additional data on the prophage such as, length, corrdinates in genome, GC%, completeness, and phage will the most common hit. These are the two files used for this analysis. 

# Step 5: Separating out results
Now that the output files are prefixed, move the region_DNA.txt files and summary.txt files into separate folders:
    % mkdir DNA_regions
    % cp */*DNA* DNA_regions
    % mkdir summary_files
    % cp */*summary* summary_files

# Step 6: Cleaning DNA_region file names
Navigate to ~/DNA_regions. This folder should hold all prophage nucleotide sequences for each assembly screened. In order to perform an all x all blast to assess genetic similarity, we need to make sure the prophages in each assembly are accurately named. First, we will clean the file names so they are only named by the assembly ID. The command below will remove all text after and including the underscore from the file names. For example: DVT1282_regions_DNA.txt will become DVT1282.txt. Once this is done, we want to change these .txt files to .fasta files for the blast anlysis.
    % find . -type f -name '*_*.*' -exec bash -c 'newname="$(basename "$0" | sed "s/_.*\(\.[^.]*\)$/\1/")"; mv "$0" "$(dirname "$0")/$newname"' {} \;

    % find . -type f -name '*.txt' -exec bash -c 'mv "$0" "${0%.txt}.fasta"' {} \;

# Step 7: Prefixing prophages with assembly ID
If you open a region_DNA.txt file, you will notice that the lines all start with > followed by a number corresponding to the prophage identified in that assembly and the corrdinates of the prophage on that contig, for example >1   2000-50000. The prophage number and genome corrdinates are separated by a tab and a space. In order to perform an all x all blast, we need to first prefix the prophages in each region_DNA.txt file with the respective assembly ID and replace the tab and space with an underscore. If this is not done, blast.py will not be able to correctly parse the prophage IDs.   
    # Prefixing prophages with assembly ID run "rename_prophages.sh" shell script
    % sh rename_prophages.sh /path/to/DNA_regions

    # Removing "tab" and replacing with underscore from all lines starting with >
    % find . -type f -name '*.fasta' -exec sed -i -e '/^>/ s/\t/_/g' {} \;
    
    Note: make sure you are in DNA_regions directory to run the above and below commands 
    
    # Remove extra space from all lines starting with >
    % find . -type f -name '*.fasta' -exec sed -i -e '/^>/ s/ //g' {} \;

    The above commands should change prophage IDs for each assembly from >1   2000-50000 to         >AssemblyID_1_2000-50000 which is now parsable by blast.py

# Step 8: Concatentate all fasta files into a multi.fasta for makeblastdb input
To make blast database concatenate all fasta files into to a multi.fasta
% cat *.fasta > multi.fasta

# Step 9: Make blast database
Make blast database based on multi.fasta of concantenated prophages for each assembly. Output databased should be moved into directory named db
% makeblastdb -in multi.fasta -title db -out db -dbtype nucl -parse_seqids
% mkdir db
% mv *db* db

# Step 10: Run all x all blast
To perform an all x all blast you need to separate all of the prophages for each genome so each prophage is compared against the blast database. Use first command below to separate out the each prophage identified in each assembly as an individual fasta file. Move all individual prophage fasta files to folder named fastas. Make sure multi.fasta is not in the fasta folder. If so, move it back to the top directory. Run all x all blast. Will produce output as a HitsTable and an all x all matrix. 
% awk '/^>/{OUT=substr($0,2) ".fasta"}; OUT {print > OUT}' multi.fasta
% mkdir fastas
% mv *.fasta fastas
% mv fastas/multi.fasta .
% blast.py --db db/db -o . fastas/*.fasta

All x All blast analysis is done, now you can see how genetically similar the prophages are in your genomes.

# Step 11: Cleaning Summary Files 
To concantenate all summary.txt into one usable table, first we need to clean the data. If you open a summary.txt file, lines 1 - 31 do not hold meaningful information to the output and can be deleted. To remove these lines, run remove_line.sh on the directory with all the summary.txt files (from Step 5). 
% sh remove_lines.sh path/to/summary_files

# Step 12: Adding column to each summary file based on assembly ID
If you open up a summary.txt file, you will see that there is no a column with the Assembly ID, therefore, when we concatenate all of the results together, it will be hard to disentagle the results from each other. We need to add a new column with the AssemblyID that has an entry for each row with a value. 
% sh add_filename_column.sh summary_files

# Step 13: Combining data into one easily readable excel file
Now that we have cleaned all of the summary.txt files and added assembly IDs to the outputs, we can combine all of the files.
% cat *.txt > concatenated_files.txt
Open up this file in your favorite text editor (BBEdit works great). Open up an excel file and copy all of the contents of the txt file into an excel file. When you copy the file, you should see an icon for "Import Wizard". Click that icon and you can easily change the delimiter of this data to "space deliminted". Now, you have all prophage summary data for each assemly you've run phastest on in one place and can further clean this data in excel. 
    
    
    

      









