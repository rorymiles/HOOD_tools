clear all
close all
clc

% this file runs the calibration for the hood. The data are stored in the
% file CALIBRATE_HOOD.mat. The steps are as follows; 1) load the previous
% version fo the calibration data. This inclides the values for span and
% allows comparison between the old and new caliration data as a sanity
% check. 2) Connect to the agilent (load cell commands are here but they
% are not used for the calibration). 3) Create a figure with pushbuttons.
% 4) define what happens when the buttons are pressed i.e. zero and span as
% appropriate. 5) Finally a button to tidyup after finishing (closing the
% connection to the insruments etc.).

% Note that the inerpolation is not done in this file - that is done in the
% RUN_TEST_HOOD.mat file. This is to ensure that the calibration data is
% linked to your test data. Just in case...

% Tell matlab the format for the timestamp - used timings
TimeStampFormat = 'yyyymmddHHMMSS.FFF';

%number of tiems the channels are scanned to give the average value
number_iterations = 10;

%this is the filaneme for the data - the new data is saved overwriting the previous file
FileName = 'HOOD_CALIBRATION_DATA.mat';

%loads the previous calibration and assigns to variable names for later
load(FileName)
prev_DPT_zero_VDC =  Average_DPT_zero_VDC;
prev_O2_zero_VDC = Average_O2_zero_VDC;
prev_CO_zero_VDC = Average_CO_zero_VDC;
prev_CO2_zero_VDC = Average_CO2_zero_VDC;
prev_O2_span_VDC = Average_O2_span_VDC;
prev_CO_span_VDC = Average_CO_span_VDC;
prev_CO2_span_VDC = Average_CO2_span_VDC;

% AGILENT Datalogger
% Connect
v34970A = visa('agilent', 'GPIB0::9::INSTR');
v34970A.InputBufferSize = 8388608;
v34970A.ByteOrder = 'littleEndian';
fopen(v34970A);

% Housekeeping commands
fprintf(v34970A, sprintf(':FORMat:READing:CHANnel %d', 1));
fprintf(v34970A, sprintf(':FORMat:READing:ALARm %d', 1));
fprintf(v34970A, sprintf(':FORMat:READing:UNIT %d', 1));
fprintf(v34970A, sprintf(':FORMat:READing:TIME:TYPE %s', 'REL'));

% %LOAD CELL - connect and open - NOT USED
% loadcell = tcpip('192.168.11.20',4305);
% fopen(loadcell);

% read in the span data using a dialogue box. Should prepopulate with data
% from the last calibration
prompt = {'O2 Span Value, %', 'CO Span Value, ppm', 'CO2 Span Value, %'};
dlgtitle = 'Check the span values are up to date';
dims = [1 100];
definput = {num2str(O2_span_value),num2str(CO_span_value), num2str(CO2_span_value)};
span_values = inputdlg(prompt,dlgtitle,dims,definput);
O2_span_value = str2double(cell2mat(span_values(1)));
CO_span_value = str2double(cell2mat(span_values(2)));
CO2_span_value = str2double(cell2mat(span_values(3)));

% save the values to the CALIBRATE_HOOD.mat file
save(FileName, 'O2_span_value', 'CO_span_value', 'CO2_span_value', '-append')

% create a figure to house the uicontrols (aka buttons)
calibrate_fig = figure('units', 'normalized', 'position', [0.25 0.25 0.25 0.5], 'Name', 'Press the buttons to do the tasks...','NumberTitle','off');

prev_DPT_zero_VDC =  Average_DPT_zero_VDC;
prev_O2_zero_VDC = Average_O2_zero_VDC;
prev_CO_zero_VDC = Average_CO_zero_VDC;
prev_CO2_zero_VDC = Average_CO2_zero_VDC;
prev_O2_span_VDC = Average_O2_span_VDC;
prev_CO_span_VDC = Average_CO_span_VDC;
prev_CO2_span_VDC = Average_CO2_span_VDC;

% the buttons and their callback functions.
zero_DPT_button = uicontrol('Style', 'Pushbutton', 'String', 'Zero DPT',...
    'fontsize', 16, 'BackgroundColor',[0.8 0.8 0.8], 'units', 'normalized', 'Position', [0 7/8 1 1/8-1/40],'Callback', {@zero_DPT,prev_DPT_zero_VDC,v34970A, FileName});
