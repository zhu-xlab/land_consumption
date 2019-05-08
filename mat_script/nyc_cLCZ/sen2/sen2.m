restoredefaultpath
addpath(genpath('/data/hu/SDG'));

%% directory setting
se1dir = '/data/hu/SDG/data/NYC/SE1/mosaic.tif';
se2dir = '/data/hu/SDG/data/NYC/SE2/23083_summer.tif';
labdir = '/data/hu/SDG/data/NYC/GT/newyork_cLCZ.tif';
patchSize = 0;

%% feature extraction
% [ se2Feat ] = sen2FeatExtract( se2dir );
load('/data/hu/SDG/data/NYC/tmpData/sen2Feature.mat')
SE2tmp = reshape(se2Feat,size(se2Feat,1)*size(se2Feat,2),size(se2Feat,3));


%% load training and testing label
[ labCoord, lab ] = getShareCoordinate( labdir,se1dir,se2dir,patchSize );
labIdx = sub2ind(size(se2Feat(:,:,1)),labCoord(:,5),labCoord(:,6));
observ = SE2tmp(labIdx,:);
observ = zscore(observ);

%% parameters for training and testing separation
trainPerc = 0.1;
[ trainIdx,testIdx ] = nFoldsDataSampleBlockEqual( lab,trainPerc );
nfolds = size(trainIdx,2);


%% set the percentage of training samples
trainPercArray = [...
    ones(1,1),zeros(1,9);...% 10%
    ones(1,5),zeros(1,5);...% 50%
    ones(1,9),zeros(1,1)... % 90%
    ]==1;

for cv_trPerc = 1:size(trainPercArray,1)
    trainPerc = trainPercArray(cv_trPerc,:);

    
    %% n folds classification with random forest
    M = cell(nfolds,1);
    oa = zeros(nfolds,1);
    kappa = zeros(nfolds,1);
    Mdl_rf = cell(nfolds,1);
    NumTrees = 8100;


    % loop for n folds
    for cv_fold = 1:nfolds
        %% get the data
        trainPercTmp = circshift(trainPerc,cv_fold-1);
        trIndex = sum(trainIdx(:,trainPercTmp),2)>0;

        trLab = lab(trIndex);
        teLab = lab(~trIndex);

        trainSE2 = observ( trIndex,:);
        testSE2  = observ(~trIndex,:); 

        
        % training
        rng(1); % For reproducibility
        Mdl_rf{cv_fold} = TreeBagger(NumTrees,trainSE2,trLab,'OOBPredictorImportance','on');
        % testing
        [predLab,scores] = predict(Mdl_rf{cv_fold},testSE2);
        predLab = cellfun(@str2double,predLab);
        [ M{cv_fold},oa(cv_fold),pa,ua,kappa(cv_fold) ] = confusionMatrix(double(teLab),predLab);
        oa
    end

    save(['sen2_xv_trp_',num2str(sum(trainPerc*10))],'oa','M','kappa','Mdl_rf','trainIdx','testIdx','labCoord','lab','observ','-v7.3') 

end
