#!/bin/bash

#make directory HigherElevation or tell user if it already exists
dir=HigherElevation
if [ -d $dir ]
then 
	echo "Directory HigherElevation exists"
else
	mkdir $dir
fi

#identify stations at altitudes equal to or greater than 200 feet
for file in StationData/*
do
#use grep to seek out altitude values
altitude=$(grep -oP '(?<=Altitude: )[0-9]+\.[0-9]+' $file)
	if (( $(echo "$altitude >= 200" |bc -l) )) 
	then cp $file $dir
	fi
done	

#extract latitude and longitude for each file in the StationData folder
#multiply longitude by -1 because it is west of the prime meridian
awk '/Longitude/ {print -1 * $NF}' StationData/Station_*.txt > Long.list
#latitude remains positive because it is above the equator
awk '/Latitude/ {print $NF}' StationData/Station_*.txt > Lat.list

#create xy coordinate pairings using paste
paste Long.list Lat.list > AllStation.xy

#do the same steps with the HigherElevation Stations
awk '/Longitude/ {print -1 * $NF}' HigherElevation/Station_*.txt > Long.list
awk '/Latitude/ {print $NF}' HigherElevation/Station_*.txt > Lat.list
paste Long.list Lat.list > HEStation.xy

#load gmt package
module load gmt

#generate plot
#draw blue lakes, rivers, coastlines, and political boundaries
gmt pscoast -JU16/4i -R-93/-86/36/43 -B2f0.5 -Cl/blue -Dh[+] -Ia/blue -Na/orange -P -K -V > SoilMoistureStations.ps
#add small black circles for all station locations
gmt psxy AllStation.xy -J -R -Sc0.15 -Gblack -K -O -V >> SoilMoistureStations.ps
#adds red circles for all higher elevation stations smaller than ALLStation
gmt psxy HEStation.xy -J -R -Sc0.08 -Gred -O -V >> SoilMoistureStations.ps

#display SoilMoistureStations.ps
gv SoilMoistureStations.ps &

#convert SoilMoistureStations.ps to epsi file
ps2epsi SoilMoistureStations.ps

#display SoilMoistureStations.epse
gv SoilMoistureStations.epsi &

#convert .epsi to .tiff at the resolution 150 dpi
convert SoilMoistureStations.epsi -density 150 -units pixelsperinch SoilMoistureStations.tiff

#display SoilMoistureStations.tiff
display SoilMoistureStations.tiff
