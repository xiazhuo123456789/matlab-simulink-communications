function plot_results(out,r,curve,baselineEb,c,d)
% Eight separate figures, all drawn from actual simulation outputs.
n=r.symbols; samples=c.sps:c.sps:n*c.sps;
tx=reshape(out.txBits.Data,numel(out.txBits.Time),[]); tx=tx(1:n,:);
rx=reshape(out.rxBits.Data,numel(out.rxBits.Time),[]); rx=rx(samples,:);
bits=reshape(tx.',[],1); recovered=reshape(rx.',[],1);
assert(sum(bits~=recovered)==r.bitErrors,'Bit alignment mismatch');
txI=out.txI.Data(1:n); txQ=out.txQ.Data(1:n);
rxI=out.rxI.Data(samples); rxQ=out.rxQ.Data(samples);

f=chart(1,'原始二进制比特流');
shown=min(64,numel(bits));
stairs((0:shown)/(c.Rs*c.k),[bits(1:shown);bits(shown)],'LineWidth',1.4);
xlabel('时间 / s');ylabel('比特');ylim([-.2 1.2]);grid on;
title('原始二进制比特流：800 bit/s，每个符号 4 bit');
finish(f,'01_input_bits');

f=chart(2,'发送 I-Q 基带波形'); tiledlayout(2,1,'TileSpacing','compact');
for ax=1:2
 nexttile; if ax==1, y=txI; name='I'; else,y=txQ;name='Q';end
 stairs((0:8)/c.Rs,y(1:9),'LineWidth',1.5);grid on;xlim([0 .04]);ylim([-1.15 1.15]);
 ylabel([name ' 路幅度']);xlabel('时间 / s');title([name ' 路 Gray 四电平（已归一化）']);
end
finish(f,'02_tx_iq');

f=chart(3,'16QAM 已调载波');idx=out.passband.Time<=.04;
plot(out.passband.Time(idx),out.passband.Data(idx),'LineWidth',1.1);grid on;
xlim([0 .04]);xlabel('时间 / s');ylabel('s(t)');
title('16QAM 实载波：2 kHz，200 Baud，s(t)=I cos(2πf_ct)-Q sin(2πf_ct)');
finish(f,'03_carrier');

f=chart(4,'发送端理想星座');
scatter(txI,txQ,38,'filled');constellationAxes;
title('发送端 16QAM 理想星座：16 个点，每符号 4 bit');
finish(f,'04_tx_constellation');

f=chart(5,'接收端带噪星座');
scatter(rxI,rxQ,9,[.12 .44 .75],'filled');hold on;
[a,b]=meshgrid(c.levels/sqrt(10));plot(a(:),b(:),'rx','MarkerSize',9,'LineWidth',1.4);
for threshold=c.thresholds
 xline(threshold,':','Color',[.5 .5 .5]);yline(threshold,':','Color',[.5 .5 .5]);
end
constellationAxes;title(sprintf('接收端：Eb/N0=%g dB，BER=%.5f，SER=%.4f',baselineEb,r.BER,r.SER));
legend('接收采样点','理想点','Location','southoutside');
finish(f,'05_rx_constellation');

f=chart(6,'解调 I-Q 与发送符号对比');tiledlayout(2,1,'TileSpacing','compact');
for ax=1:2
 nexttile;if ax==1, a=txI;b=rxI;name='I';else,a=txQ;b=rxQ;name='Q';end
 m=min(40,n);stairs(1:m,a(1:m),'LineWidth',1.2);hold on;
 plot(1:m,b(1:m),'o','MarkerSize',4);grid on;xlabel('符号序号');ylabel([name ' 路幅度']);
 title([name ' 路：发送电平与匹配滤波后的符号末采样（已对齐）']);legend('发送','接收采样','Location','best');
end
finish(f,'06_recovered_iq');

f=chart(7,'发送与恢复比特对比');tiledlayout(3,1,'TileSpacing','compact');
first=find(bits~=recovered,1);if isempty(first),startBit=1;else,startBit=max(1,first-24);end
lastBit=min(numel(bits),startBit+63);section=startBit:lastBit;
nexttile;stairs(section,bits(section),'LineWidth',1.4);ylim([-.2 1.2]);grid on;ylabel('发送比特');
title('发送/恢复比特已按符号末采样对齐；有误码时展示首个误码附近');
nexttile;stairs(section,recovered(section),'LineWidth',1.4);ylim([-.2 1.2]);grid on;ylabel('恢复比特');xlabel('比特序号');
nexttile;stem(find(bits~=recovered),ones(r.bitErrors,1),'r.');grid on;xlim([1 numel(bits)]);ylim([0 1.3]);
xlabel('整个仿真中的比特序号');ylabel('误码位置');title(sprintf('全程 %d 个错误 / %d bit，BER=%g',r.bitErrors,r.bits,r.BER));
finish(f,'07_recovered_bits');

if isempty(curve),return;end
f=chart(8,'BER-SER 误码率曲线');e=linspace(min(curve.EbN0_dB),max(curve.EbN0_dB),401);
h1=semilogy(e,3/8*erfc(sqrt(.4*10.^(e/10))),'k-','LineWidth',1.5);hold on;
ber=curve.BER;ser=curve.SER;ber(ber==0)=NaN;ser(ser==0)=NaN;
h2=semilogy(curve.EbN0_dB,ber,'bo-','LineWidth',1.3);
h3=semilogy(curve.EbN0_dB,ser,'rs-','LineWidth',1.3);
z=curve.BitErrors==0;h4=semilogy(curve.EbN0_dB(z),curve.ZeroErrorUpper95(z),'bv','MarkerSize',8,'LineWidth',1.3);
grid on;ylim([1e-5 1]);xlim([min(curve.EbN0_dB) max(curve.EbN0_dB)]);xlabel('Eb/N0 / dB');ylabel('误码率（对数刻度）');
legend([h1 h2 h3 h4],{'理论 BER 近似','仿真 BER','仿真 SER','零观测误码：95% BER 上界'},'Location','southwest');
title({sprintf('16QAM: Eb/N0 %g to %g dB, %d bits/point',min(curve.EbN0_dB),max(curve.EbN0_dB),c.Nbits),'Zero observed errors do not imply zero true BER'});
finish(f,'08_ber_ser');

 function finish(fig,stemName)
  savefig(fig,fullfile(d,[stemName '.fig']));
  exportgraphics(fig,fullfile(d,[stemName '.png']),'Resolution',160); close(fig);
 end
end
function f=chart(number,label)
tag=sprintf('MSC16Figure%02d',number);f=findall(groot,'Type','figure','Tag',tag);
if isempty(f)
 f=figure('Tag',tag,'NumberTitle','off','Color','w','Visible','off','Position',[40+24*number 60+15*number 1000 650]);
else
 f=f(1);clf(f);
end
set(f,'Name',sprintf('%02d - %s',number,label),'Visible','off');
end
function constellationAxes
axis equal;grid on;xlim([-1.5 1.5]);ylim([-1.5 1.5]);xlabel('I（同相）');ylabel('Q（正交）');
end