zero_O2_button = uicontrol('Style', 'Pushbutton', 'String', 'Zero O2',...
    'fontsize', 16, 'BackgroundColor',[0.8 0.8 0.8], 'units', 'normalized', 'Position', [0 6/8 1 1/8-1/40],'Callback', {@zero_O2,prev_O2_zero_VDC,v34970A, FileName});
zero_CO_button = uicontrol('Style', 'Pushbutton', 'String', 'Zero CO',...
    'fontsize', 16, 'BackgroundColor',[0.8 0.8 0.8], 'units', 'normalized', 'Position', [0 5/8 1 1/8-1/40],'Callback', {@zero_CO,prev_CO_zero_VDC,v34970A, FileName});
zero_CO2_button = uicontrol('Style', 'Pushbutton', 'String', 'Zero CO2',...
    'fontsize', 16, 'BackgroundColor',[0.8 0.8 0.8], 'units', 'normalized', 'Position', [0 4/8 1 1/8-1/40],'Callback', {@zero_CO2,prev_CO2_zero_VDC,v34970A, FileName});
span_O2_button = uicontrol('Style', 'Pushbutton', 'String', 'Span O2',...
    'fontsize', 16, 'BackgroundColor',[0.8 0.8 0.8], 'units', 'normalized', 'Position', [0 3/8 1 1/8-1/40],'Callback', {@span_O2,prev_O2_span_VDC,v34970A, FileName});
span_CO_button = uicontrol('Style', 'Pushbutton', 'String', 'Span CO',...
        'fontsize', 16, 'BackgroundColor',[0.8 0.8 0.8], 'units', 'normalized', 'Position', [0 2/8 1 1/8-1/40],'Callback', {@span_CO,prev_CO_span_VDC,v34970A, FileName});
span_CO2_button = uicontrol('Style', 'Pushbutton', 'String', 'Span CO2',...
    'fontsize', 16, 'BackgroundColor',[0.8 0.8 0.8], 'units', 'normalized', 'Position', [0 1/8 1 1/8-1/40],'Callback', {@span_CO2,prev_CO2_span_VDC,v34970A, FileName});
all_done_button = uicontrol('Style', 'Pushbutton', 'String', 'All done!',...
    'fontsize', 16, 'BackgroundColor',[0.8 0.8 0.8], 'units', 'normalized', 'Position', [0 0/8 1 1/8-1/40],'Callback', {@all_done,v34970A});

% these are the functions that are called from the buttons their purpose
% should be fairly self explanatory
function zero_DPT(~,~,prev_DPT_zero_VDC,v34970A, FileName)
for i = 1:10
    readings = query(v34970A, sprintf(':MEASure:VOLTage:DC? (%s)', '@101:109')); %scan the voltage reacdings (DPT, gases)
    v_data(i,:) = str2num(readings); %make a variable that is a matriix of all teh channels
    DPT_zero_VDC(i) = v_data(i,2);
    disp(['VDC DPT Zero = ' num2str(DPT_zero_VDC(i)) ' V.'])
end
Average_DPT_zero_VDC = mean(DPT_zero_VDC);
disp(['New VDC DPT Zero = ' num2str(Average_DPT_zero_VDC) ' V. Previous value was ' num2str(prev_DPT_zero_VDC) ' V.' 'If there is a big diffeerence maybe someting is wrong']);
save(FileName, 'Average_DPT_zero_VDC', '-append')
end

function zero_O2(~,~,prev_O2_zero_VDC,v34970A, FileName)
for i = 1:10
    readings = query(v34970A, sprintf(':MEASure:VOLTage:DC? (%s)', '@101:109')); %scan the voltage reacdings (DPT, gases)
    v_data(i,:) = str2num(readings); %make a variable that is a matriix of all teh channels
    O2_zero_VDC(i) = v_data(i,1);
    disp(['VDC O2 Zero = ' num2str(O2_zero_VDC(i))])
end
Average_O2_zero_VDC = mean(O2_zero_VDC);
disp(['New VDC O2 Zero = ' num2str(Average_O2_zero_VDC) ' V. Previous value was ' num2str(prev_O2_zero_VDC) ' V.' 'If there is a big diffeerence maybe someting is wrong']);
save(FileName, 'Average_O2_zero_VDC', '-append')
end

