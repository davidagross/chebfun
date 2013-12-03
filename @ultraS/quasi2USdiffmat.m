function L = quasi2USdiffmat(c, dom, dim, outputSpace)
%  Copyright 2013 by The University of Oxford and The Chebfun Developers.
%  See http://www.chebfun.org for Chebfun information.

diffOrder = size(c, 2) - 1;
if ( nargin < 4 )
    outputSpace = diffOrder;
end

dummy = ultraS([]);
dummy.domain = dom;
dummy.dimension = dim;
c = fliplr(c);

L = 0*speye(sum(dim));
for j = 1:size(c, 2)
    %form D^(j-1) term.
    L = L + convert(dummy, j-1, outputSpace)*mult(dummy, c{j}, j-1)*diff(dummy, j - 1);
end

% if ( dim < 200 ) 
%     L = full(L); 
% end


end