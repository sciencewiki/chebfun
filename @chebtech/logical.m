function f = logical(f)
%LOGICAL   CHEBTECH logical.
%   LOGICAL(F) returns a CHEBTECH which evaluates to one at all points where F
%   is nonzero and zero otherwise.  F cannot have any roots in its domain.  If
%   F does have roots, then LOGICAL(F) will return garbage with no warning. F
%   may be complex.

% Copyright 2013 by The University of Oxford and The Chebfun Developers.
% See http://www.chebfun.org for Chebfun information.

% TODO:  Should we use a tolerance here instead of any()?
f.values = any(f.values);
f.coeffs = f.values;
f.vscale = abs(f.values);

end
