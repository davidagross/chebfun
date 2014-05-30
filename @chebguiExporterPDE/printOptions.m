function printOptions(fid, expInfo)
tol = expInfo.tol;
pdeflag = expInfo.pdeflag;
doplot = expInfo.doplot;
dohold = expInfo.dohold;
ylim1 = expInfo.ylim1;
ylim2 = expInfo.ylim2;
fixN = expInfo.fixN;
% Option for tolerance
opts = [];
opts = [opts, '''Eps'',', tol];

if ( ~all(pdeflag) )
    opts = [opts, ',''PDEflag'',', 'pdeflag'];
end

% Options for plotting
if ( strcmpi(doplot, 'off') )
    opts = [opts, ',''Plot'',', '''off'''];
else
    if ( dohold )
        opts = [opts, ',''HoldPlot'',', '''on'''];
    end
    if ( ~isempty(ylim1) && ~isempty(ylim2) )
        opts = [opts, ',''Ylim'',[', ylim1, ',', ylim2,']'];
    end
end

% Options for fixed N
if ( ~isempty(fixN) )
    N = str2double(fixN);
    opts = [opts, ',''N'',', N];
end

% Set up preferences
fprintf(fid, '\n%% Setup preferences for solving the problem.\n');
fprintf(fid, 'opts = pdeset');
if ( isempty(opts) )
    fprintf(fid, ';\n', opts);
else
    fprintf(fid, '(%s);\n', opts);
end
end