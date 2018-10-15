# fire-indices
Code for calculating various fire indices for a research project about simultaneous large fires

## Overview
Fire indices can show the current fire danger, the severity of drought in an area, and likelihood of spread. All the indices in this repository have been written in the NCAR Command Language (NCL). They use a variety of inputs. All of them use precipitation, many use temperature, while others also use solar radiation, wind speeds, and humidity. In combination, a variety of fire indices may be able to be used to pinpoint areas of extreme fire danger and severity, with focus on synchronous large wildfires across the contiguous United States. 

Please note that all units mentioned are the ones that the files are currently set up to use, but will most likely be modified to be more consistent. All temperature inputs can be input as Kelvin, Celsius, or Fahrenheit.

## SPI3
SPI3 is the 3 month standard precipitation index. The only input into SPI3 is monthly precipitation in any units.

3 month SPI is a relatively short time interval, and is indicative of soil moisture. It is quite simple and does not account for many variables present in other indices. 

The code uses a built in function for SPI in NCL, with the input set to 3. It can easily be modified to time scales other than 3 months. Generally, in order to be effective, a series of 30 to 50 years should be fed in, so as to get more accurate results. Typically, the scale ranges from -4 to 4, where -4 is abnormally low precipitation and 4 indicates abnormally high precipitation. Some regions may have less extreme scales. Technically, there is no limit to how wide the scale can be.

## KBDI
KBDI is the Keetch-Byram Drought Index. Its inputs are maximum daily temperature and daily precipitation. In its current form it expects mm for precipitation. The actual calculations require precipitation in inches, but there is a conversion built in to the function.

KBDI relies on the previous day's KBDI to formulate the current day's KBDI. It has a scale from 0 to 800, where 0 indicates saturated soil and 800 indicates severe drought. Since it does rely on the previous day, a spin-up period does exist up until the first major rainfall, usually at which point the scale resets to 0 and becomes independent from the initial value.

The code is based on calculations made in "A Drought Index for Fire Control" by John Keetch and George Byram in 1968. 

## mFFWI
mFFWI is the modified Fosberg Fire Weather Index. Its inputs are daily surface windspeed in m/s, daily maximum temperature, daily relative humidity (0 - 100 scale), and KBDI. The final calculations require windspeed in mph, but a conversion is built in to the function.

The modified Fosberg index has a stronger correlation to area burned than the original Fosberg index. This is due to the inclusion of KBDI, and therefore precipitation, into the calculations. Technically, mFFWI starts at 0 and is an open ended scale, but usually exists between 0 and 100. mFFWI values above 50 suggest significant fire danger. Below 25 suggests little fire danger.

Each calculation is independent of the previous day. Additionally, the code expects KBDI as an input, so KBDI calculations should always be completed before running mFFWI.

## CFWI
CFWI is the Canadian Fire Weather Index. Its inputs are daily surface windspeed in m/s, daily maximum temperature, daily relative humidity (0 to 100 scale), and daily precipitation in mm. Some datasets do not have average daily humidity, in which case use the inputs of daily max and min humidities, averaged together. The current code is currently set up to take in the two and average them.

CFWI usually operates in a smaller range than other fire indices. Typically, 0-5 is considered low fire danger, 5-10 is moderate, 10-20 is high, 20-30 is very high, and anything greater than 30 is considered extreme.

An intermediate step of CFWI relies on the previous day's calculation, so the calculations are done in a loop. Like MFFWI, this index is of interest because it uses windspeed.

## FM100
FM100 is percent moisture content for 100-hour timelag, or 100 hour Fuel Moisture. It takes inputs of daily maximum and minimum temperature in degrees Celsius, daily precipitation in mm, and daily minimum and maximum relative humidity. Final calculations use precipitation in inches but a conversion is built in to the code.

Typically, FM100 ranges between 0 and 30, where 30 is low fire danger and 0 is high fire danger. Note that this scale is inverse to most other fire indices, where the maximum value denotes high fire danger.

Currently, it only serves as an input to ERC, but may be used as a separate index. Also note that in the NFDRS equations from 1985 that FM100 is referred to as MC100 (moisture content instead of fuel moisture).

## FM1000
FM1000 is percent moisture content for 1000-hour timelag, or 1000 hour Fuel Moisture. It takes inputs of daily maximum and minimum temperature, daily precipitation in mm, and daily minimum and maximum relative humidity (the same as FM100).

FM1000 ranges from 0 to 45, though in most of the US, it rarely reaches above 35. Like FM100, 0 is high fire danger and 45 is low fire danger. 

Currently, it only serves as an input to ERC, but may be used as a separate index. Also like FM100, in the NFDRS 1985 equations paper, FM1000 is referred to as MC1000.

## ERC 
ERC is the Energy Release Component. Its inputs are daily maximum and minimum temperature in degrees Celsius, daily precipitation in mm, daily minimum and maximum relative humidity (0-100 scale), daily downwelling shortwave radiation in W/m^2, daily specific humidity in kg/kg, 100 hour fuel moisture, and 1000 hour fuel moisture. 

Like CFWI, several intermediate steps rely on the previous day's calculations. This index is by far the most computationally complex and the most time consuming to run. Previous work suggests that it is very accurate, however. ERC typically ranges from 0 to 80, where 0 is low fire danger and 80 is severe fire danger. Drier, hotter regions may get higher than 80, though, as it is an open ended scale.

The code is almost exclusively adapted from code from John Abatzoglou. 
