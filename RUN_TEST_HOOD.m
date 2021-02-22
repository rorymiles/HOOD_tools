clear all
close all
clc

%This programme runs a test in the Hood

%USE AT YOUR OWN RISK!

%%%% NOTES %%%
% - the DPT span is from manufacurers data sheet - this should be
%checked.
% - the time between readings is ~1.3 s. 
% - the HRR calculations may be spurious.
% - delay times are not considered.
% - the RH probe is assumed to follow manufacturer data (is the hard coded data correct?).
% - HRR calculations do not do any pre-ignition averaging (this is for
%flexibility).
% - there is perhaps some efficinecy to be gained by having the variables
%as structures e.g. all the temperatures as T.xxx, concentrations as C.xxx
%maybe later...
% - T_stack? T_smoke? who knows?
% - you need to write a separate programme to do proper HRR calculations.
% - all data are saved as a .mat file

% Tell matlab the format for the timestamp - required for keepign track of
% things
TimeStampFormat = 'yyyymmddHHMMSS.FFF';

%give a filename for your data. The timestamp should prevent any overwriting
FileName = inputdlg('Filename', 'Filename', [1 35], {[datestr(now, TimeStampFormat) '_']});
FileName = [cell2mat(FileName) '.mat'];

% AGILENT
% Conenct
v34970A = visa('agilent', 'GPIB0::9::INSTR');
v34970A.InputBufferSize = 8388608;
v34970A.ByteOrder = 'littleEndian';
fopen(v34970A);

% Housekeeping
fprintf(v34970A, sprintf(':FORMat:READing:CHANnel %d', 1));
fprintf(v34970A, sprintf(':FORMat:READing:ALARm %d', 1));
fprintf(v34970A, sprintf(':FORMat:READing:UNIT %d', 1));
fprintf(v34970A, sprintf(':FORMat:READing:TIME:TYPE %s', 'REL'));

% a prompt in the command line to check the load cell is in use
loadcell_in_use = input('Are you using the load cell? y/n: ', 's');

if sum(strcmp(loadcell_in_use, {'Y', 'y'})) >0
    %LOAD CELL - connect and open
    loadcell = tcpip('192.168.11.20',4305);
    fopen(loadcell);
else
    loadcell = 1;
end

% call the function that does the fitting requred from the calibration
[O2_fit, CO_fit, CO2_fit, DPT_fit, RH_fit] = vdc2eng_units(FileName);

%figure to plot the data and add some commands for the user - this is set up so the system keeps logging until
%you hit the stop button. Always end with this so the code closes the
%instruments and you dont have to use tmtool to manually do that
test_fig = figure('units', 'normalized', 'position', [0.25 0.25 0.5 0.5]);

