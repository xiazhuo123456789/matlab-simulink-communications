function mdl = build_model(c,outDir)
% Build a flat real-passband 16QAM model from visible Simulink primitives.

mdl = 'msc_16qam';
target = fullfile(outDir,[mdl '.slx']);
if exist(target,'file')
    error('Model already exists. Choose a new output directory.');
end

load_system('simulink');
new_system(mdl);

w = get_param(mdl,'ModelWorkspace');
names = fieldnames(c);
for n = 1:numel(names)
    assignin(w,names{n},c.(names{n}));
end
set_param(mdl,'SolverType','Fixed-step','Solver','FixedStepDiscrete', ...
    'FixedStep','1/fs','StopTime','Nsym/Rs','StartTime','0', ...
    'ReturnWorkspaceOutputs','on','SaveTime','on','TimeSaveName','tout', ...
    'SaveOutput','off','SignalLogging','off', ...
    'Description','Flat real-passband Gray 16QAM using visible standard Simulink blocks.');

add(mdl,'BitFrames','simulink/Sources/From Workspace',[40 380 170 430], ...
    'VariableName','txData','SampleTime','1/Rs','Interpolate','off', ...
    'OutputAfterFinalValue','Holding final value');
add(mdl,'Split4Bits','simulink/Signal Routing/Demux',[245 370 250 440],'Outputs','4');
wire(mdl,'BitFrames/1','Split4Bits/1');

% Gray-code two-bit indices to the normalized I/Q amplitudes.
for axisIndex = 1:2
    ax = 'I'; y = 245;
    if axisIndex == 2, ax = 'Q'; y = 650; end
    msbPort = num2str((axisIndex-1)*2+1);
    lsbPort = num2str((axisIndex-1)*2+2);
    add(mdl,[ax '_MSB_x2'],'simulink/Math Operations/Gain', ...
        [390 y 455 y+40],'Gain','2');
    add(mdl,[ax '_BinaryIndex'],'simulink/Math Operations/Sum', ...
        [535 y 575 y+40],'Inputs','++');
    add(mdl,[ax '_GrayAmplitude'],'simulink/Lookup Tables/1-D Lookup Table', ...
        [650 y-5 800 y+45],'BreakpointsForDimension1','0:3', ...
        'Table','levels(grayTable+1)','InterpMethod','Flat');
    add(mdl,[ax '_Normalize'],'simulink/Math Operations/Gain', ...
        [870 y 945 y+40],'Gain','1/sqrt(10)');
    wire(mdl,['Split4Bits/' msbPort],[ax '_MSB_x2/1']);
    wire(mdl,[ax '_MSB_x2/1'],[ax '_BinaryIndex/1']);
    wire(mdl,['Split4Bits/' lsbPort],[ax '_BinaryIndex/2']);
    wire(mdl,[ax '_BinaryIndex/1'],[ax '_GrayAmplitude/1']);
    wire(mdl,[ax '_GrayAmplitude/1'],[ax '_Normalize/1']);
end

% Real carrier modulator: s(t) = I*cos(2*pi*fc*t) - Q*sin(2*pi*fc*t).
addCarrier(mdl,'CosCarrier',[1080 205 1185 245],'pi/2');
addCarrier(mdl,'SinCarrier',[1080 700 1185 740],'0');
add(mdl,'I_CarrierProduct','simulink/Math Operations/Product',[1260 260 1300 300]);
add(mdl,'Q_CarrierProduct','simulink/Math Operations/Product',[1260 670 1300 710]);
add(mdl,'PassbandSum','simulink/Math Operations/Sum',[1410 445 1450 495],'Inputs','+-');
wire(mdl,'I_Normalize/1','I_CarrierProduct/1');
wire(mdl,'CosCarrier/1','I_CarrierProduct/2');
wire(mdl,'Q_Normalize/1','Q_CarrierProduct/1');
wire(mdl,'SinCarrier/1','Q_CarrierProduct/2');
wire(mdl,'I_CarrierProduct/1','PassbandSum/1');
wire(mdl,'Q_CarrierProduct/1','PassbandSum/2');

