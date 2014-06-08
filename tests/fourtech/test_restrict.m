% Test file for fourtech/restrict.m

function pass = test_restrict(pref)

% Get preferences.
if (nargin < 1)
    pref = chebtech.techPref();
end

testclass = fourtech();

%%
% Check behavior for empty inputs.
f = testclass.make();
f = restrict(f, [-0.5 0.5]);
pass(1) = isempty(f);

%%
% Check behvaior for non-subinterval inputs.
f = testclass.make(@(x) sin(2*pi*x), [], [], pref);
g = restrict(f, [-1 1]);
pass(2) = isequal(f, g);

try
    g = restrict(f, [-1, 3]); %#ok<NASGU>
    pass(3) = 0;
catch ME
    pass(3) = strcmp(ME.identifier, 'FOURTECH:restrict:badinterval');
end

try
    g = restrict(f, [-2, 1]); %#ok<NASGU>
    pass(4) = 0;
catch ME
    pass(4) = strcmp(ME.identifier, 'FOURTECH:restrict:badinterval');
end

try
    g = restrict(f, [-1 -0.25 0.3 0.1 1]); %#ok<NASGU>
    pass(5) = 0;
catch ME
    pass(5) = strcmp(ME.identifier, 'FOURTECH:restrict:badinterval');
end

%%
% Spot-check a few functions
pass(6) = test_spotcheck_restrict(testclass, ...
    @(x) sin(2*pi*x) - 1, [-0.5 0.5], pref);
pass(7) = test_spotcheck_restrict(testclass, ...
    @(x) 3./(5 - 4*cos(2*pi*x)), [-0.5 0.5], pref);
pass(8) = test_spotcheck_restrict(testclass, ...
    @(x) cos(4*pi*x), [-0.25 0.25], pref);

%%
% Check multiple subinterval restriction.
f = testclass.make(@(x) sin(4*pi*x), [], [], pref);
g = restrict(f, [-1 -0.5 0 0.5]);
h1 = restrict(f, [-1 -0.5]);
h2 = restrict(f, [0 0.5]);
x = linspace(-1, 1, 100).';
err1 = feval(g{1} - h1, x);
err2 = feval(g{3} - h2, x);
pass(9) = all(err1(:) == 0) && all(err2(:) == 0);

%%
% Check operation for array-valued functions.
pass(10) = test_spotcheck_restrict(testclass, ...
    @(x) [sin(2*pi*x) cos(4*pi*x) exp(cos(2*pi*x))], [-0.5 0.5], pref);

end

% Spot-check restriction of a given function to a given subinterval.
function result = test_spotcheck_restrict(testclass, fun_op, subint, pref)
    % Perform restriction.
    f = testclass.make(fun_op, [], [], pref);
    g = restrict(f, subint);

    % Construct mapping from restricted subinterval to [-1, 1].
    a = subint(1);
    b = subint(2);
    map = @(t) (2/(b - a))*(t - a) - 1;

    % Sample on a grid of 100 points and check for accuracy.
    x = linspace(a, b, 100).';
    y_exact = fun_op(x);
    y_approx = feval(g, map(x));

    result = norm(y_exact - y_approx, Inf) < 100*max(g.vscale.*g.epslevel);
end