% the buttons and their callback functions. MATLAB does not recommend using
% strings as the callbacks but rather to use functions. Trouble is passing
% the info between the handles and the function :(. A bit of a hack but it
% works
ignition_button = uicontrol('Style', 'Pushbutton', 'String', 'Ignition', 'fontsize', 16, 'BackgroundColor',[0.8 0.8 0.8], 'units', 'normalized', 'Position', [0.15 0.03 0.1 0.07],'Callback', 'ignition_time(i) = str2num(datestr(now, TimeStampFormat));ignition_row(i) = i;');
event_button = uicontrol('Style', 'Pushbutton', 'String', 'Event', 'fontsize', 16, 'BackgroundColor',[0.8 0.8 0.8], 'units', 'normalized', 'Position', [0.35 0.03 0.1 0.07],'Callback', 'event_time(i) = str2num(datestr(now, TimeStampFormat));event_row(i) = i;');
flameout_button = uicontrol('Style', 'Pushbutton', 'String', 'Flame out', 'fontsize', 16, 'BackgroundColor',[0.8 0.8 0.8], 'units', 'normalized', 'Position', [0.55 0.03 0.1 0.07],'Callback', 'flameout_time(i) = str2num(datestr(now, TimeStampFormat));flameout_row(i) = i;');
stop_button = uicontrol('Style', 'Pushbutton', 'String', 'Stop', 'fontsize', 16, 'BackgroundColor',[0.8 0.8 0.8], 'units', 'normalized', 'Position', [0.75 0.03 0.1 0.07],  'Callback', 'delete(gcbf)');

%prepare the axes in a nice way by calling the function prepare_axes (its at
%the end of the script
[O2_axes, CO_axes, CO2_axes, mass_axes, HRR_axes, duct_flow_axes] = prepare_axes(test_fig);

i = 1; %cos a counter is needed to index the variables

%this is a hack
v_duct = 0; 
X0_O2_A = 0;
X0_CO_A = 0;
X0_CO2_A = 0;
Q_OC__O2_CO2_CO = 0;

% This is where the magic (DATA LOGGING) happens

while(ishandle(stop_button)) %so the loop runs til you press STOP
    
    if isobject(loadcell) == 1 % only query the load cell if it is in use
        mass_str = query(loadcell, 'SI'); %ask the load cell for the mass
        if length(mass_str) > 5 %this bit is to avoid weird stuff coming from the scale messing up the loop
            mass(i) = str2double(mass_str(9:14)); %if the string is long enough it is asimed to have numbers in these posiitons (maybe not always true?)
        else
            mass(i) = NaN; % if the string is not long enough, repleace the mass with a NaN
        end
    else
        mass(i) = NaN;
    end
    
    temps = query(v34970A, sprintf(':MEASure:TEMPerature? %s,%s,(%s)', 'TCouple', 'K', '@111:115')); %scan the temperaure channels
    tic
    readings = query(v34970A, sprintf(':MEASure:VOLTage:DC? (%s)', '@101:109')); %scan the voltage reacdings (DPT, gases)
    toc
    
    v_data(i,:) = str2num(readings); %make a variable that is a matriix of all teh channels
    temperatures(i,:) = str2num(temps) ; %same with the temps
    timestamp(i) = str2double(datestr(now, TimeStampFormat))'; %get a timestamp to associate with the data
    test_time(i) = (datenum(num2str(timestamp(i), '%.3f'), TimeStampFormat)-datenum(num2str(timestamp(1), '%.3f'), TimeStampFormat)).*(24*60*60);
    
    O2_conc(i) = v_data(i,1)*O2_fit(1)+O2_fit(2);
    DPT_Pa(i) = v_data(i,2)*DPT_fit(1)+DPT_fit(2);
    CO_conc(i) = v_data(i,3)*CO_fit(1)+CO_fit(2);
    CO2_conc(i) = v_data(i,4)*CO2_fit(1)+CO2_fit(2);
    
    RH_ambient(i) = v_data(i,9)*RH_fit(1)+RH_fit(2);
    
    T_cold_trap(i) = temperatures(i,1);
    T_duct(i) = temperatures(i,2);
    T_smoke(i) = temperatures(i,5);
    T_duct2(i) =  temperatures(i,4);
    T_ambient(i) = temperatures(i,5);
    
    [Q_OC__O2_CO2_CO, v_duct, X0_O2_A, X0_CO_A, X0_CO2_A] = HRR_calc(i, CO_conc, CO2_conc, O2_conc, T_ambient, T_duct, RH_ambient, DPT_Pa, v_duct, X0_O2_A, X0_CO_A, X0_CO2_A, Q_OC__O2_CO2_CO);
    
    tic
    plot_O2 = plot(test_time, O2_conc, 'parent', O2_axes, 'color', 'b');
    plot_mass = plot(test_time, mass, 'parent', mass_axes, 'color', 'k');
    plot_CO = plot(test_time, CO_conc, 'parent', CO_axes, 'color', 'k');
    plot_CO2 = plot(test_time, CO2_conc, 'parent', CO2_axes, 'color', 'r');
    plot_HRR = plot(test_time, Q_OC__O2_CO2_CO, 'parent', HRR_axes, 'color', 'r');
    plot_duct_flow = plot(test_time, v_duct, 'parent', duct_flow_axes, 'color', 'g');
    toc
    %
    i = i+1 %add one to the counting variable whch is used in indexing
    pause(0.1) %if there isnt a pause you cant click the buttons (hacky hack...)
    
end

%save the variables
save(FileName)%, '-append')

% 'timestamp', 'v_data', 'temperatures', 'test_time', 'mass',...
%     'O2_conc', 'CO_conc', 'CO2_conc', 'DPT_Pa', 'RH_ambient',...
%     'T_cold_trap', 'T_duct', 'T_smoke', 'T_duct2', 'T_ambient',...
%     'ignition_row', 'ignition_time', 'event_row', 'event_time',  'flameout_row', 'flameout_time',...
%     'Q_OC__O2_CO2_CO', '-append')

%Close and delete the objects
fclose(v34970A);
delete(v34970A);
clear v34970A;
if isobject(loadcell) == 1
    fclose(loadcell);
    delete(loadcell);
    clear loadcell
end

% THESE ARE THE FUNCTIONS CALLED EARLIER TO KEEP THE CODE FROM LOOKING TOO UGLY

