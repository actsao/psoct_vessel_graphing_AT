%% Main file for calling segmentation functions
% Author: Mack Hyman
% Date Created: March 16, 2023
%
% Detailed Description
%{
This script performs the following:
- segmentation ()
- convert segmentation to graph ()
- prune graph (remove loops and unterminated segments)
    - remove loops ()
    - remove segments ()
- overlay graph and image
- diameter
- tortuosity (vessel_tortuosity_index.m)
- length
- topology (why does this use the mask?)
%}
clear; clc; close all;

%% Add top-level directory of code repository to path
% This allows Matlab to find the functions in the project folders
% Print current working directory
mydir  = pwd;
% Find indices of slashes separating directories
if ispc
    idcs = strfind(mydir,'\');
elseif isunix
    idcs = strfind(mydir,'/');
end
% Remove the two sub folders to reach top-level directory
% (psoct_vessel_graphing)
topdir = mydir(1:idcs(end));
addpath(genpath(topdir));

%% Imaging parameters
% voxel dimensions
vox_dim = [30, 30, 30]; % microns

%% Import volume (.TIF or .BTF) & convert to MAT (windows PC)
%{
dpath = 'C:\Users\mack\Documents\BU\Boas_Lab\psoct_human_brain_resources\test_data\Hui_Frangi_dataset\200218depthnorm\';
fname = 'volume_ori_inv_cropped';
% filename extension
ext = '.tif';
filename = strcat(dpath, strcat(fname,ext));
% Convert .tif to .MAT
vol = TIFF2MAT(filename);
%}

%% Import volume (.TIF or .BTF) & convert to MAT (SCC)
dpath = '/projectnb/npbssmic/ns/Ann_Mckee_samples_10T/AD_10382/dist_corrected/volume/';
fname = 'ref_4ds_norm';
ext = '.btf';
filename = strcat(dpath, strcat(fname,ext));
% Convert .tif to .MAT
vol = TIFF2MAT(filename);

%% Multiscale vessel segmentation
% I = 3D angiogram
% sigma = standard deviation values of gaussian filter
% thres = threshold for binarizing vessel in segmentation [0, 1]
I = double(vol);
sigma = 1;
thres = 0.2;
[~, I_seg] = vesSegment(I, sigma, thres);

%% Save segmented volume as .MAT and .TIF
% Save vessel segment stack as .MAT for the next step (graph recon)
fname = strcat(fname, '_sigma', num2str(sigma));
fout = strcat(dpath, fname);
save(strcat(fout, '.mat'), 'I_seg', '-v7.3');
% Save as .TIF for visualizations
tifout = strcat(fout, '.tif');
segmat2tif(I_seg, tifout);

%{
%% Apply mask to segmentation volume -- remove erroneous vessels
% TODO: find optimal range for remove_mask_islands
% TODO: create function "clean_mask" and perform both:
%       - imerode - remove boundaries
%       - remove_mask_islands - remove islands of pixels

%%% Create mask from normalized volume
% TODO: create function to create binary 3D mask

%%% Place next two steps into a function "clean_mask":
% Erode mask to remove small pixels on border that are not part of volume
se = strel('disk',10);
mask = imerode(mask, se);

% Remove islands of pixels from mask
% Range of object size to keep
range = [1e4, 1e8];
mask_isl = remove_mask_islands(mask, range);

%%% Apply mask to segmentation volume
% Convert from logical back to uint16 for matrix multiplication
mask_isl = uint16(mask_isl);
% Element-wise multiply mask and volume
vol_masked = apply_mask(vol, mask_isl);
% Convert masked image back to tif
fout = strcat(laptop_path, strcat(vol_name,'_masked_eroded_island_rm.tif'));
segmat2tif(vol_masked, fout);

%% Convert segmentation to graph
% I_seg is the segmentation matrix
I_seg_path = strcat(fout, '.mat');
Graph = seg_to_graph(I_seg_path);   

%%% Save graph
% Create new filename for graph and add .MAT extension
fname = strcat(fname, '_frangi_seg.mat');
fout = strcat(dpath, fname);
save(fout,'Graph');

%% Initialization of vesGraphValidate
% Run "Verification > get segment info > Update"
% Run "Update branch info"
% Run "Regraph Nodes" to down sample
% Open GUI with both image and data (graph)
% Run prune_loops and prune_segment
% Run straighten


%% Perform manual pruning
% The user must use the matlab GUI to manually remove these segments

%% Calculate Diameter
% Load Graph struct
fname = 'volume_nor_inverted_masked_sigma1_frangi_seg_regraphed';
dpath =...
    'C:\Users\mack\Documents\BU\Boas_Lab\psoct_human_brain_resources\test_data\Hui_Frangi_dataset\200726PSOCT\';
fpath = strcat(dpath, strcat(fname,'.mat'));
Data = load(fpath,'Graph');

% Call function to calculate diameter at each node
Diam = GetDiam_graph(...
    vol,...
    Data.Graph.nodes,...
    Data.Graph.edges,...
    Ithresh,...
    vox_dim);

%% Calculate Tortuosity
tortuosity = vessel_tortuosity_index(Data.Graph, Ithresh);

%% Histograms for geometries
% Histo for diameter
figure; histogram(Diam);
title('Vessel Diameter')
xlabel('Diameter (microns)')
ylabel('Count')
set(gca, 'FontSize', 20)

% Histo for diameter
figure; histogram(tortuosity);
title('Vessel Tortuosity')
xlabel('Tortuosity (unitless)')
ylabel('Count'); ylim([0,200])
set(gca, 'FontSize', 20)
%}

%% (OLD CODE) Median diameter
%{
dia_vessel=zeros(1,length(Data.Graph.segInfo.segLen));
for i=1:length(dia_vessel)
    dia_vessel(i)=median(Diam(find(Data.Graph.segInfo.nodeSegN(:)==i)));
end
figure; histogram(dia_vessel,'BinWidth',10);
%}

%% (OLD CODE) length of each vessel
%{
% remove fake vessels
length_vessel( length_vessel(:)==0 ) = [];
figure;
histogram(length_vessel.*10,0:25:1000);
%}


%% (OLD CODE) extract vessels and clean up boundaries by creating a mask
%{
V_seg=TIFF2MAT('I_seg_Ann.tif');
mask=TIFF2MAT('I_mask.tif');
for i=1:size(img,3)
    mask_tmp=squeeze(mask(:,:,i));
    mask_tmp(mask_tmp(:)~=0)=1;
    mask_tmp = bwareaopen(logical(mask_tmp), 500);
    V_seg(:,:,i)=uint16(mask_tmp).*squeeze(V_seg(:,:,i));
    % figure;imshow(mask_tmp);
end
MAT2TIFF(V_seg,'I_seg_masked2.tif');
%}

%% (OLD CODE) calculate topology
%{
% skeletonization
I_seg=TIFF2MAT('I_seg_nor_mask.tif');
I_seg(I_seg(:)~=0)=1;
I_skel=bwskel(logical(I_seg));
MAT2TIFF(I_skel,'I_seg_skel.tif');
%}

function segment_main(dpath, fname, ext)
% 

end

function graph_main()

end