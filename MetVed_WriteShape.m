function [] = MetVed_WriteShape(S,PrjFile,ofname)
%--------------------------------------------------------------------------
% Metved: Emissions from Residential Wood Combustion
%--------------------------------------------------------------------------
% Explanation goes here:
%
% NILU: Aug 2020: Henrik Grythe
%--------------------------------------------------------------------------
fprintf('\n%s\n',text_div)
fprintf('In MetVed_WriteShape\n\n')

dbfspec = makedbfspec(S);
shapewrite(S, ofname, 'DbfSpec', dbfspec)
prj = MetVed_read_projection(PrjFile);
pfilename=strcat(ofname,'.prj');
fid=fopen(pfilename,'w+');
fprintf(fid,'%s',prj);
fclose(fid);
fprintf('Wrote file; \n %s \n',ofname)

end