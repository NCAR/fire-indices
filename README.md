# fire-indices
Code for calculating various fire indices for a research project about simultaneous large fires

**WARNING**

ERC and BI are currently being overhauled and currently contain several typos that range from negligible to very noticeable changes in results. This message will be removed as soon as the overhaul is complete

## Overview
Fire indices can show the current fire danger, the severity of drought in an area, and likelihood of spread. All the indices in this repository have been written in the NCAR Command Language (NCL). They use a variety of inputs. All of them use precipitation, many use temperature, while others also use solar radiation, wind speeds, and humidity. In combination, a variety of fire indices may be able to be used to pinpoint areas of extreme fire danger and severity, with focus on synchronous large wildfires across the contiguous United States. 

Unit handling is available for any temperature, relative humidity, precipitation, and wind variables. Solar radiation variables must be in W/m2 and specific humidity must be in kg/kg. Details regarding unit handling can be found in calc\_\<fire index\>.ncl files.

All main files (except SPI3) have built-in checks that ensure that the length of the time attribute in every file is the same, and that their start and end dates match within 24 hours.

## Running fire indexes
Each fire index can be run from the command line using the \<fire index\>\_main.ncl scripts. Their purpose is mostly to read in input variables and set up the output files. These scripts call the calc\_\<fire index\>.ncl functions. The main scripts include an example of how to run them in the comments at the top, as well as some explanation regarding inputs. For some variables, such as the grid variable used in FM100, FM1000, ERC, and BI there is further explanation within the calc_<fire_index>.ncl files. 

## SPI3
SPI3 is the 3 month standard precipitation index. The only input into SPI3 is monthly precipitation in any units.

3 month SPI is a relatively short time interval, and is indicative of soil moisture. It is quite simple and does not account for many variables present in other indices. 

The code uses a built in function for SPI in NCL, with the input set to 3. It does not have a corresponding calc\_\<fire index\>.ncl function. It can easily be modified to time scales other than 3 months. Generally, in order to be effective, a series of 30 to 50 years should be fed in, so as to get more accurate results. Typically, the scale ranges from -4 to 4, where -4 is abnormally low precipitation and 4 indicates abnormally high precipitation. Some regions may have less extreme scales. Technically, there is no limit to how wide the scale can be.

## KBDI
KBDI is the Keetch-Byram Drought Index. Its inputs are maximum daily temperature and daily precipitation. The final calculations for KBDI require temperature in Fahrenheit and precipitation in inches.

KBDI relies on the previous day's KBDI to formulate the current day's KBDI. It has a scale from 0 to 800, where 0 indicates saturated soil and 800 indicates severe drought. 800 is the limit because KBDI only deals with up to 8 inches of precipitation. The value of 800 indicates that it would take 8 inches of precipitation for soil to reach saturation. Since it does rely on the previous day, a spin-up period does exist up until the first major rainfall, usually at which point the scale resets to 0 and becomes independent from the initial value.

The code is based on calculations made in "A Drought Index for Fire Control" by John Keetch and George Byram in 1968. 

## mFFWI
mFFWI is the modified Fosberg Fire Weather Index. Its inputs are daily surface windspeed, daily maximum temperature, daily relative humidity, and KBDI.

The modified Fosberg index has a stronger correlation to area burned than the original Fosberg index. This is due to the inclusion of KBDI, and therefore precipitation, into the calculations. Technically, mFFWI starts at 0 and is an open ended scale, but usually exists between 0 and 100. mFFWI values above 50 suggest significant fire danger. Below 25 suggests little fire danger.

Each calculation is independent of the previous day. Additionally, the code expects KBDI as an input, so KBDI calculations should always be completed before running mFFWI.

## CFWI
CFWI is the Canadian Fire Weather Index. Its inputs are daily surface windspeed, daily maximum temperature, daily minimum relative humidity, and daily precipitation. Alternatively, daily average temperature and humidity could be used if maximum temperature and minimum humidity are not available.


An intermediate step of CFWI relies on the previous day's calculation, so the calculations are done in a loop. Like mFFWI, this index is of interest because it uses windspeed.

## FM100
FM100 is percent moisture content for 100-hour timelag, or 100 hour Fuel Moisture. It takes inputs of daily maximum and minimum temperature, daily precipitation, and daily minimum and maximum relative humidity. 