% Real AWGN channel, calibrated for Eb/N0 with sps real samples per symbol.
add(mdl,'UnitGaussianNoise','simulink/Sources/Random Number',[1420 820 1535 870], ...
    'Mean','0','Variance','1','Seed','noiseSeed','SampleTime','1/fs');
add(mdl,'NoiseScale','simulink/Math Operations/Gain',[1600 825 1715 865], ...
    'Gain','NoiseEnable*sqrt(sps/(4*k*10^(EbN0/10)))');
add(mdl,'ChannelSum','simulink/Math Operations/Sum',[1810 445 1850 495],'Inputs','++');
wire(mdl,'UnitGaussianNoise/1','NoiseScale/1');
wire(mdl,'PassbandSum/1','ChannelSum/1');
wire(mdl,'NoiseScale/1','ChannelSum/2');

% Coherent product detectors followed by 50-sample integrate-and-dump FIRs.
addCarrier(mdl,'LocalCosCarrier',[1940 210 2045 250],'pi/2');
addCarrier(mdl,'LocalSinCarrier',[1940 700 2045 740],'0');
add(mdl,'I_Mixer','simulink/Math Operations/Product',[2120 265 2160 305]);
add(mdl,'Q_Mixer','simulink/Math Operations/Product',[2120 675 2160 715]);
add(mdl,'I_DemodGain','simulink/Math Operations/Gain',[2230 265 2290 305],'Gain','2');
add(mdl,'Q_DemodGain','simulink/Math Operations/Gain',[2230 675 2290 715],'Gain','-2');
add(mdl,'I_MatchedFIR','simulink/Discrete/Discrete FIR Filter',[2370 255 2525 315], ...
    'Coefficients','ones(1,sps)/sps','SampleTime','-1', ...
    'InputProcessing','Elements as channels (sample based)');
add(mdl,'Q_MatchedFIR','simulink/Discrete/Discrete FIR Filter',[2370 665 2525 725], ...
    'Coefficients','ones(1,sps)/sps','SampleTime','-1', ...
    'InputProcessing','Elements as channels (sample based)');
wire(mdl,'ChannelSum/1','I_Mixer/1');
wire(mdl,'ChannelSum/1','Q_Mixer/1');
wire(mdl,'LocalCosCarrier/1','I_Mixer/2');
wire(mdl,'LocalSinCarrier/1','Q_Mixer/2');
wire(mdl,'I_Mixer/1','I_DemodGain/1');
wire(mdl,'Q_Mixer/1','Q_DemodGain/1');
wire(mdl,'I_DemodGain/1','I_MatchedFIR/1');
wire(mdl,'Q_DemodGain/1','Q_MatchedFIR/1');

% Three slicer thresholds per axis, then Gray decode lookup tables.
for axisIndex = 1:2
    ax = 'I'; y = 155;
    if axisIndex == 2, ax = 'Q'; y = 700; end
    src = [ax '_MatchedFIR/1'];
    for j = 1:3
        yy = y + (j-1)*90;
        thresholdName = [ax '_ThresholdValue' num2str(j)];
        compareName = [ax '_Compare' num2str(j)];
        convertName = [ax '_CompareDouble' num2str(j)];
        add(mdl,thresholdName,'simulink/Sources/Constant', ...
            [2670 yy+32 2745 yy+62],'Value',['thresholds(' num2str(j) ')']);
        add(mdl,compareName,'simulink/Logic and Bit Operations/Relational Operator', ...
            [2800 yy 2850 yy+55],'Operator','>=','OutDataTypeStr','boolean');
        add(mdl,convertName,'simulink/Signal Attributes/Data Type Conversion', ...
            [2910 yy+5 3000 yy+45],'OutDataTypeStr','double');
        wire(mdl,src,[compareName '/1']);
        wire(mdl,[thresholdName '/1'],[compareName '/2']);
        wire(mdl,[compareName '/1'],[convertName '/1']);
    end
    sumName = [ax '_LevelIndex'];
    add(mdl,sumName,'simulink/Math Operations/Sum',[3070 y+80 3110 y+125],'Inputs','+++');
    for j = 1:3, wire(mdl,[ax '_CompareDouble' num2str(j) '/1'],[sumName '/' num2str(j)]); end
    add(mdl,[ax '_GrayMSB'],'simulink/Lookup Tables/1-D Lookup Table', ...
        [3190 y+10 3320 y+55],'BreakpointsForDimension1','0:3','Table','grayMSB','InterpMethod','Flat');
    add(mdl,[ax '_GrayLSB'],'simulink/Lookup Tables/1-D Lookup Table', ...
        [3190 y+165 3320 y+210],'BreakpointsForDimension1','0:3','Table','grayLSB','InterpMethod','Flat');
    wire(mdl,[sumName '/1'],[ax '_GrayMSB/1']);
    wire(mdl,[sumName '/1'],[ax '_GrayLSB/1']);
