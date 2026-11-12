function generate_tables(out, P, fname)
% GENERATE_TABLES  Writes every numerical table of Section 5 as LaTeX
% (same column layout and labels as the manuscript) and echoes them to the
% console.

fid = fopen(fname, 'w');
A   = numel(P.alpha_levels);
lev = {'95.0\%', '97.5\%', '99.0\%'};

%% Table 3: risk-measure summary
w(fid, '%% ---- Table: Summary statistics for risk measures ----\n');
w(fid, '\\begin{tabular}{|c|c|c|c|}\n\\hline\n');
w(fid, '\\textbf{Confidence Level} & \\textbf{Average VaR} & \\textbf{Average TVaR} & \\textbf{TVaR/VaR Ratio} \\\\\n\\hline\n');
for a = 1:A
    v = mean(out.C_SL.q(:,a));  t = mean(out.C_SL.TX(:,a));
    w(fid, '%s & %.1f & %.1f & %.2f \\\\\n\\hline\n', lev{a}, v, t, t/v);
end
w(fid, '\\end{tabular}\n\n');

%% Tables 4 / 5: stop-loss and limited stop-loss strategies (VaR and TVaR)
tags = {'VaR', 'TVaR'};
for typ = 1:2
    w(fid, '%% ---- Table: Stop-loss strategies (%s-based) ----\n', tags{typ});
    w(fid, '\\begin{tabular}{|c|l|l|l|l|l|l|}\n\\hline\n');
    w(fid, '\\textbf{Confidence} & \\textbf{Strategy} & \\textbf{Optimal $k$} & \\textbf{RAROC$_I$} & \\textbf{RAROC$_R$} & \\textbf{Profit$_I$} & \\textbf{Profit$_R$} \\\\\n\\hline\n');
    for a = 1:A
        R = out.SL.strat{typ,a};
        for s = 1:5
            if s == 1, c1 = sprintf('\\multirow{5}{*}{%s}', lev{a}); else, c1 = ''; end
            if ~R(s).feasible
                w(fid, '%s & %s & \\multicolumn{5}{c|}{no feasible contract} \\\\\n', c1, R(s).name);
            elseif s == 5   % P_I + P_R = theta*E[X] for every k: indeterminate
                w(fid, '%s & %s & any & -- & -- & \\multicolumn{2}{c|}{$P_I+P_R = %.2f$} \\\\\n', ...
                  c1, R(s).name, R(s).PI + R(s).PR);
            else
            w(fid, '%s & %s & %.2f & %s & %s & %.2f & %.2f \\\\\n', c1, R(s).name, ...
              out.SL.k(R(s).idx), num(R(s).RI), num(R(s).RR), R(s).PI, R(s).PR);
            end
        end
        w(fid, '\\hline\n');
    end
    w(fid, '\\end{tabular}\n\n');

    w(fid, '%% ---- Table: Limited stop-loss strategies (%s-based) ----\n', tags{typ});
    w(fid, '\\begin{tabular}{|c|l|l|l|l|l|l|l|}\n\\hline\n');
    w(fid, '\\textbf{Confidence} & \\textbf{Strategy} & \\textbf{Optimal $k$} & \\textbf{Optimal $m$} & \\textbf{RAROC$_I$} & \\textbf{RAROC$_R$} & \\textbf{Profit$_I$} & \\textbf{Profit$_R$} \\\\\n\\hline\n');
    G = numel(out.LSL.k);
    for a = 1:A
        R = out.LSL.strat{typ,a};
        for s = 1:5
            [ik, im] = ind2sub([G G], R(s).idx);
            if s == 1, c1 = sprintf('\\multirow{5}{*}{%s}', lev{a}); else, c1 = ''; end
            if ~R(s).feasible
                w(fid, '%s & %s & \\multicolumn{6}{c|}{no feasible contract} \\\\\n', c1, R(s).name);
            elseif s == 5
                w(fid, '%s & %s & any & any & -- & -- & \\multicolumn{2}{c|}{$P_I+P_R = %.2f$} \\\\\n', ...
                  c1, R(s).name, R(s).PI + R(s).PR);
            else
            w(fid, '%s & %s & %.2f & %.2f & %s & %s & %.2f & %.2f \\\\\n', c1, R(s).name, ...
              out.LSL.k(ik), out.LSL.m(im), num(R(s).RI), num(R(s).RR), R(s).PI, R(s).PR);
            end
        end
        w(fid, '\\hline\n');
    end
    w(fid, '\\end{tabular}\n\n');
end

%% Tables 8 / 9: asymmetric Nash
w(fid, '%% ---- Table: Asymmetric Nash, stop-loss (VaR %.1f%%) ----\n', 100*P.alpha_levels(P.asym_level));
w(fid, '\\begin{tabular}{|c|c|c|c|c|c|c|}\n\\hline\n');
w(fid, '$\\alpha_b$ & \\textbf{Optimal $k^*_{\\alpha_b}$} & \\textbf{RAROC$_I$} & \\textbf{RAROC$_R$} & \\textbf{Profit$_I$} & \\textbf{Profit$_R$} & \\textbf{$P_I/P_R$} \\\\\n\\hline\n');
for b = 1:numel(out.SL.asym)
    R = out.SL.asym(b);
    w(fid, '%.1f & %.2f & %s & %s & %.2f & %.2f & %.4f \\\\\n', R.alpha_b, ...
      out.SL.k(R.idx), num(R.RI), num(R.RR), R.PI, R.PR, R.ratio);
end
w(fid, '\\hline\n\\end{tabular}\n\n');

w(fid, '%% ---- Table: Asymmetric Nash, limited stop-loss (VaR %.1f%%) ----\n', 100*P.alpha_levels(P.asym_level));
w(fid, '\\begin{tabular}{|c|c|c|c|c|c|c|c|}\n\\hline\n');
w(fid, '$\\alpha_b$ & \\textbf{Optimal $k^*_{\\alpha_b}$} & \\textbf{Optimal $m^*_{\\alpha_b}$} & \\textbf{RAROC$_I$} & \\textbf{RAROC$_R$} & \\textbf{Profit$_I$} & \\textbf{Profit$_R$} & \\textbf{$P_I/P_R$} \\\\\n\\hline\n');
G = numel(out.LSL.k);
for b = 1:numel(out.LSL.asym)
    R = out.LSL.asym(b);
    [ik, im] = ind2sub([G G], R.idx);
    w(fid, '%.1f & %.2f & %.2f & %s & %s & %.2f & %.2f & %.4f \\\\\n', R.alpha_b, ...
      out.LSL.k(ik), out.LSL.m(im), num(R.RI), num(R.RR), R.PI, R.PR, R.ratio);
end
w(fid, '\\hline\n\\end{tabular}\n');

fclose(fid);
fprintf('\nLaTeX tables written to %s\n', fname);
end

function s = num(x)
% RAROC is undefined when the risk capital is zero
if isnan(x) || isinf(x), s = '--';
elseif abs(x) >= 1e4, s = sprintf('$%.2f\\times 10^{%d}$', x/10^floor(log10(abs(x))), floor(log10(abs(x))));
else, s = sprintf('%.4f', x); end
end

function w(f, varargin)
% write to file and echo to console
s = sprintf(varargin{:});
fprintf(f, '%s', s);
fprintf('%s', s);
end
