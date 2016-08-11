%% Reset MATLAB
close all
clear
clc

%% Enable dependencies
[githubDir,~,~] = fileparts(pwd);
d12packDir      = fullfile(githubDir,  'd12pack');
circadianDir	= fullfile(githubDir,'circadian');
addpath(d12packDir,circadianDir);

%% Map paths
timestamp = datestr(now,'yyyy-mm-dd_HHMM');
rootDir = '\\root\projects';
calPath = fullfile(rootDir,'DaysimeterAndDimesimeterReferenceFiles',...
            'recalibration2016','calibration_log.csv');
prjDir  = fullfile(rootDir,'GSA_Daysimeter','Vermont_VA_Hospital',...
            'Daysimeter_People_Data');
prjList = nodotdir(prjDir);
ssnName = {prjList.name};
ssnName = ssnName([prjList.isdir]);
ssnDir  = fullfile(prjDir,ssnName);
orgDir  = fullfile(ssnDir,'originalData');
dbName  = [timestamp,'.mat'];
dbPath  = fullfile(prjDir,dbName);
xlsName = [timestamp,'.xlsx'];
xlsPath = fullfile(prjDir,'tables',xlsName);

%% Crop and convert data
LocObj = d12pack.LocationData;
LocObj.State_Territory          = 'Vermont';
LocObj.PostalStateAbbreviation	= 'VT';
LocObj.Country                  = 'United States of America';
LocObj.Organization             = 'General Services Administration';

ii = 1;
for issn = 1:numel(ssnName)
    Session      = struct('Name',ssnName{issn});
    listingCDF   = dir(fullfile(orgDir{issn},'*.cdf'));
    cdfPaths     = fullfile(orgDir{issn},{listingCDF.name});
    loginfoPaths = regexprep(cdfPaths,'\.cdf','-LOG.txt');
    datalogPaths = regexprep(cdfPaths,'\.cdf','-DATA.txt');
    
    for iFile = 1:numel(loginfoPaths)
        cdfData = daysimeter12.readcdf(cdfPaths{iFile});
        ID = cdfData.GlobalAttributes.subjectID;
        
        thisObj = d12pack.HumanData;
        thisObj.CalibrationPath = calPath;
        thisObj.RatioMethod     = 'newest';
        thisObj.ID              = ID;
        thisObj.Location        = LocObj;
        thisObj.Session         = Session;
        thisObj.TimeZoneLaunch	= 'America/New_York';
        thisObj.TimeZoneDeploy	= 'America/New_York';
        
        % Import the original data
        thisObj.log_info = thisObj.readloginfo(loginfoPaths{iFile});
        thisObj.data_log = thisObj.readdatalog(datalogPaths{iFile});
        
        % Crop the data
        thisObj = crop(thisObj);
        
        objArray(ii,1) = thisObj;
        ii = ii + 1;
    end
end

%% Save converted data to file
save(dbPath,'objArray');

%% Save results to file
Analysis = objArray.analysis;
writetable(Analysis,xlsPath);

