function  out = MetVed_EPISODE_domain_list(dl)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
if ispc
    bp='N:\Inby\';
else
    bp='/storage/nilu/Inby/';
end
base       = sprintf('%s%s',bp,'Emission_Group/Geographical_Domains/');


% base  = '/storage/nilu/Inby/Emission_Group/Geographical_domains/';

DomainList=[{'BB_Bergen_NBV_Grid'},{'BB_Drammen_NBV_Grid'},{'BB_Grenland_NBV_Grid'},...
    {'BB_NedreGlomma_NBV_Grid'},{'BB_Oslo_NBV_Grid'},{'BB_Stavanger_NBV_Grid'},{'BB_Trondheim_NBV_Grid'},...
    {'nbv_halden_v1'},{'nbv_harstad_v1'},{'nbv_lillehammer_v1'},{'nbv_brumunddal_v1'},{'nbv_moss_v1'},...
    {'nbv_gjovik_v1'},{'moirana_nbv_v1'},{'Tiltak_Tromso_Grid_33N'},{'Tiltak_Stavanger_Grid'},{'Levanger_grid_UTM32N'},{'Bergen_tiltak_2017_grid_utm32'}];

ShortName=[{'Bergen'},{'Drammen'},{'Grenland'},...
    {'NedreGlomma'},{'Oslo'},{'Stavanger'},{'Trondheim'},...
    {'Halden'},{'Harstad'},{'Lillehammer'},{'Brummundal'},{'Moss'},...
    {'Gjovik'},{'Mo_i_Rana'},{'Tromso'},{'Stavanger_tiltak'},{'Levanger'},{'Bergen'}];

idTag = [{'{Bergen-AQ-calculations------------01}'},{'{Unknown-AQ-calculations-----------01}'},...
         {'{Unknown-AQ-calculations-----------01}'},{'{Unknown-AQ-calculations-----------01}'},...
         {'{Oslo-AQ-calculations--------------01}'},{'{Unknown-AQ-calculations-----------01}'},...
         {'{Unknown-AQ-calculations-----------01}'},{'{Unknown-AQ-calculations-----------01}'},...
         {'{Unknown-AQ-calculations-----------01}'},{'{Unknown-AQ-calculations-----------01}'},...
         {'{Unknown-AQ-calculations-----------01}'},{'{Unknown-AQ-calculations-----------01}'},...
         {'{Unknown-AQ-calculations-----------01}'},{'{Unknown-AQ-calculations-----------01}'},...
         {'{Unknown-AQ-calculations-----------01}'},{'{Unknown-AQ-calculations-----------01}'},...
         {'{Levanger-AQ-calculations-----------01'},{'Bergen-AQ-calculations-------------01}'}];


if dl == 0
    fprintf('-----------------------------\n')
    fprintf('Testing domain availabilility\n')
    for i = 1: length(DomainList)
        fprintf('-----------------------------\n %02i %s \n',i,char(ShortName(i)))
        fprintf('%s%s\n',base,char(ShortName(i)))
        %     exist(sprintf('%s%s\n',base,char(ShortName(i))),'dir')
        fprintf('ShortName  = %s \nDomainList = %s\n' ,char(ShortName(i)),char(DomainList(i)))
        fname ='';
    end
else
    out.fname = sprintf('%s%s/',base,char(ShortName(dl)),char(DomainList(dl)));
    out.sn    = char(ShortName(dl));
    out.fn    = char(DomainList(dl));
    out.id    = char(idTag(dl));
    
end

end

