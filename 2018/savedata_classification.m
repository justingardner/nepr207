function savedata_classification(cfolder,rois,scan,analysis,classify)
%%SAVEDATA_CLASSIFICATION
%
% Call:
% savedata_classification('path/to/folder/',{'roi1','roi2'},scan#inConcatentation,analysisName,pertrialforclassifiers);
%
% Example:
% savedata_classification('/Users/dan/data/cogneuro/s037120180521',{'lV1','rV1'},2,'task',false);
%
% Output:
% in folder 'path/to/folder/' you will find classify_roi1roi2.mat
% containing:
%
%   resp (x*y*z * condition * time)
%   roiresp (voxel * condition * time)
%

% Output folder default
output_folder = '~/proj/nepr207/2018/';
idx = strfind(cfolder,'s0');
cf =  cfolder(idx:end);

%% Pull conditions
% Load from group 'Concatenation' scan # the event-related condition data.
% Then save all of this information into a matrix:
%
% output: voxels * condition * time
% header: condition labels
%
% cfolder = s037120180521

cwd = pwd;

%% Move to Data WD
mrQuit
cd(fullfile(cfolder));
folders = dir(pwd);
skip = 1;
for fi = 1:length(folders)
    if ~isempty(strfind(folders(fi).name,'Concatenation')), skip = 0; end
end
if skip
    disp(sprintf('Data folder %s has not been prepared for analysis',cfolder));
    return
end

%% Setup a view + Load Concatenation
view = newView();
view = viewSet(view,'curGroup','Concatenation');
view = viewSet(view,'curscan',scan);
%% Get analysis
view = loadAnalysis(view,sprintf('erAnal/%s',analysis)); % check analysis name!


%% Re-organize data matrix
task = view.analyses{1};
d = task.d{scan};

% data.resp = d.ehdr; you can save out the full response matrix (entire
% brain) using this, but per-roi is probably preferable
data.roiresp = {};

%% Get coordinates of rois
for ri = 1:length(rois)  
    
    [scanCoords, ~] = getROICoordinates(view,rois{ri},scan,viewGet(view,'curGroup'),'straightXform',0);

    data.roiresp{end+1} = zeros(size(scanCoords,2),size(d.ehdr,4),size(d.ehdr,5));
    for vi = 1:size(scanCoords,2)
        data.roiresp{end}(vi,:,:) = d.ehdr(scanCoords(1,vi),scanCoords(2,vi),scanCoords(3,vi),:,:);
    end
    
%     % save out individual matrices for the areas (not necessary)
%     carea = data.roiresp{end};
%     save(fullfile(cfolder,sprintf('decon_%s.mat',rois{ri})),'carea');
end
%% Save
save(fullfile(output_folder,cf,sprintf('decon_%s',[rois{:}])),'data');




%% %%%%%%%%%%%%%%%%%
%% Classification %%
%% %%%%%%%%%%%%%%%%%

if ~classify
    % Return
    mrQuit;
    cd(cwd);
    return
end


%% Get individual trial responses
stimvol = d.stimvol;

    croi = loadROITSeries(view,rois,scan,viewGet(view,'curGroup'));
    croi = getSortIndex(view,croi,task.overlays.data{2});
    
%% add missing info and get instances
for ri = 1:length(rois)
    croi{ri}.concatInfo = viewGet(view,'concatInfo');
    croi{ri}.framePeriod = 1.5;
    croi{ri}.nFrames = length(size(croi{ri}.tSeries,2));
end

clear times
for ti = 1:10
        times{1} = getInstances(view,croi,stimvol,'startLag',ti,'blockLen',4,'n=inf');

    %% Pull instances and stack

    for ri = 1:length(rois)
        if length(times{1}{ri}.instance.instances)==2
            numIns = size(times{1}{ri}.instance.instances{1},1)+size(times{1}{ri}.instance.instances{2},1);
        else
            numIns = size(times{1}{ri}.instance.instances{1},1)+size(times{1}{ri}.instance.instances{2},1)+size(times{1}{ri}.instance.instances{3},1);
        end
        data = zeros(numIns,size(times{1}{ri}.instance.instances{1},2));

%         for ti = 1:length(times)
            croi = times{1};
            cond = [];
            cdat = [];
            for ci = 1:length(croi{ri}.instance.instances)
                cond = [cond ; ci*ones(size(croi{ri}.instance.instances{ci},1),1)];
                cdat = [cdat ; croi{ri}.instance.instances{ci}];
            end
            data(:,:) = cdat;

            save(fullfile(output_folder,cf,sprintf('%i_%s_labels.mat',ti,rois{ri})),'cond');
            save(fullfile(output_folder,cf,sprintf('%i_%s_instances.mat',ti,rois{ri})),'data');
%         end
    end
    
end

%% Return
mrQuit;
cd(cwd);