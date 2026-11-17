function make_figures(out, P, fdir)
% MAKE_FIGURES  Figures 1-7 of Section 5 (EPS + PNG in fdir).

t  = (0:P.n_steps)' * P.dt;
X  = out.X_real;
tc = t(2:end);                      % decision-step times (coverage ends)
lw = 1.2;

%% Figure 1: realized path
f = figure('Visible','off');
plot(t, X, 'LineWidth', lw); grid on;
xlabel('Time (years)'); ylabel('Claims amount'); xlim([0 P.T]);
save_fig(f, fdir, 'Figure1_RealPath', [6.0 3.2]);

%% Figure 2: realized path with VaR / TVaR at three levels
f = figure('Visible','off', 'Position', [100 100 1100 800]);
labs = {'95%', '97.5%', '99%'};
for a = 1:3
    subplot(2,2,a);
    plot(tc, X(2:end), 'k', tc, out.C_SL.q(:,a), 'b', tc, out.C_SL.TX(:,a), 'r--', 'LineWidth', 1.2);
    grid on; xlabel('Time (years)'); ylabel('Claims');
    title(['Confidence ' labs{a}]); xlim([0 P.T]); legend('Real path','VaR','TVaR','Location','northwest');
end
subplot(2,2,4); hold on;
cl = {'b','g','r'};
for a = 1:3
    plot(tc, out.C_SL.q(:,a),  cl{a}, 'LineWidth', 1.2);
    plot(tc, out.C_SL.TX(:,a), [cl{a} '--'], 'LineWidth', 1.2);
end
hold off; grid on; xlabel('Time (years)'); ylabel('Risk measures');
title('All risk measures');
xlim([0 P.T]); legend('VaR 95','TVaR 95','VaR 97.5','TVaR 97.5','VaR 99','TVaR 99','Location','northwest');
save_fig(f, fdir, 'Figure_RiskMeasures_AllLevels', [7.0 5.6]);

%% Figure 3: insurer RAROC vs retention (VaR 95%)
KI = squeeze(out.SL.KI(1,1,:));  RI = out.SL.PI(:) ./ KI;
RI(KI <= 1e-6*max(abs(out.SL.PI(:)),1)) = NaN;   % undefined: riskless layer
f = figure('Visible','off');
semilogy(out.SL.k, RI, 'LineWidth', lw); grid on;
xlabel('Retention level k'); ylabel('RAROC_I (log scale)');
save_fig(f, fdir, 'Figure_Insurer_RAROC', [6.0 3.2]);

%% Figure 4: Nash product and profits, stop-loss
k  = out.SL.k;  N = out.SL.PI .* out.SL.PR;
ks = k(out.SL.strat{1,1}(4).idx);
f = figure('Visible','off', 'Position', [100 100 1100 420]);
subplot(1,2,1); plot(k, N/max(N), 'LineWidth', lw); hold on;
xline_(ks); hold off; grid on;
xlabel('Retention level k'); ylabel('Normalized Nash product');
title(sprintf('Nash product, k^* = %.2f', ks));
subplot(1,2,2); plot(k, out.SL.PI, k, out.SL.PR, 'LineWidth', lw); hold on;
xline_(ks); hold off; grid on;
xlabel('Retention level k'); ylabel('Profit'); legend('Insurer','Reinsurer','Location','northeast');
title('Profits');
save_fig(f, fdir, 'Figure_NashProduct_ProfitDistribution', [7.0 2.9]);

%% Figure 5: stop-loss cash flows at k*
f = figure('Visible','off', 'Position', [100 100 1100 420]);
CI = min(X, ks);  CR = max(X - ks, 0);
EIk   = out.C_SL.EX - out.C_SL.SL(:, out.SL.strat{1,1}(4).idx);   % E[min(X,k*)] per step
PremI = (1 + P.theta) * [EIk(1); EIk];   % t = 0 carries the first step's premium
subplot(1,2,1);
plot(t, X, 'k', t, CI, 'b', t, CR, 'r', t, PremI, 'g--', 'LineWidth', 1.1); grid on;
yline_(ks); xlabel('Time (years)'); ylabel('Amount');
xlim([0 P.T]); lg = legend('X(t)','C_I(t)','C_R(t)','\Pi_{I,t}','k^*','Location','southoutside','Orientation','horizontal'); title('Full year');
subplot(1,2,2); id = t <= 0.3;
plot(t(id), X(id), 'k', t(id), CI(id), 'b', t(id), CR(id), 'r', t(id), PremI(id), 'g--', 'LineWidth', 1.1);
grid on; yline_(ks); xlim([0 0.3]); xlabel('Time (years)'); title('First 0.3 years');
center_legend(lg);
save_fig(f, fdir, 'Figure7_StopLoss_TimeSeries', [7.0 3.4]);