FM100 is part of the National Fire Danger Rating System, which categorizes dead fuel based on fuel diameter. Timelag can be defined as the approximate time it takes for the fuel to reach 2/3 of the way to equilibrium with the environment. 100-hour timelag fuel is roundwood that is 1 to 3 inches in diameter and describes the layer of dead fuel on the forest floor approximately 3/4 of an inch to four inches below the surface. FM100 uses a 24-hour boundary condition. 

Typically, FM100 ranges between 0 and 30, where 30 is low fire danger and 0 is high fire danger. Note that this scale is inverse to most other fire indices, where the maximum value denotes high fire danger.

Currently, it only serves as an input to ERC, but may be used as a separate index. Also note that in the NFDRS equations from 1985 that FM100 is referred to as MC100 (moisture content instead of fuel moisture).

## FM1000
FM1000 is percent moisture content for 1000-hour timelag, or 1000 hour Fuel Moisture. It takes inputs of daily maximum and minimum temperature, daily precipitation, and daily minimum and maximum relative humidity (the same as FM100).

FM1000, like FM100, is part of the National Fire Danger Rating System, which categorizes dead fuel based on fuel diameter. Timelag can be defined as the approximate time it takes for the fuel to reach 2/3 of the way to equilibrium with the environment.  1000-hour timelag fuel is roundwood that is 3 to 8 inches in diameter and describes the layer of dead fuel on the forest floor deeper than four inches below the surface. FM1000 uses a 7-day average boundary condition.

FM1000 ranges from 0 to 45, though in most of the US, it rarely reaches above 35. Like FM100, 0 is high fire danger and 45 is low fire danger. 
It serves as an input to ERC, but may be used as a separate index. Also like FM100, in the NFDRS 1985 equations paper, FM1000 is referred to as MC1000.

## ERC 
ERC is the Energy Release Component. Its inputs are daily maximum and minimum temperature, daily precipitation, daily minimum and maximum relative humidity, daily downwelling shortwave radiation in W/m^2, daily specific humidity in kg/kg, 100 hour fuel moisture, and 1000 hour fuel moisture.

ERC is a component in the National Fire Danger Rating System relating the available energy in BTU per unit area in square feet within the flaming front at the head of a fire. It includes fuel moisture values from all dead and live fuels that can contribute to potential fire intensity. It is a cumulative index. When the ERC value doubles, the potential heat release has doubled.

There are many options surrounding the fuel model portion of the code. The NFDRS fuel models are letters A-L, N-U. An overview of their distributions in the US and descriptive names for each can be seen here: https://www.wfas.net/index.php/nfdrs-fuel-model-static-maps-44

Work surrounding adapting the map to calculated ERC across large areas of the United States is currently in progress. Limited functionality has been built into the current code that can use the fuel model map, with the option to use custom files for different grids and locations.

Like CFWI, several intermediate steps rely on the previous day's calculations. This index is by far the most computationally complex and the most time consuming to run. Previous work suggests that it is very accurate, however. ERC calculated using fuel model G (which is frequently used) typically ranges from 0 to 80, where 0 is low fire danger and 80 is severe fire danger. Drier, hotter regions may get higher than 80, though, as it is an open ended scale.

The code is almost exclusively adapted from code from John Abatzoglou. 

## BI
BI is Burning Index. Its inputs are daily maximum and minimum temperature, daily precipitation, daily minimum and maximum relative humidity, daily windspeed, daily downwelling shortwave radiation in W/m^2, daily specific humidity in kg/kg, 100 hour fuel moisture, 1000 hour fuel moisture, and energy release component.

BI is an index in the National Fire Danger Rating System and describes the difficulty to control a fire. The higher the value of BI, the longer the flame length and the harder a fire is to contain. It is a combination of energy release component (ERC) and spread component (SC). This means it accounts for how much energy will be produced and for how fast it can spread. 

The scale for burning index depends on which fuel model is used. 0 is low fire danger, and large values are higher fire danger, with values in the 60-80 range or higher suggesting containment will be difficult. It is of interest partially because it takes into account the same variables as ERC, but also includes wind, which is of great interest in wildfire spread. 

Like ERC, there are options for the fuel model inputs. It is closely related to ERC in many ways.

## SUPPORT
This repository is supported by NSF Growing Convergence Project 2019762.
