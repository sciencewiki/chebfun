function u = expm(L, t, u0, prefs)
%EXPM      Exponential semigroup of a linop.
%   u = EXPM(L, T, U0) uses matrix exponentiation to propagate an initial
%   condition U0 for time T through the differential equation u' = L*u, where L
%   is a linop. Formally, the solution is given by u(t) = exp(t*L)*u0, where
%   exp(t*L) is a semigroup generated by L.
%
%   The output is a chebmatrix. If T is a vector, then U will have one column
%   for each entry of T. 
%
%   L should have appropriate boundary conditions to make the problem
%   well-posed. Those conditions have zero values; i.e. are represented by
%   B*u(t)=0 for a linear functional B.
%
%   EXPM(...,PREFS) accepts a preference structure or object like that created
%   by CHEBOPPREF.
%
%   EXAMPLE: Heat equation
%      d = [-1 1];  x = chebfun('x',d);
%      D = operatorBlock.diff(d);  
%      A = linop( D^2 );  
%      E = functionalBlock.eval(d);
%      A = addBC(A,E(d(1)),0);   % left Dirichlet condition
%      A = addBC(A,E(d(2)),0);   % right Dirichlet condition
%      u0 = exp(-20*(x+0.3).^2);  
%      t = [0 0.001 0.01 0.1 0.5 1];
%      u = expm(A,t,u0);
%      colr = zeros(6,3);  colr(:,1) = 0.85.^(0:5)';
%      clf, set(gcf,'defaultaxescolororder',colr)
%      plot(chebfun(u),'linewidth',2)
%
%    See also LINOP/ADDBC.

% Copyright 2013 by The University of Oxford and The Chebfun Developers.
% See http://www.maths.ox.ac.uk/chebfun/ for Chebfun information.

if ( nargin < 4 )
    prefs = cheboppref;
end

discType = prefs.discretization;
isFun = isFunVariable(L); 

%% Set up the discretization:
if ( isa(discType, 'function_handle') )
    % Create a discretization object
    disc = discType(L);  
    
    % Merge domains of the operator and the initial condition.
    disc.domain = chebfun.mergeDomains(disc.domain, u0.domain); 
    
    % Set the allowed discretisation lengths: 
    dimVals = prefs.dimensionValues;
    
    dimVals( dimVals < length(u0) ) = [];
    
    % Apply the discretiztion dimension on all pieces:
    disc.dimension = repmat(dimVals(1), 1, numel(disc.domain)-1);
else
    % A discretization is given:
    disc = discType;
        
    % Initialise dimVals;
    dimVals = max(disc.dimension);
end

if ( isempty(L.continuity) )
     % Apply continuity conditions:
     disc.source = deriveContinuity(disc.source,disc.domain);
end

% Initialise happiness:
numInt = disc.numIntervals;
isDone = false(1, numInt);

if isa(u0, 'chebfun')
    u0 = chebmatrix({u0}); 
end

%% Loop over different times.
allu = chebmatrix({});
for i = 1:length(t)
    
    %% Loop over a finer and finer grid until happy:
    for dim = dimVals
 
        disc.dimension(~isDone) = dim;

        % Discretize the operator (incl. constraints/continuity):
        E = expm(disc, t(i));
        
        % Discretize the initial condition.
        %v0 = instantiate(disc, u0.blocks) 
        %v0 = cell2mat(v0);
        v0 = matrix(u0,disc.dimension,disc.domain);
        
        % Propagate.
        v = E*v0;
        
        % Convert the different components into cells
        u = partition(disc, v);
        
        % Test the happieness of the function pieces:
        [isDone, epsLevel] = testConvergence(disc, u(isFun));
        
        if ( all(isDone) )
            break
        end
        
    end
    
    if ( ~all(isDone) )
        warning('LINOP:expm:NoConverge', ...
            'Matrix exponential may not have converged.')
    end
    
    %% Tidy the solution for output:
    ucell = mat2fun(disc, u);
    allu = [ allu, chebmatrix(ucell) ];
end

u = allu;

end