%% Figure 6: limited stop-loss Nash surface
G  = numel(out.LSL.k);  NL = out.LSL.PI .* out.LSL.PR;
[ik, im] = ind2sub([G G], out.LSL.strat{1,1}(4).idx);
kL = out.LSL.k(ik);  mL = out.LSL.m(im);
NLn = NL / max(NL(:));
f = figure('Visible','off', 'Position', [100 100 1100 800]);
[MM, KK] = meshgrid(out.LSL.m, out.LSL.k);
step = max(1, floor(G/100));
sub = 1:step:G;
subplot(2,2,1); surf(MM(sub,sub), KK(sub,sub), NLn(sub,sub), 'EdgeColor','none');
xlabel('m'); ylabel('k'); zlabel('Nash product'); title('(a) Surface'); view(45,30);
subplot(2,2,2); contourf(MM(sub,sub), KK(sub,sub), NLn(sub,sub), 20); hold on;
plot(mL, kL, 'rp', 'MarkerSize', 14, 'MarkerFaceColor','r'); hold off;
xlabel('m'); ylabel('k'); title('(b) Contour'); colorbar;
subplot(2,2,3); plot(out.LSL.k, NLn(:,im), 'LineWidth', lw); grid on;
xlabel('k'); title(sprintf('(c) Section at m^* = %.2f', mL));
subplot(2,2,4); plot(out.LSL.m, NLn(ik,:), 'LineWidth', lw); grid on;
xlabel('m'); title(sprintf('(d) Section at k^* = %.2f', kL));
save_fig(f, fdir, 'Figure5_Limited_NashSurface', [7.0 5.6]);

%% Figure 7: limited stop-loss cash flows at (k*, m*)
CI = min(X, kL) + max(X - mL, 0);  CR = min(mL - kL, max(X - kL, 0));
f = figure('Visible','off', 'Position', [100 100 1100 420]);
subplot(1,2,1); plot(t, X, 'k', t, CI, 'b', t, CR, 'r', 'LineWidth', 1.1); grid on;
yline_(kL); yline_(mL, 'k-.'); xlabel('Time (years)'); ylabel('Amount');
xlim([0 P.T]); lg = legend('X(t)','C_I(t)','C_R(t)','k^*','m^*','Location','southoutside','Orientation','horizontal'); title('Full year');
subplot(1,2,2); id = t <= 0.3;
plot(t(id), X(id), 'k', t(id), CI(id), 'b', t(id), CR(id), 'r', 'LineWidth', 1.1); grid on;
xlim([0 0.3]); xlabel('Time (years)'); title('First 0.3 years');
center_legend(lg);
save_fig(f, fdir, 'Figure6_Limited_TimeSeries', [7.0 3.4]);

fprintf('Figures written to %s\n', fdir);
end

function save_fig(f, fdir, name, wh)
% Publication output: fixed size in inches (wh = [width height]), 10 pt
% fonts, tight bounding box. Include in LaTeX at about width = wh(1) in.
set(findall(f, '-property', 'FontSize'), 'FontSize', 10);
set(findall(f, 'Type', 'legend'), 'FontSize', 8);
set(findall(f, 'Type', 'axes'), 'TitleFontSizeMultiplier', 1, 'LabelFontSizeMultiplier', 1);
set(f, 'Units', 'inches', 'Position', [1 1 wh], 'Color', 'w');
set(f, 'PaperUnits', 'inches', 'PaperSize', wh, 'PaperPosition', [0 0 wh]);
if exist('exportgraphics', 'file')          % MATLAB R2020a+: tight crop
    % The 3D surface (Figure 5) has thousands of patches: store it as a
    % high-resolution image inside the EPS; all other figures stay vector.
    if strcmp(name, 'Figure5_Limited_NashSurface'), ct = 'image'; else, ct = 'vector'; end
    ws = warning('off', 'all');             % silence the vector-content notice
    exportgraphics(f, fullfile(fdir, [name '.eps']), 'ContentType', ct, 'Resolution', 600);
    warning(ws);
    exportgraphics(f, fullfile(fdir, [name '.png']), 'Resolution', 300);
else                                        % Octave / older MATLAB
    print(f, '-depsc', fullfile(fdir, [name '.eps']));
    print(f, '-dpng', '-r300', fullfile(fdir, [name '.png']));
end
close(f);
end

function xline_(x)   % portable vertical line (works in MATLAB and Octave)
yl = ylim; hold on; plot([x x], yl, 'k:', 'LineWidth', 1.2); hold off; ylim(yl);
end

function yline_(y, style)
if nargin < 2, style = 'k:'; end
xl = xlim; hold on; plot(xl, [y y], style, 'LineWidth', 1.0); hold off; xlim(xl);
end

function center_legend(lg)
% Place a horizontal legend centred across the full figure width, so it is
% not clipped when it is wider than the left panel, and give both panels
% the same vertical extent so the legend does not overlap any axis label.
f  = ancestor(lg, 'figure');
ax = findobj(f, 'Type', 'axes');
set(ax, 'Units', 'normalized');  set(lg, 'Units', 'normalized');
P  = cell2mat(get(ax, 'Position'));
y0 = max(P(:,2));  y1 = min(P(:,2) + P(:,4));
for i = 1:numel(ax)
    p = P(i,:);  p(2) = y0;  p(4) = y1 - y0;  set(ax(i), 'Position', p);
end
pos = get(lg, 'Position');
pos(1) = 0.5 - pos(3)/2;  pos(2) = 0.01;
set(lg, 'Position', pos);
end
