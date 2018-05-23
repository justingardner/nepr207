function savedata_classification(cfolder,rois,scan)
%%SAVEDATA_CLASSIFICATION
%
% Call:
% savedata_classification('path/to/folder/',{'roi1','roi2'},scan#inConcatentation');
%
% Example:
% savedata_classification('/Users/dan/data/cogneuro/s037120180521',{'lV1','rV1'},2);
%
% Output:
% in folder 'path/to/folder/' you will find classify_roi1roi2.mat
% containing:
%
%   resp (x*y*z * condition * time)
%   roiresp (voxel * condition * time)

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

%% Get analysis
view = loadAnalysis(view,sprintf('erAnal/%s','task')); % check analysis name!


%% Re-organize data matrix
task = view.analyses{1};
d = task.d{scan};

data.resp = d.ehdr;
data.roiresp = {};

%% Get coordinates of rois
for ri = 1:length(rois)  
    
    [scanCoords, ~] = getROICoordinates(view,rois{ri},scan,viewGet(view,'curGroup'),'straightXform',0);

    data.roiresp{end+1} = zeros(size(scanCoords,2),size(data.resp,4),size(data.resp,5));
    for vi = 1:size(scanCoords,2)
        data.roiresp{end}(vi,:,:) = data.resp(scanCoords(1,vi),scanCoords(2,vi),scanCoords(3,vi),:,:);
    end
end

%% Save
save(fullfile(cfolder,sprintf('classify_%s',[rois{:}])),'data');

%% Return
mrQuit;
cd(cwd);