end
add(mdl,'RecoveredBitMux','simulink/Signal Routing/Mux',[3440 335 3445 535],'Inputs','4');
wire(mdl,'I_GrayMSB/1','RecoveredBitMux/1');
wire(mdl,'I_GrayLSB/1','RecoveredBitMux/2');
wire(mdl,'Q_GrayMSB/1','RecoveredBitMux/3');
wire(mdl,'Q_GrayLSB/1','RecoveredBitMux/4');

% Scopes and logged signals keep the model inspectable after each run.
add(mdl,'CarrierScope','simulink/Sinks/Scope',[1600 90 1710 155],'NumInputPorts','2');
wire(mdl,'PassbandSum/1','CarrierScope/1');
wire(mdl,'ChannelSum/1','CarrierScope/2');
add(mdl,'RecoveredIQScope','simulink/Sinks/Scope',[2580 445 2690 510],'NumInputPorts','2');
wire(mdl,'I_MatchedFIR/1','RecoveredIQScope/1');
wire(mdl,'Q_MatchedFIR/1','RecoveredIQScope/2');
for scopeName = {'CarrierScope','RecoveredIQScope'}
    sc = get_param([mdl '/' scopeName{1}],'ScopeConfiguration');
    sc.TimeSpan = '0.04';
end
addLog(mdl,'TxBitsLog','txBits','BitFrames/1',[50 975 165 1010]);
addLog(mdl,'TxILog','txI','I_Normalize/1',[700 70 815 105]);
addLog(mdl,'TxQLog','txQ','Q_Normalize/1',[700 1020 815 1055]);
addLog(mdl,'PassbandLog','passband','PassbandSum/1',[1490 570 1605 605]);
addLog(mdl,'RxILog','rxI','I_MatchedFIR/1',[2410 115 2525 150]);
addLog(mdl,'RxQLog','rxQ','Q_MatchedFIR/1',[2410 895 2525 930]);
addLog(mdl,'RxBitsLog','rxBits','RecoveredBitMux/1',[3500 405 3615 440]);

set_param(mdl,'ZoomFactor','FitSystem');
set_param(mdl,'SimulationCommand','update');
save_system(mdl,target);
bdclose(mdl);
load_system(target);
fprintf('BUILT %s, visible primitive blocks=%d\n',target,numel(find_system(mdl,'Type','Block'))-1);
end

function add(parent,name,libraryBlock,position,varargin)
add_block(libraryBlock,[parent '/' name],'Position',position,varargin{:});
end

function wire(parent,source,destination)
add_line(parent,source,destination,'autorouting','on');
end

function addCarrier(parent,name,position,phase)
add(parent,name,'simulink/Sources/Sine Wave',position, ...
    'Amplitude','1','Frequency','2*pi*fc','Phase',phase,'SampleTime','1/fs');
end

function addLog(model,name,variable,source,position)
add(model,name,'simulink/Sinks/To Workspace',position, ...
    'VariableName',variable,'SaveFormat','Timeseries', ...
    'MaxDataPoints','inf','Decimation','1');
wire(model,source,[name '/1']);
end
