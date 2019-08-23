# Description
A toolset created in Matlab to aid in empirical data collection of vapor-to-particle reactions for a chemistry lab at Colorado State University. The tool set consits of four main programs these being:
  * ColorSpec - Analysis the RGB values of an image or video in a given region. The user can specify to break the region into vertical or horizontal slices for further analysis.
  * LineSpec - Analyzes the color intesitys and light intensity of an image or video on a given line. 
  * CryAnalysis - Maps regions of a particle or material to show the underlying crystal structor through the use of a 2d fourier transform. If the region consists of only noise or no substantual phase cannot be found, the region is further broken up regions and analysised.    
  * TornadoPulse - Analyzes the changing volume and perimeter of a particle cloud. This allows the user to measure the volume of the vortex rings leaving the vapor-to-particle site as well as the frequency.

# ColorSpec
The region being analyzed.

![Region](https://github.com/ManVanMaan/Empirical-Data-Collection-Toolset/blob/master/Images/ColorSpec_RegionSelect.png)

A histogram of all colors found in the region.

![Histogram](https://github.com/ManVanMaan/Empirical-Data-Collection-Toolset/blob/master/Images/ColorSpec_Histogram.png)

Max RGB values found in each vertical slice of the region.

![Slices](https://github.com/ManVanMaan/Empirical-Data-Collection-Toolset/blob/master/Images/ColorSpec_CrossSections.png)

# LineSpec
The line being analyzed.

![Line](https://github.com/ManVanMaan/Empirical-Data-Collection-Toolset/blob/master/Images/SpecLine_Region.png)

The Data pulled from the line.

![Data](https://github.com/ManVanMaan/Empirical-Data-Collection-Toolset/blob/master/Images/LineSpec_Data.png)

# CryAnalysis
The material being analyzed.

![Material](https://github.com/ManVanMaan/Empirical-Data-Collection-Toolset/blob/master/Images/CryAnalysis_Material.png)

How the material was broken into regions.

![Regions](https://github.com/ManVanMaan/Empirical-Data-Collection-Toolset/blob/master/Images/CryAnalysis_Regions.png)

The found angles and magnitudes from all the regions.

![AngleAndMagnitude](https://github.com/ManVanMaan/Empirical-Data-Collection-Toolset/blob/master/Images/CryAnalysis_AngleAndMagnitude.png)

A heatmap of similar crystal structures.

![Heatmap](https://github.com/ManVanMaan/Empirical-Data-Collection-Toolset/blob/master/Images/CryAnalysis_Orientations.png)

# TornadoPulse
A frame from a video of a vapor-to-particle reaction.

![Sample](https://github.com/ManVanMaan/Empirical-Data-Collection-Toolset/blob/master/Images/TornadoPulse_Sample.png)

How the computer sees the same frame of the reactions.

![MachineVision](https://github.com/ManVanMaan/Empirical-Data-Collection-Toolset/blob/master/Images/TornadoPulse_MachineVision.png)



