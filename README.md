# VISUALISING-METEOROLOGICAL-CONDITIONS-ASSOCIATED-WITH-PM2.5-EXCEEDANCES-IN-SHEFFIELD

## Project Overview
This project investigates the meteorological conditions under which PM2.5 concentrations exceed the World Health Organization (WHO) 2021 health-based guideline in Sheffield. Using hourly air quality and meteorological data, a composite visualisation was developed to examine exceedance behaviour from relational, temporal, summary, and distributional perspectives, with a focus on wind speed and temperature as key dispersion-related factors.

## ❓ Research Question
Under what meteorological conditions (wind speed and temperature) do PM2.5 concentrations exceed the WHO 2021 health-based guideline in Sheffield?

## 📊 Key Findings
**Key Finding 1 (Figure 2 – Scatter with smoothing):**  
PM2.5 exceedances are strongly associated with low wind speed conditions, where atmospheric dispersion is limited. Higher concentrations are more frequently observed under cooler temperatures, indicating the role of stable atmospheric conditions in short-term pollution episodes.

**Key Finding 2 (Figure 3 – Daily time series):**  
PM2.5 exceedances occur episodically rather than persistently across the year. Most daily mean concentrations remain below the WHO guideline, suggesting that short-lived pollution events drive exceedance risk rather than sustained high background levels.

**Key Finding 3 (Figure 4 – Binned medians):**  
Median PM2.5 concentrations decline with increasing wind speed, confirming wind speed as a key structural meteorological factor influencing typical pollution levels and dispersion.

**Key Finding 4 (Figure 5 – Distributions):**  
Exceedances arise primarily from the upper tail of the PM2.5 distribution under low wind conditions. Even when median values remain below the guideline, extreme values can exceed health-based thresholds, highlighting the limitations of relying on averages alone.

## 📈 Composite Visualisation
The composite visualisation integrates four complementary charts:
1. PM2.5 vs wind speed with temperature encoded by colour
2. Daily mean PM2.5 time series with WHO guideline
3. Binned median PM2.5 across wind speed categories
4. Distribution of PM2.5 by wind speed category

Together, these views provide a nuanced understanding of exceedance risk that would not be apparent from any single visualisation.

## ⚙️ Repository Structure
```├── README.md  
├── dataset/  
│   ├── Openaq.csv              # Hourly PM2.5 data  
│   └── Openmeteo.csv           # Hourly meteorological data  
├── scripts/  
│   └── final_code(visualisation).R            # Code for Visualisation
├── figures/  
│   ├── figure1_scatter (Section2).png  
│   ├── figure2_timeseries (Section3).png  
│   ├── figure3_binned (Section4).png  
│   └── figure4_boxplot (Section5).png  
```

## 💻 Code
All analysis was conducted in R using RStudio. The main script (`final_code.R`) includes:
- Data cleaning and preprocessing  
- Hourly alignment of air quality and meteorological data  
- Threshold-based exceedance calculation  
- Construction of all figures used in the composite visualisation  

The code is fully commented and structured to support transparency and reproducibility.

## ▶️ How to Run the Code
**Requirements**
- R (version 4.0 or above recommended)
- RStudio (recommended)

**Steps**
1. Download or clone this repository.  
2. Ensure the following files are present in the `dataset/` folder:  
   - `Openaq.csv`  
   - `Openmeteo.csv`  
3. Open RStudio and set the working directory to the repository root (the folder containing `README.md`).  
4. Install required packages (first time only):

```r
install.packages(c("dplyr", "readr", "lubridate", "stringr", "ggplot2", "reshape2", "viridis"))