%a function to create the axes
function [O2_axes, CO_axes, CO2_axes, mass_axes, HRR_axes, duct_flow_axes] = prepare_axes(test_fig)
O2_axes = axes('Parent', test_fig, 'Position',[0.05 0.75 0.15 0.15], 'box', 'on');
CO_axes = axes('Parent', test_fig, 'Position',[0.3 0.75 0.15 0.15], 'box', 'on');
CO2_axes = axes('Parent', test_fig, 'Position',[0.55 0.75 0.15 0.15], 'box', 'on');
duct_flow_axes = axes('Parent', test_fig, 'Position',[0.8 0.75 0.15 0.15], 'box', 'on');
mass_axes = axes('Parent', test_fig, 'Position',[0.05 0.2 0.4 0.4], 'box', 'on');
HRR_axes = axes('Parent', test_fig, 'Position',[0.55 0.2 0.4 0.4], 'box', 'on');

hold(O2_axes);
hold(CO_axes);
hold(CO2_axes);
hold(mass_axes);
hold(HRR_axes);
hold(duct_flow_axes);

O2_axes.YLabel.String = 'O_2 Concentration, %';
CO_axes.YLabel.String = 'CO Concentration, ppm';
CO2_axes.YLabel.String = 'CO_2 Concentration, ppm';
mass_axes.YLabel.String = 'Mass, kg';
HRR_axes.YLabel.String = 'HRR (O2, CO2, CO), kW';
duct_flow_axes.YLabel.String = 'Duct flow, l/s';
O2_axes.XLabel.String = 'Time, s';
CO_axes.XLabel.String = 'Time, s';
CO2_axes.XLabel.String = 'Time, s';
mass_axes.XLabel.String = 'Time, s';
HRR_axes.XLabel.String = 'Time, s';
duct_flow_axes.XLabel.String = 'Time, s';
end
%a function to deal with the conversion between volts and engineerng units
function [O2_fit, CO_fit, CO2_fit, DPT_fit, RH_fit] = vdc2eng_units(FileName)

load HOOD_CALIBRATION_DATA.mat

RH_calib_V = [0 5];
RH_zero_span = [0 100];

O2_fit = polyfit(O2_calib_V, O2_zero_span, 1);
CO_fit = polyfit(CO_calib_V, CO_zero_span, 1);
CO2_fit = polyfit(CO2_calib_V, CO2_zero_span, 1);
DPT_fit = polyfit(DPT_calib_V, DPT_zero_span, 1);
RH_fit = polyfit(RH_calib_V, RH_zero_span, 1);

save(FileName, 'O2_calib_V', 'CO_calib_V', 'CO2_calib_V', 'DPT_calib_V',...
    'O2_zero_span', 'CO_zero_span', 'CO2_zero_span', 'DPT_zero_span');

end

function [Q_OC__O2_CO2_CO, v_duct, X0_O2_A, X0_CO_A, X0_CO2_A] = HRR_calc(i, CO_conc, CO2_conc, O2_conc, T_ambient, T_duct, RH_ambient, DPT_Pa, v_duct, X0_O2_A, X0_CO_A, X0_CO2_A,Q_OC__O2_CO2_CO)
%%% MOST OF THE INDEXING HERE CAN GO! %%%%
%turn T into units of K
T_ambient = T_ambient+273;
T_duct = T_duct+273;

% Define constants needed for HRR calcs
%MW of species
M_air = 28.8;                                                             % Molecular weight of dry air [kg/kmol]
M_H2O = 18;                                                                 % Molecular weight of H2O [kg/kmol]
M_CO = 28;                                                                  % Molecular weight of CO [kg/kmol]
M_CO2 = 44;                                                                 % Molecular weight of CO2 [kg/kmol]
M_N2 = 28;                                                                  % Molecular weight of N2 [kg/mol]
M_O2 = 32;                                                                  % Molecular weight of O2 [kg/mol]
M_Soot = 12;                                                                % carbon molecular weight [kg/kmol]
M_CH4 = 16;                                                                 % Molecular weight of CH4 [kg/mol]

% universal constants
R = 8.314472;
p_ambient = 101325; %Pa

% energy constants
E_O2 = 13.1;
E_CO2 = 13.3;
E_CO = 17.6;
E_CO_CO2 = 17.63 * 1000; % no idea what this is! assumed to be the energy release from CO->CO2
E_S = 12.3 * 1000;  % 12.3E3[MJ/kg]  Energy release per mass unit of oxygen consumed for combustion of soot to CO2 [kJ/kg]
Delta_H_CO = 283000/28/1000 * 1000; % 2.83E5[kJ/mole] or 10.11 [MJ/kg] Energy release per unit mass of CO consumed in the burning of CO [kJ/mole] Ref.VI
Delta_H_S = 393500/12/1000 * 1000; 

% Calorimetry specific constants
alpha = 1.105;

% Apparatus constants
K = 0.86; %probe constant
Dia_Duct = 0.315; %m
Area_Duct = pi * (Dia_Duct^2) / 4;

