# MATLAB
SOLAR CELL IV ANALYSIS TOOL
============================

Author: Bader ALJEBAEI (HIAST 2025)

This MATLAB GUI is designed to:
- Import IV data from a .txt file
- Fit it using a full diode model
- Compute solar cell parameters and efficiency
- Export results and plots

REQUIREMENTS:
-------------
- MATLAB R2018 or later
- Optimization Toolbox
- Image Processing Toolbox (for background image)

SETUP INSTRUCTIONS:
-------------------
1. Make sure your IV data file is formatted as:
   Voltage (V) ; Current (A)
   (semicolon-separated)
  use the attached file "DD" for checking 

2. Place the background image ( 2.png) instead of:
   C:\Users\ASUS\OneDrive\Desktop\5th\matlab\2.png
   Or edit the `imread(...)` path inside `solar_gui.m`

3. Run the program in MATLAB by typing:
   >> solar_gui

4. In the GUI:
   - Click "Browse" to load your IV data file
   - Enter cell dimensions (width and length in cm)
   - Click "Run Analysis"

5. After processing:
   - A new window will display the fitted IV curve and parameters
   - You will be prompted to save:
     - A TXT file with parameters and data
     - A PNG image of the IV curve

OUTPUT:
-------
- IV_Curve.png → the plotted IV curve
- <YourFilename>.txt → results including:
  - Diode parameters: Iph, I0, Rs, n, Rsh
  - Performance: Voc, Isc, FF, Efficiency
  - Fitting quality: R², RMSE, MAE

Enjoy!
