function F = diff(F, n, dim)
%DIFF   Differentiation of a CHEBFUN.
%   DIFF(F), when F is a column CHEBFUN, computes a column CHEBFUN whose columns
%   are the derivatives of the corresponding columns in F.  At discontinuities,
%   DIFF creates a Dirac delta with coefficient equal to the size of the jump.
%   Dirac deltas already existing in F will increase their degree.
%
%   DIFF(F), when F is an array-valued row CHEBFUN or a quasimatrix, computes
%   the first-order finite difference of F along its rows. The resulting row
%   CHEBFUN will have one row less than the number of rows in F.
%
%   DIFF(F, N) or DIFF(F, N, 1) computes the Nth derivative of F if F is a
%   column CHEBFUN and the Nth-order finite difference of F along its rows if F
%   is a row CHEBFUN. The order N does not have to be integer. When it is not,
%   the result is the corresponding fractional derivatives of F. For N > 1, 
%   the Riemann-Liouville definition is used by default. One can switch to 
%   the Caputo definition with a call of the form DIFF(F, N,'Caputo'),
%   with the third argument serving as the indicator of the definition
%   used.
%
%   DIFF(F, N, 2) is the Nth-order finite difference of F along its columns if
%   F is a column CHEBFUN and the Nth derivative of F if F is a row CHEBFUN.
%
% See also SUM, CUMSUM.

% Copyright 2014 by The University of Oxford and The Chebfun Developers.
% See http://www.chebfun.org for Chebfun information.

% Trivial case:
if ( isempty(F) )
    return
end

% Parse inputs:
if ( nargin == 1 )
    n = 1;
end
if ( nargin < 3 )
    dim = 1;
end

if ( isnumeric(dim) && ~any(dim == [1, 2]) )
    error('CHEBFUN:diff:dim', 'Dimension must either be 1 or 2.');
end
    
if ( round(n) ~= n )
    if strcmpi(dim, 'Caputo')
        % Caputo definition - differentiate then integrate:
        F = fracCumSum(diff(F, ceil(n)), ceil(n)-n); 
    else
        % Riemann-Liouville definition - integrate then differentiate:
        F = diff(fracCumSum(F, ceil(n)-n), ceil(n)); 
    end
    
    return
end

if ( xor(F(1).isTransposed, dim == 2) )
    % Diff across columns (or rows for a transposed) array-valued CHEBFUN:
    F = diffFiniteDim(F, n);
else
    % Diff along continuous dimension (i.e., dF/dx):
    for k = 1:numel(F)
        F(k) = diffContinuousDim(F(k), n);
    end
end

end

function f = diffFiniteDim(f, n)
% Differentiate across the finite dimension (i.e., across columns).
if ( numel(f) == 1 )
    % Array-valued CHEBFUN case:
    for k = 1:numel(f.funs)
        f.funs{k} = diff(f.funs{k}, n, 2);
    end
else
    % Quasimatrix case:
    numCols = numel(f);
    if ( numCols <= n )
        f = chebfun();
    else
        for j = 1:n
            for k = 1:numCols-j
                f(k) = f(k+1) - f(k);
            end
        end
    end
    f = f(1:numCols-n);
end

end

function f = diffContinuousDim(f, n)
% Differentiate along continuous dimension (i.e., df/dx).

% Grab some fields from f:
funs = f.funs;
numFuns = numel(funs);
numCols = size(f.funs{1}, 2);

% Set a tolerance: (used for introducing Dirac deltas at jumps)
tol = epslevel(f)*hscale(f);

p.enableDeltaFunctions = true;
pref = chebfunpref(p);
deltaTol = pref.deltaPrefs.deltaTol; % TODO: Which tol is correct?

% Loop n times for nth derivative:
for j = 1:n
    vs = get(f, 'vscale-local'); 
    vs = vs(:);

    % Detect jumps in the original function and create new deltas.
    deltaMag = getDeltaMag();

    % Differentiate each FUN in turn:
    for k = 1:numFuns
        funs{k} = diff(funs{k});
        
        % If there is a delta function at the join, recreate the FUN using the
        % DELTAFUN constructor:
        funs{k} = addDeltas(funs{k}, deltaMag(k:k+1,:));
    end
    
    % Compute new function values at breaks:
    pointValues = chebfun.getValuesAtBreakpoints(funs);
    
    % Reassign data to f:
    f.funs = funs;
    f.pointValues = pointValues;

end

    function deltaMag = getDeltaMag()
        deltaMag = zeros(numFuns + 1, numCols);
        for l = 1:(numFuns - 1)
            jmp = get(funs{l+1}, 'lval') - get(funs{l}, 'rval');
            if ( any(abs(jmp) > deltaTol ) )
                deltaMag(l+1, :) = jmp;
            end
        end
    end

    function f = addDeltas(f, deltaMag)
        if ( any(abs(deltaMag(:)) > deltaTol) )
            % [TODO]: This does not handle array-valuedness at the moment.
            if ( size(deltaMag, 2) > 1 )
                warning('CHEBFUN:diff:dirac:array', ...
                    'No support here for array-valuedness at the moment.');
                deltaMag = [0 ; 0];
            end
            % New delta functions are only possible at the ends of the domain:
            f = fun.constructor(f, f.domain, deltaMag.'/2, f.domain, pref);
        end
    end

end