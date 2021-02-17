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
function T= Find_Norwegian_Holidays(date,Cabin_Population_file)
%--------------------------------------------------------------------------
% This function finds the holidays in Norway for a given dates year. It is 
% based on input from a sheet where the user input is the variable vaccation
% weeks in fall and summer. 

% This function also calculates the amount of Norwegians at cabins during
% each holiday. 
%--------------------------------------------------------------------------

Tva = readtable(Cabin_Population_file,'Sheet','Varaiable_Vaccations');

ymd = datevec(date);
year = ymd(1);
yd              = datenum([year 1 1 0 0 0]):1: datenum([year+1 1 1 0 0 0])-1;
holiday    = zeros(size(yd));  Cabin_day  = zeros(size(yd)); 
Sum_Factor = ones(size(yd));   Win_Factor = ones(size(yd));

day_of_the_week = weekday(yd);
day_of_the_week = day_of_the_week -1;
day_of_the_week(day_of_the_week==0)=7;
week_num = week(datetime(datevec(yd)));
week_num(day_of_the_week==7)=week_num(day_of_the_week==7)-1;

fprintf('Year %i is ',year)
if length(yd)==365   
    fprintf('Not a Leap year \n')
elseif length(yd)==366
    fprintf('A Leap year \n')
else
    fprintf('Not a valid year \n')
    return
end

%--------------- EASTER ---------------------------------------------------
ED     = Find_Easter(date);
fprintf('Easter in %i is %s\n',year,datestr(ED))
ide = find(yd == ED);
holiday(ide-3:ide+1) = 2;
holiday(ide-6:ide-4) = 1;

Sum_Factor(ide-3:ide+1) = Tva.Coastal(1);
Sum_Factor(ide-6:ide-4) = Tva.Coastal(1);

Win_Factor(ide-3:ide+1) = Tva.Mountain(1);
Win_Factor(ide-6:ide-4) = Tva.Mountain(1);

% ------------- KRISTI HIMMELFART -----------------------------------------
KrHimmelfart    = ED + 40;
ide = find(yd == KrHimmelfart);
holiday(ide) = 2;
holiday(ide+1) = 1;

% ------------- Pinse             -----------------------------------------
pinse           = ED+49;
ide = find(yd == pinse);
holiday(ide+2) = 2;

% ------------- Vinterferie Uke   -----------------------------------------
vinterferieuke  = Tva.Weeknum(2);
ide = find(week_num == vinterferieuke);
holiday(ide) = 1;
Sum_Factor(ide) = Tva.Coastal(2);
Win_Factor(ide) = Tva.Mountain(2);

% ------------- Høstferie Uke   -------------------------------------------
hoestferieuke   = Tva.Weeknum(3);
ide = find(week_num == hoestferieuke);
holiday(ide) = 1;
Sum_Factor(ide) = Tva.Coastal(3);
Win_Factor(ide) = Tva.Mountain(3);

% ------------- Fellesferie Uker-------------------------------------------
sommerferieuke1 = 27;
ide = find(week_num == sommerferieuke1);
holiday(min(ide):min(ide)+28) = 1;

% ------------- Første Mai ------------------------------------------------
forsteMai       = datenum([year 5 1 0 0 0]);
ide = find(yd == forsteMai);
holiday(ide) = 2;

% ------------- Syttende Mai ----------------------------------------------
syttendeMai     = datenum([year 5 17 0 0 0]);
ide = find(yd == syttendeMai);
holiday(ide) = 2;

% ------------- Jula ------------------------------------------------------
julaften        = datenum([year 12 24 0 0 0]);
ide = find(yd == julaften);
holiday(ide:ide+2) = 2;
holiday(ide+3:end) = 1;

% ------------- Første Nyttårsdag    --------------------------------------
holiday(1) =   2;

%--------------------------------------------------------------------------
for i =1:length(yd)
    if day_of_the_week(i) == 5 || day_of_the_week(i) == 5
        Cabin_day(i) = 1;
    end
    if day_of_the_week(i) == 6
        Cabin_day(i) = 2;
    else
        if i>1 && i< length(yd)
            if day_of_the_week(i-1) > 5 || holiday(i-1)>0 % last day was a holiday
                if day_of_the_week(i+1) > 5 || holiday(i+1)>0 % next day is a holiday
                    Cabin_day(i) = 2;
                end
            end
        end
    end
    if Cabin_day(i)<2 & (day_of_the_week(i)==5 || day_of_the_week(i)==7)
        Cabin_day(i) = 1;
    end
end
for i =2:length(yd)-1
    if Cabin_day(i-1)>1 && Cabin_day(i+1)>0
        Cabin_day(i) = 2;
    end
     if Cabin_day(i-1)>1  && Cabin_day(i+1)==0
        Cabin_day(i) = 1;
     end
end
% ------------- Nyttårsaften and Jan. 1st are treated as Cabin days -------
Cabin_day(end) = 2;
Cabin_day(1)   = 2;

% ------------ Finally Construct the table with the relevant information --
T=table;
T.Mdate         = yd';
T.Weekday       = day_of_the_week';
T.Weeknum       = week_num;
T.Holiday       = holiday';
T.Cabin_day     = Cabin_day'+1;
T.Summer_Factor = Sum_Factor';
T.Winter_Factor = Win_Factor';

end
