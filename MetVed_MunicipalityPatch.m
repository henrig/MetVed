%--------------------------------------------------------------------------
% This file is part of MetVed
% 
% MetVed is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation version 3.
% 
% MetVed is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with MetVed.  If not, see <https://www.gnu.org/licenses/>.
%--------------------------------------------------------------------------
function [S] = MetVed_MunicipalityPatch(S,Municipality_list)
global SSBfile EFSheet
% Patch for bergen and possibly also other municipalities 


kom = extractfield(S,'KommuneNR');

sp = fieldnames(S);
sp = sp(contains(sp,'gEM_'));
specs = regexprep(sp,'gEM_','');

C = extractfield(S,'GridConsumption');
Tef  = readtable(SSBfile,'Sheet',EFSheet);
T = struct2table(S);


fprintf('Making emissions with all NEW emission factors\n')
for i = 1:length(Municipality_list)
    idx_kom = (kom == Municipality_list(i));
    cnt = sum(idx_kom);
    

    fprintf('Adjusting emissions in:\n KommuneNr  %04i \n ##### %i fields\n',Municipality_list(i),cnt)
    for s = 1:length(specs)
        fld               = sprintf('gEM_%s',char(specs(s)));
        idx_spec          = find(ismember(Tef.EF,specs(s)));
        oldEM(s,:)        = extractfield(S,fld);
        newEM(s,~idx_kom) = oldEM(s,~idx_kom);   
        newEM(s,idx_kom)  = C(idx_kom)*Tef.x2020_New(idx_spec);
        % stats
        local             = 100*(sum(newEM(s,idx_kom),2)-sum(oldEM(s,idx_kom),2))./sum(oldEM(s,idx_kom),2);
        norway = 100*(sum(newEM(s,:),2)-sum(oldEM(s,:),2))./sum(oldEM(s,:),2);
        fprintf(' %8s by %-04.1f%% NORWAY change: %-4.2f%%\n',char(specs(s)),local,norway)
        idT = find(ismember(T.Properties.VariableNames,fld));
        T(idx_kom,idT)= array2table(newEM(s,idx_kom)');
    end    
end

S = table2struct(T);


end




% 
% 
% 
% 
% 
% % Rt = sum(extractfield(ResEm,'gEM_PM25'))
% % Ct = sum(extractfield(CabEm,'gEM_PM25'))
% % Tt = sum(extractfield(TotEm,'gEM_PM25'))
% 
% 
% 
% R = shaperead('N:\Inby\Emission_Group\Emission_Models\MetVed\MetVed_v2\Output_patchBergen\MetVed_Emissions_nEF_2021.shp')
% Rt2 = sum(extractfield(R,'gEM_PM25'))
% Rt
% 
% C = shaperead('N:\Inby\Emission_Group\Emission_Models\MetVed\MetVed_v2\Output_patchBergen\MetCab_Emissions_nEF_2021.shp')
% Ct2 = sum(extractfield(C,'gEM_PM25'))
% Ct
% 
% T = shaperead('N:\Inby\Emission_Group\Emission_Models\MetVed\MetVed_v2\Output_patchBergen\MetAll_Emissions_nEF_2021.shp')
% Tt2 = sum(extractfield(T,'gEM_PM25'))
% Tt



















































