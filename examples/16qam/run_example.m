% Portable entry point. Called by scripts/workflow.py or MATLAB Run button.
sourceDir = fileparts(mfilename('fullpath'));
configFile = getenv('MSC_CONFIG_FILE');
if isempty(configFile), configFile = fullfile(sourceDir,'config.json'); end
cfg = jsondecode(fileread(configFile));
outputDir = getenv('MSC_OUTPUT_DIR');
if isempty(outputDir)
    outputDir = fullfile(sourceDir,'results',char(datetime('now','Format','yyyyMMdd_HHmmss_SSS')));
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end
run_adapter(cfg,outputDir);

function run_adapter(cfg,outputDir)
assert(license('test','Simulink')==1,'Simulink license is required.');
p=cfg.parameters;
validateattributes(p.bits,{'numeric'},{'scalar','integer','>=',64,'<=',4000000});
assert(mod(p.bits,4)==0,'Bit count must be a multiple of 4.');
validateattributes(p.ebN0Db,{'numeric'},{'scalar','finite','>=',-20,'<=',60});
validateattributes(p.sweepDb,{'numeric'},{'vector','finite','>=',-20,'<=',60,'numel',numel(p.sweepDb)});
assert(numel(p.sweepDb)>=2 && all(diff(p.sweepDb)>0),'Sweep must contain at least two increasing points.');
validateattributes(p.bitSeed,{'numeric'},{'scalar','integer','nonnegative','<=',2^32-1});
validateattributes(p.noiseSeed,{'numeric'},{'scalar','integer','positive','<=',2^32-1});
c.Nbits=p.bits; c.k=4; c.Nsym=c.Nbits/c.k;
c.Rs=200; c.fc=2000; c.fs=10000; c.sps=c.fs/c.Rs;
c.EbN0=p.ebN0Db; c.NoiseEnable=1;
c.levels=[-3 -1 1 3]; c.grayTable=[0 1 3 2];
c.grayMSB=[0 0 1 1]; c.grayLSB=[0 1 1 0]; c.thresholds=[-2 0 2]/sqrt(10);
c.noiseSeed=p.noiseSeed; c.bitSeed=p.bitSeed;
rs=RandStream('mt19937ar','Seed',c.bitSeed);
c.bits=randi(rs,[0 1],c.Nbits,1); c.bitFrames=reshape(c.bits,c.k,[]).';
c.txData=[(0:c.Nsym-1)'/c.Rs c.bitFrames];
c.txData(end+1,:)=[c.Nsym/c.Rs c.bitFrames(end,:)];
% Keep generated Simulink cache outside the source tree.
oldCache=Simulink.fileGenControl('getConfig');
cacheCleanup=onCleanup(@() Simulink.fileGenControl('setConfig','config',oldCache));
Simulink.fileGenControl('set','CacheFolder',fullfile(outputDir,'cache'), ...
    'CodeGenFolder',fullfile(outputDir,'codegen'),'createDir',true);
mdl=build_model(c,outputDir);
modelCleanup=onCleanup(@() close_system(mdl,0));
fprintf('Noiseless verification...\n');
clean=measure(run_one(mdl,c.EbN0,0),c);
assert(clean.bitErrors==0,'Noiseless test failed; do not trust noisy measurements.');
fprintf('Baseline Eb/N0=%g dB...\n',c.EbN0);
out=run_one(mdl,c.EbN0,1); baseline=measure(out,c);
eb=p.sweepDb(:); count=numel(eb);
BER=zeros(count,1); SER=BER; BitErrors=BER; SymbolErrors=BER;
for k=1:count
    fprintf('Sweep %d/%d: %g dB\n',k,count,eb(k));
    measured=measure(run_one(mdl,eb(k),1),c);
    BER(k)=measured.BER; SER(k)=measured.SER;
    BitErrors(k)=measured.bitErrors; SymbolErrors(k)=measured.symbolErrors;
end
% One-sided binomial 95% zero-event bound; bit independence is approximate.
ZeroErrorUpper95=repmat(1-0.05^(1/c.Nbits),count,1);
curve=table(eb,BER,SER,BitErrors,SymbolErrors,ZeroErrorUpper95, ...
    'VariableNames',{'EbN0_dB','BER','SER','BitErrors','SymbolErrors','ZeroErrorUpper95'});
plot_results(out,baseline,curve,c.EbN0,c,outputDir);
print(['-s' mdl],'-dpng','-r150',fullfile(outputDir,'model.png'));
writetable(curve,fullfile(outputDir,'ber_results.csv'));
save(fullfile(outputDir,'results.mat'),'out','baseline','curve','c');
metrics=baseline; metrics.noiselessBitErrors=clean.bitErrors;
metrics.ebN0Db=c.EbN0; metrics.matlabVersion=version;
metrics.simulinkVersion=ver('simulink');
fid=fopen(fullfile(outputDir,'metrics.json'),'w'); assert(fid>=0);
fprintf(fid,'%s',jsonencode(metrics)); fclose(fid);
fid=fopen(fullfile(outputDir,'report.md'),'w'); assert(fid>=0);
fprintf(fid,'# 16QAM simulation report\n\nMATLAB %s\n\n',version);
fprintf(fid,'Eb/N0: %g dB; %d bits; %d symbols.\n\n',c.EbN0,c.Nbits,c.Nsym);
fprintf(fid,'BER = %d/%d = %.8g. SER = %d/%d = %.8g.\n\n', ...
    baseline.bitErrors,c.Nbits,baseline.BER,baseline.symbolErrors,c.Nsym,baseline.SER);
fprintf(fid,'Noiseless verification: %d bit errors.\n\n',clean.bitErrors);
fprintf(fid,'Known timing, rectangular pulse shaping, coherent carrier; no timing/carrier recovery loop.\n');
fprintf(fid,'Zero-event BER bounds assume independent trials approximately; bits within a QAM symbol can be correlated.\n');
fclose(fid);
fprintf('COMPLETE: %d bits, BER=%g, SER=%g\n',c.Nbits,baseline.BER,baseline.SER);
end

function out=run_one(mdl,eb,noise)
input=Simulink.SimulationInput(mdl);
input=input.setVariable('EbN0',eb,'Workspace',mdl);
input=input.setVariable('NoiseEnable',noise,'Workspace',mdl);
out=sim(input);
end

function r=measure(out,c)
tx=reshape(out.txBits.Data,numel(out.txBits.Time),[]); tx=tx(1:c.Nsym,:);
rx=reshape(out.rxBits.Data,numel(out.rxBits.Time),[]);
idx=c.sps:c.sps:c.Nsym*c.sps; rx=rx(idx,:);
assert(isequal(size(tx),size(rx)),'Tx/Rx alignment mismatch.');
assert(all(isfinite(out.rxI.Data(:))) && all(isfinite(out.rxQ.Data(:))));
assert(max(abs(out.rxI.Time(idx)-((1:c.Nsym)'/c.Rs-1/c.fs)))<1e-8,'Sampling time mismatch.');
% Independently decide using matched-filter amplitudes to check model decoding.
i=sum(out.rxI.Data(idx)>=c.thresholds,2);
q=sum(out.rxQ.Data(idx)>=c.thresholds,2);
expected=[reshape(c.grayMSB(i+1),[],1),reshape(c.grayLSB(i+1),[],1), ...
    reshape(c.grayMSB(q+1),[],1),reshape(c.grayLSB(q+1),[],1)];
assert(isequal(expected,rx),'Model decisions disagree with independent Gray decoder.');
errors=tx~=rx;
r.bitErrors=sum(errors(:)); r.symbolErrors=sum(any(errors,2));
r.bits=c.Nbits; r.symbols=c.Nsym;
r.BER=r.bitErrors/r.bits; r.SER=r.symbolErrors/r.symbols;
end