% Duct flow calculation
rho_air(i) = M_air/1000*101325./(R.*T_duct(i));
f_Re = 1.08;

% m_Duct_TS = Area_Duct .* K_ ./ f_Re .* ((2 .* p_DPT .* rho_air.^(1/2))); % Mass flow [kg/s] in the test section duct Equation 4 Ref.I
% v_Duct_TS = m_Duct_TS ./ rho_air;                     % Volumetric flow [m3/s] in the test section duct Ref.II

m_duct(i) = 26.54.*Area_Duct.*K./f_Re.*(DPT_Pa(i)./T_duct(i)).^(1/2);
v_duct(i) = m_duct(i)./rho_air(i).*1000;

% Mole fractions &c
X_CO_A(i) = CO_conc(i) ./ 10^6;
X_CO2_A(i) = CO2_conc(i) ./ 10^6;
X_O2_A(i) = O2_conc(i) ./ 100;

p_H2O_saturation(i) = exp(23.2 - 3816 ./ (-46 + T_ambient(i)));
X0_H2O(i) = RH_ambient(i) .* p_H2O_saturation(i) ./ 100 ./ p_ambient;   % The molar fraction of water vapor Equation (10) Ref.I

X_Soot = 0;

X_H2O(i) = X0_H2O(i);

X_O2(i)  = X_O2_A(i)  .* (1 - X_H2O(i) - X_Soot);                                         % Molar fraction of oxygen in the exhaust duct from Equation (18) Ref.III
X_CO(i)  = X_CO_A(i)  .* (1 - X_H2O(i) - X_Soot);                                         % Molar fraction of carbon monoxid in the exhaust duct from Equation (18) Ref.III
X_CO2(i) = X_CO2_A(i) .* (1 - X_H2O(i) - X_Soot);

% the ambinet mole fractions are taken to be the first reading to avoid
% having to average
if i==1
X0_O2_A = X_O2_A(1);
X0_CO2_A = X_CO2_A(1);
X0_CO_A = X_CO_A(1);
else 
end
%commented sicne we dont calculate a pre ignition average
% X0_O2_A = mean(X_O2_A(1:t_ignition_row-1));
% X0_CO2_A = mean(X_CO2_A(1:t_ignition_row-1));
% X0_CO_A = mean(X_CO_A(1:t_ignition_row-1));
% disp(['The mole fraction of O2 at the start is ' num2str(X0_O2_A)])
% disp(['The mole fraction of CO2 at the start is ' num2str(X0_CO2_A)])
% disp(['The mole fraction of CO at the start is ' num2str(X0_CO_A)])
% disp(['The vapour pressure of water is ' num2str(X0_CO_A)])

% depletion factors and associated stuff

% if O2 and CO2 are measured
phi_O2_CO2(i) = (X0_O2_A./(1-X_CO2_A(i)) - X_O2_A(i).*(1-X0_CO2_A))./((1-X_O2_A(i)-X_CO2_A(i)).*X0_O2_A);
% if O2 CO2 and CO are measured
PHI_O2_CO2_CO(i) = (X0_O2_A .* (1 - X_CO2_A(i) - X_CO_A(i)) - ...                    % Equation (20) Ref.I
    X_O2_A(i) .* (1 - X0_CO2_A)) ./ ...
    (X0_O2_A .* (1 - X_O2_A(i) - X_CO2_A(i) - X_CO_A(i)));

m_incoming_air(i) = m_duct(i) ./ (1 + PHI_O2_CO2_CO(i) .* (alpha - 1));             % Mass flow rate of the incomming air [kg/s] Equation (15) Ref.I
M_incoming_air(i) = M_air * (1 - X0_H2O(i)) + M_H2O * X0_H2O(i);                % Molecular weight of the incomming air [kg/kmol] which should be around 29 Equation (11) Ref.I
m_M__incoming_air_var = m_incoming_air(i) ./ M_incoming_air(i);
M_air_duct(i) = M_incoming_air(i);

% Heat relase by Oxygen Consumption Calorimetry when O2, CO2 and CO are
% measured. From Janssens, M.L. and Parker, W.J. 1992. "Oxygen Consumption Calorimetry,"in Heat Release in Fires, edited by V. Babrauskas and S.J. Grayson,Chapter 3: pp. 31-59.

Q_OC__O2_CO2_CO(i) = ((E_O2 .* PHI_O2_CO2_CO(i) - (E_CO - E_O2) .* (1-PHI_O2_CO2_CO(i)) ./ 2 .* X_CO_A(i) ./ X_O2_A(i)) .* ...
    m_incoming_air(i) ./ M_incoming_air(i) .*  M_O2 .* (1 - X0_H2O(i)) * X0_O2_A)*1000;

end