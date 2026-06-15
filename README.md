PROJECT OVERVIEW
The setup_project.sh shell script bootstraps the Student Attendance Tracker
workspace. It builds the directory structure, generates the source files,
configures attendance thresholds, validates the environment, and cleans up
safely if the user cancels mid-run.


HOW TO RUN
Use the command:
./setup_project.sh
      OR
bash setup_project.sh

The script will then prompt you for: a project tag, whether you want to update the attendance thresholds and if you do it will allow you to change the values.


HOW TO RUN THE GENERATED APP
Use the command:
python3 attendance_checker.py
This reads Helpers/assets.csv, applies the thresholds in Helpers/config.json, and writes alerts to reports/reports.log.


HOW TO TRIGGER THE ARCHIVE FEATURE
While the script is running, press Ctrl+C


HOW TO READ THE ARCHIVE
The archive is a compressed binary file. Do not open it in a text editor, it will look like scrambled symbols. Use tar instead.
The two commands you can use are:
tar -tzf attendance_tracker_{tag}_archive.tar.gz   # list contents
tar -xzf attendance_tracker_{tag}_archive.tar.gz   # extract it back