function zero_CO(~,~,prev_CO_zero_VDC,v34970A, FileName)
for i = 1:10
    readings = query(v34970A, sprintf(':MEASure:VOLTage:DC? (%s)', '@101:109')); %scan the voltage reacdings (DPT, gases)
    v_data(i,:) = str2num(readings); %make a variable that is a matriix of all teh channels
    CO_zero_VDC(i) = v_data(i,3);
    disp(['VDC CO Zero = ' num2str(CO_zero_VDC(i))])
end
Average_CO_zero_VDC = mean(CO_zero_VDC);
disp(['New VDC CO Zero = ' num2str(Average_CO_zero_VDC) ' V. Previous value was ' num2str(prev_CO_zero_VDC) ' V.' 'If there is a big diffeerence maybe someting is wrong']);
save(FileName, 'Average_CO_zero_VDC', '-append')

end

function zero_CO2(~,~,prev_CO2_zero_VDC,v34970A, FileName)
for i = 1:10
    readings = query(v34970A, sprintf(':MEASure:VOLTage:DC? (%s)', '@101:109')); %scan the voltage reacdings (DPT, gases)
    v_data(i,:) = str2num(readings); %make a variable that is a matriix of all teh channels
    CO2_zero_VDC(i) = v_data(i,4);
    disp(['VDC CO2 Zero = ' num2str(CO2_zero_VDC(i))])
end
Average_CO2_zero_VDC = mean(CO2_zero_VDC);
disp(['New VDC CO2 Zero = ' num2str(Average_CO2_zero_VDC) ' V. Previous value was ' num2str(prev_CO2_zero_VDC) ' V.' 'If there is a big diffeerence maybe someting is wrong']);
save(FileName, 'Average_CO2_zero_VDC', '-append')

end

function span_O2(~,~,prev_O2_span_VDC,v34970A, FileName)
for i = 1:10
    readings = query(v34970A, sprintf(':MEASure:VOLTage:DC? (%s)', '@101:109')); %scan the voltage reacdings (DPT, gases)
    v_data(i,:) = str2num(readings); %make a variable that is a matriix of all teh channels
    O2_span_VDC(i) = v_data(i,1);
    disp(['VDC O2 span = ' num2str(O2_span_VDC(i))])
end
Average_O2_span_VDC = mean(O2_span_VDC);
disp(['New VDC O2 span = ' num2str(Average_O2_span_VDC) ' V. Previous value was ' num2str(prev_O2_span_VDC) ' V.' 'If there is a big diffeerence maybe someting is wrong']);
save(FileName, 'Average_O2_span_VDC', '-append')

end

function span_CO(~,~,prev_CO_span_VDC,v34970A, FileName)
for i = 1:10
    readings = query(v34970A, sprintf(':MEASure:VOLTage:DC? (%s)', '@101:109')); %scan the voltage reacdings (DPT, gases)
    v_data(i,:) = str2num(readings); %make a variable that is a matriix of all teh channels
    CO_span_VDC(i) = v_data(i,3);
    disp(['VDC CO span = ' num2str(CO_span_VDC(i))])
end
Average_CO_span_VDC = mean(CO_span_VDC);
disp(['New VDC CO span = ' num2str(Average_CO_span_VDC) ' V. Previous value was ' num2str(prev_CO_span_VDC) ' V.' 'If there is a big diffeerence maybe someting is wrong']);
save(FileName, 'Average_CO_span_VDC', '-append')

end

function span_CO2(~,~,prev_CO2_span_VDC,v34970A, FileName)
for i = 1:10
    readings = query(v34970A, sprintf(':MEASure:VOLTage:DC? (%s)', '@101:109')); %scan the voltage reacdings (DPT, gases)
    v_data(i,:) = str2num(readings); %make a variable that is a matriix of all teh channels
    CO2_span_VDC(i) = v_data(i,4);
    disp(['VDC CO2 span = ' num2str(CO2_span_VDC(i))])
end
Average_CO2_span_VDC = mean(CO2_span_VDC);
disp(['New VDC CO2 span = ' num2str(Average_CO2_span_VDC) ' V. Previous value was ' num2str(prev_CO2_span_VDC) ' V.' 'If there is a big diffeerence maybe someting is wrong']);
save(FileName, 'Average_CO2_span_VDC', '-append')

end

function all_done(~,~,v34970A)
%Close and delete the objects
fclose(v34970A);
%fclose(loadcell)
delete(v34970A);
%delete(loadcell);
clear v34970A;
%clear loadcell
close all
clc
end