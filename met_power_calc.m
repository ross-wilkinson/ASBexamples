%% Metabolic Power Calculation
% Calculate metabolic power during final two minute steady-state period
% from a .csv output file from a Parvo Gas Analyzer

%% Load Parvo data
filename = '/Users/rosswilkinson/Documents/Postdoc/Specialized/Seat Tube Angle/data/MTB_geo_pilot_RW_vo2.xlsx';

%% User input data
prompt = 'Enter number of trials conducted:';
dlgtitle = 'Input';
dims = [1 35];
definput = {'4'};
answer = str2double(inputdlg(prompt,dlgtitle,dims,definput));

prompt1 = cell(1,answer*2);
dlgtitle1 = 'Input';
dims1 = [1 35];
n = 0;

for i = 1:answer*2
    if rem(i,2)
        n = n+1;
        definput{i} = ['Start Time Trial ' num2str(n)];
    else
        definput{i} = ['End Time Trial ' num2str(n)];
    end
end
answer1 = str2double(inputdlg(prompt1,dlgtitle1,dims1,definput));
%% Manual input data
subMass = 77.4; % subject mass in kg
condition = {'01','02','02','01'}; % order of conditions
rm = {'01','01','02','02'}; % order of repeated measures
period = 120; % steady state period in seconds
freq = 5; % sampling rate in seconds
samples = period/freq; % # of samples

%% Calculate time in seconds from inputs
times = round(floor(answer1)+(answer1-floor(answer1))/.60,2);

%% Create data table of type double
T = readtable(filename,'ReadVariableNames',0);
T.Properties.VariableNames = T{27,:};
T.Properties.VariableUnits = T{29,:};
T = T(31:end,:);
T = convertvars(T,T.Properties.VariableNames,'string');
T = convertvars(T,T.Properties.VariableNames,'double');
end_ind = find(isnan(T.TIME(:,1)),1)-1;
T = T(1:end_ind,:);

%% Find indices of trial periods to split data
for i = 1:length(times)
    ind(i) = find(T.TIME < times(i),1,'last');
end

%% Split trial data into structure and fields 
for i = 1:answer
    field = ['c' condition{i} rm{i}];
    S.(field) = T(ind(i*2-1):ind(i*2-1)+60,:);
    for j = 1:height(S.(field))
        % Calculate Metabolic Power at each time point
        VO2 = S.(field).VO2(j)/60; % convert to L/s
        VCO2 = S.(field).VCO2(j)/60; % convert to L/s
        metP = (16.89*VO2 + 4.84*VCO2)*1000;
        S.(field).MetP(j) = metP;
        S.(field).MetP_kg(j) = metP/subMass;
        if j == 1
            S.(field).MetE(j) = NaN;
        else
            t1 = S.(field).TIME(j-1)*60;
            t2 = S.(field).TIME(j)*60;
            metP = S.(field).MetP(j);  
            % Multiply Met. Power by time to get Energy
            S.(field).MetE(j) = metP * (t2-t1);
        end
    end
    steadyStart = S.(field).TIME(end-samples);
    steadyEnd = S.(field).TIME(end);
    steadySeconds = (steadyEnd - steadyStart) * 60;
    totalEnergy = sum(S.(field).MetE(end-samples:end));
    % Place total MetE into structure 
    S.MetE.(field) = totalEnergy;
    % Place MetP data into structure
    S.MetP.(field) = totalEnergy / steadySeconds;
    % Place mean of each variable into structure
    S.means.(field) = varfun(@mean, S.(field)(end-samples:end,:));
end

%% Save results
cd '/Users/rosswilkinson/Documents/Postdoc/Specialized/Seat Tube Angle/results'
save('pilot_data','S')
