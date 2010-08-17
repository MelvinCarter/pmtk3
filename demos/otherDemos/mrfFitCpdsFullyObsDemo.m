%% Fit the local CPDs of an mrf given an image / noisy image pair
%
%%
cmap = 'bone';
imgs = loadData('tinyImages'); 
img = double(imgs.matlabIconGray);
[M, N] = size(img); 
ns = 32; 
img = reshape(quantizePMTK(img(:), 'levels', ns), M, N);
img = canonizeLabels(img); 
nstates = max(img(:)); 
figure;
imagesc(img); 
colormap(cmap); 
title('original image');
localCPD  = condGaussCpdCreate( nstates*ones(1, nstates), ones(1, 1, nstates)); 

sigma = 0.1; 
yTrain = img./nstates + sigma*randn(M, N);
yTest  = img./nstates + sigma*randn(M, N);
figure; imagesc(yTrain);
colormap(cmap); 
title('noisy copy (yTrain)');
figure; imagesc(yTest); 
colormap(cmap); 
title('noisy copy (yTest)');
localCPD = localCPD.fitFn(localCPD, img(:), yTrain(:));

edgePot = exp(bsxfun(@(a, b)-abs(a-b), 1:nstates, (1:nstates)')); % will be replicated

figure; imagesc(edgePot); colormap('default'); title('tied edge potential');
nodePot = normalize(rand(1, nstates));
G         = mkGrid(M, N);
infEngine = 'libdai';
opts = {'TRWBP', '[updates=SEQFIX,tol=1e-9,maxiter=10000,logdomain=0,nrtrees=0]'};

mrf     = mrfCreate(G, 'nodePots', nodePot, 'edgePots', edgePot,...
    'localCPDs', localCPD, 'infEngine', infEngine, 'infEngArgs', opts);

nodes = mrfInferNodes(mrf, 'localev', rowvec(yTest)); 
maxMarginals = maxidx(tfMarg2Mat(nodes), [], 1);
figure; imagesc(reshape(maxMarginals, M, N)); colormap(cmap); 
title('reconstructed image'); 
placeFigures;
