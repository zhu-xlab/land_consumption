function [flag] = SDG_Output(cityPath,enviPath)
% This function implements the ensemble mima for the land cover land use
% classification.
%   Input:
%       - cityPath      -   a directory to a folder, where has three
%                           subfolders: SE1, SE2, and GT, which contain a
%                           geotiff file of Sentinel-1, Sentinel-2, and
%                           ground truth, respectively.
%       - enviPath      -   a path to a firectory, where lib are stored.
%                           '/<directory to git local repo>/mat_script'
%
%   Output:
%       - flag          -   '0' failed
%                           '1' successed: results are saved in the ouput
%                           directory;

%% setting the environmental path
addpath(genpath(enviPath));
flag = 0;
%% ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% directory setting
disp('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
disp('+++++++++++++++++++++ Setting Directories ++++++++++++++++++++++++++');

% directory to the population data
popDir = [cityPath,'/POP/*POP_22km.tif'];
fileName = dir(popDir);
if isempty(fileName)
    disp('The Population GEOTIFF data does not exist!');
    return
elseif length(fileName)~=1
    disp('More than one population GEOTIFF data exist');
    return
else
    popDir = [fileName.folder,'/',fileName.name];
    disp(['The directory to population data: ',popDir]);
end

% directory to the output files
outputDir = [cityPath,'/OUTPUT'];
disp(['The output directory was set to: ',outputDir]);


% temporary data file
datTmpDir = [outputDir,'/datTmp.mat'];
disp(['The temporary data file was set to: ',datTmpDir]);

% clcz geotiff file
clamapTifDir = [outputDir,'/claMap_cLCZ_22km.tif'];
disp(['The temporary data file was set to: ',clamapTifDir]);

disp('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
disp('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

load(datTmpDir,'OKclaMap')
if ~exist('OKclaMap','var')
    disp('classification map is not ready yet!')
    return
end

if ~exist(clamapTifDir,'file')
    disp('the classification map tiff file not found!')
    return
end
%% get the city code
cityCode = strsplit(cityPath,'/');
cityCode = cityCode{end};
disp(['~~~ working on the city: ',cityCode,' ~~~'])
disp([outputDir,'/SDG_STAT.mat'])

%{

%% calculate open public space, and saving
disp('Calculating SDG: open public space ...')
% [opsDistriFeat, opsShare, popTotal, ops, meanDist2OPS, opsLandPerc, opsPopPerc] = openPubSpaceDistribution(clamapTifDir,popDir);

disp('Saving open public space SDG ...')
[~,ref] = geotiffread(clamapTifDir);
info = geotiffinfo(clamapTifDir);
geotiffwrite([outputDir,'/ops.tif'], ops, ref, 'GeoKeyDirectoryTag', info.GeoTIFFTags.GeoKeyDirectoryTag);
geotiffwrite([outputDir,'/meanDist2OPS.tif'], meanDist2OPS, ref, 'GeoKeyDirectoryTag', info.GeoTIFFTags.GeoKeyDirectoryTag);
save([outputDir,'/SDG_STAT.mat'], 'opsDistriFeat', 'opsShare', 'popTotal', 'opsLandPerc', 'opsPopPerc', 'cityCode','-append');
%}

%% calculate land comsumption, and saving
disp('Calculating SDG: land comsuption ...')
[landStat] = landComsuptionAndPop(clamapTifDir,popDir);
popTotal = geotiffread(popDir);
popTotal = sum(popTotal(:));
if isfile([outputDir,'/SDG_STAT.mat'])
    save([outputDir,'/SDG_STAT.mat'], 'landStat','cityCode','popTotal','-append');
else
    save([outputDir,'/SDG_STAT.mat'], 'landStat','cityCode','popTotal');
end

%{
%% calcuate the correlation between clcz and population
% disp('Calculating the correlation of city morphology and population distribution ...')
% [spatilCorrelation] = lczPopCorr(clamapTifDir,popDir)
% geotiffwrite([outputDir,'/spatilCorrelation.tif'],spatilCorrelation,ref, 'GeoKeyDirectoryTag', info.GeoTIFFTags.GeoKeyDirectoryTag);

%}

end
