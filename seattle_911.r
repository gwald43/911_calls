# ----------------------------------------------
# David Phillips
#
# 5/17/2018
# Descriptive analysis of 911 calls in the Seattle area
# Source: https://data.seattle.gov/Public-Safety/Seattle-Police-Department-911-Incident-Response/3k2p-39jp
# The working directory should be the same as the downloaded data
# ----------------------------------------------


# --------------------
# Set up R
rm(list=ls())
library(tools)
library(data.table)
library(reshape2)
library(stringr)
library(RColorBrewer)
library(ggplot2)
library(gridExtra)
# --------------------


# ---------------------------------------------------------------
# Files and directories

# input file
inFileSea = './Seattle_Police_Department_911_Incident_Response.csv'
inFileBal = './911_Police_Calls_for_Service.csv'
inFileLA = './LAPD_Calls_for_Service_2017.csv'
inFileDet = './DPD__911_Calls_for_Service__September_20__2016_-_Present.csv'

# output files
graphFile = './descriptive_analysis.pdf'
# ---------------------------------------------------------------


# ---------------------------------------------------------------
# Load/prep data

# load all files
dataSea = fread(inFileSea)
dataBal = fread(inFileBal) # doesn't have event classifications
dataLA = fread(inFileLA) # doesn't have event classifications
dataDet = fread(inFileDet)  # doesn't have event classifications

# rename
setnames(dataSea, c('record_id', 'event_number', 'general_offense_number',
				'clearance_code', 'clearance_description', 'clearance_subgroup',
				'clearance_group', 'call_date_time', 'address', 'district',
				'zone', 'census_tract', 'longitude', 'latitude', 'location',
				'initial_type_description', 'initial_type_subgroup',
				'initial_type_group', 'at_scene_time'))
# setnames(dataBal, c('record_id', 'call_date_time', 'priority', 'district',
# 				'initial_type_description', 'event_number', 'address', 'location'))

# append


# missing values
data[Initial_Type_Group=='', Initial_Type_Group:='NOT RECORDED']

# date formats
data[, c('date_str', 'time_str', 'AMPM'):=tstrsplit(At_Scene_Time, ' ', fixed=TRUE)]
data[is.na(date_str), c('date_str', 'time_str', 'AMPM'):=tstrsplit(Event_Clearance_Date, ' ', fixed=TRUE)]
data[, call_date:=as.Date(date_str, '%m/%d/%Y')]
data[, call_month:=month(call_date)]
data[, call_year:=year(call_date)]
data[, call_my:=as.Date(paste('01',call_month,call_year), '%d %m %Y')]

# categorize according to whether initial classification is immediately threatening
clear_danger = c('CRISIS CALL' ,'CASUALTIES', 'ASSAULTS', 'PERSONS - LOST, FOUND, MISSING',
					'THREATS, HARASSMENT', 'GUN CALLS', 'HAZARDS', 'WEAPONS CALLS',
					'SEX OFFENSE (NO RAPE)', 'PERSON DOWN/INJURY', 'MENTAL CALL')
possible_danger = c('TRESPASS', 'RESIDENTIAL BURGLARIES', 'ANIMAL COMPLAINTS', 'ROBBERY',
					'RECKLESS BURNING', 'ROAD RAGE')

data[Initial_Type_Group %in% clear_danger, Initial_Type_Danger:='Clear Danger']
data[Initial_Type_Group %in% possible_danger, Initial_Type_Danger:='Possible Danger']
data[!(Initial_Type_Group %in% clear_danger) & !(Initial_Type_Group %in% possible_danger),
					Initial_Type_Danger:='No Immediate Danger']
data[, Initial_Type_Danger:=factor(Initial_Type_Danger,
		levels=c('Clear Danger',  'Possible Danger', 'No Immediate Danger'), ordered=TRUE)]

# convert to title case (warning: slow)
# data[, Initial_Type_Group:=toTitleCase(Initial_Type_Group)]
# ---------------------------------------------------------------


# ------------------------------------------------------------------------------------------
# Descriptive Graphs

# 911 cals by initial group
tmpAgg = data[, .N, by=c('Initial_Type_Danger', 'Initial_Type_Group')]
p1 = ggplot(tmpAgg, aes(y=N, x=reorder(Initial_Type_Group, -N), fill=Initial_Type_Danger)) +
	geom_bar(stat='identity') +
	labs(title='Initial 911 Call Category', y='Frequency', x='') +
	scale_fill_manual('', values=brewer.pal(3, 'Set1')) +
	theme_bw() +
	theme(axis.text.x=element_text(angle=315, hjust=0), plot.title=element_text(hjust=.5))

# 911 calls by day
tmpAgg = data[, .N, by='call_date']
p2 = ggplot(tmpAgg, aes(y=N, x=call_date)) +
	geom_line() +
	labs(title='911 Calls per Day', y='Frequency', x='') +
	theme_bw() +
	theme(axis.text.x=element_text(angle=315, hjust=0), plot.title=element_text(hjust=.5))

# 911 calls by month
tmpAgg = data[, .N, by='call_my']
p3 = ggplot(tmpAgg, aes(y=N, x=call_my)) +
	geom_line() +
	labs(title='911 Calls per Month', y='Frequency', x='') +
	theme_bw() +
	theme(axis.text.x=element_text(angle=315, hjust=0), plot.title=element_text(hjust=.5))

# 911 calls by initial group over time
tmpAgg = data[, .N, by=c('call_my', 'Initial_Type_Danger')]
p4 = ggplot(tmpAgg, aes(y=N, x=call_my, color=Initial_Type_Danger)) +
	geom_line() +
	labs(title='911 Calls per Month', y='Frequency', x='') +
	scale_color_manual('', values=brewer.pal(3, 'Set1')) +
	theme_bw() +
	theme(axis.text.x=element_text(angle=315, hjust=0), plot.title=element_text(hjust=.5))
tmpAgg[, pct:=N/sum(N), by='call_my']
p5 = ggplot(tmpAgg, aes(y=pct*100, x=call_my, fill=Initial_Type_Danger)) +
	geom_bar(stat='identity', position='stack') +
	labs(title='911 Calls per Month', y='Percentage', x='') +
	scale_fill_manual('', values=brewer.pal(3, 'Set1')) +
	theme_bw() +
	theme(axis.text.x=element_text(angle=315, hjust=0), plot.title=element_text(hjust=.5))

# 911 calls by location

# 911 calls by location and initial group

# comparison of initial group to event clearance group

# time between call time and at-scene time

# time between call time and at-scene time by initial group

# ------------------------------------------------------------------------------------------


# ---------------------------------
# Run analysis

# ---------------------------------


# ----------------------------------------------
# Analysis Graphs

# ----------------------------------------------


# --------------------------------
# Save graphs
pdf(graphFile, height=6, width=9)
p1
grid.arrange(p2, p3)
grid.arrange(p4, p5)
dev.off()
# --------------------------------
