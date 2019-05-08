addpath(genpath('/data/hu/SDG'));

%% load data
load('/data/hu/SDG/munich_cLCZ_perc/con/con_xv.mat', 'trainIdx', 'testIdx', 'observ', 'nbFeatSE1', 'lab')
observ = double(observ);

nFolds = 1;

%% get the data
trLab = lab(trainIdx(:,nFolds));
teLab = lab( testIdx(:,nFolds));

trainSE1 = observ(trainIdx(:,nFolds),1:nbFeatSE1);
testSE1  = observ( testIdx(:,nFolds),1:nbFeatSE1);

trainSE2 = observ(trainIdx(:,nFolds),nbFeatSE1+1:size(observ,2));
testSE2  = observ( testIdx(:,nFolds),nbFeatSE1+1:size(observ,2));

se1Data = cat(1,trainSE1,testSE1);
se2Data = cat(1,trainSE2,testSE2);

% SE1 magnitude difference --- dB
se1Data(:,[1:21,29:31,33:35]) = log10(se1Data(:,[1:21,29:31,33:35]));
% se1Data(:,[1:14,22:30,33:34,36]) = log10(se1Data(:,[1:21,22:30,33:34,36]));

se1Data = zscore(se1Data);

% se2Data = zscore(se2Data);


%% mima graph 
data = se1Data;

param.nbBin = 40;
param.ovLap = .5;
param.itvFlag = 1;
param.clutMeth = 'sc';
[Tpca,~,~,~,~,~]=pca(data);
se1fil = data*Tpca(:,1);
[ G, Wv, clusterCen ] = EnMIMA_MAPPER( data,se1fil,param );

G_sup = repmat(trLab,1,length(trLab))==repmat(trLab',length(trLab'),1);
G_sup = double(G_sup);
% figure,imagesc(G)
G(1:length(trLab),1:length(trLab)) = G_sup;
% figure,imagesc(G)

% #########################################################################
% Construct diagonal weight matrix
D = diag(sum(G, 2));
% Compute Laplacian
L = D - G;
L(isnan(L)) = 0; D(isnan(D)) = 0;
L(isinf(L)) = 0; D(isinf(D)) = 0;
% Compute XDX and XLX and make sure these are symmetric
disp('Computing low-dimensional embedding...');
DP = data' * D * data;
LP = data' * L * data;
DP = (DP + DP') / 2;
LP = (LP + LP') / 2;

options.disp = 0;
options.issym = 1;
options.isreal = 1;
[eigvector, eigvalue] = eigs(LP, DP, size(data,2), 'sa', options);

% Sort eigenvalues in descending order and get smallest eigenvectors
[eigvalue, ind] = sort(diag(eigvalue), 'ascend');
eigvector = eigvector(:,ind(1:size(data,2)));

% Compute final linear basis and map data
mappedX = data * eigvector;  
% #########################################################################

trainFeat = mappedX(1:size(trainSE1,1),:);
testFeat = mappedX(size(trainSE1,1)+1:end,:); 

NumTrees = 100;
rng(1); % For reproducibility
Mdl_rf = TreeBagger(NumTrees,trainFeat,trLab,'OOBPredictorImportance','on');
% testing
[predLab,scoresSE1] = predict(Mdl_rf,testFeat);
predLab = cellfun(@str2double,predLab);
[ M,oa_mima,pa,ua,ka ] = confusionMatrix(double(teLab),predLab);
oa_mima



%% LPP graph 
k = 12;
data = se2Data;
pd = squareform(pdist(data));
tmp = sort(pd);
tmp = tmp(k+1,:);
tmp = repmat(tmp,size(pd,1),1);
G = pd<tmp;
G = (G+G')>0; clear tmp pd

G_sup = repmat(trLab,1,length(trLab))==repmat(trLab',length(trLab'),1);
G_sup = double(G_sup);

G(1:length(trLab),1:length(trLab)) = G_sup;


% #########################################################################
% Construct diagonal weight matrix
D = diag(sum(G, 2));
% Compute Laplacian
L = D - G;
L(isnan(L)) = 0; D(isnan(D)) = 0;
L(isinf(L)) = 0; D(isinf(D)) = 0;
% Compute XDX and XLX and make sure these are symmetric
disp('Computing low-dimensional embedding...');
DP = data' * D * data;
LP = data' * L * data;
DP = (DP + DP') / 2;
LP = (LP + LP') / 2;

options.disp = 0;
options.issym = 1;
options.isreal = 1;
[eigvector, eigvalue] = eigs(LP, DP, size(data,2), 'sa', options);

% Sort eigenvalues in descending order and get smallest eigenvectors
[eigvalue, ind] = sort(diag(eigvalue), 'ascend');
eigvector = eigvector(:,ind(1:size(data,2)));

% Compute final linear basis and map data
mappedX = data * eigvector;  
% #########################################################################

trainFeat = mappedX(1:size(trainSE1,1),:);
testFeat = mappedX(size(trainSE1,1)+1:end,:); 

NumTrees = 100;
rng(1); % For reproducibility
Mdl_rf = TreeBagger(NumTrees,trainFeat,trLab,'OOBPredictorImportance','on');
% testing
[predLab,scoresSE1] = predict(Mdl_rf,testFeat);
predLab = cellfun(@str2double,predLab);
[ M,oa_lpp,pa,ua,ka ] = confusionMatrix(double(teLab),predLab);
oa_lpp


