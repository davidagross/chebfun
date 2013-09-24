classdef linop
    
    properties
        fundomain = [];
        
        % This stores the delayed evaluation. Its argument is an empty
        % instance of the class that determines how the operator is
        % instantiated (collocation matrix, function handle, ...).
        delayFun = [];
        
        % Track differential order.
        diffOrder = 0;
        
    end
    
    properties (Constant)
        % Used whenever a matrix is required but the type is not specified.
        % It doesn't work as a set/get property, because different linops
        % within one chebmatix can't have different defaults.
        defaultDiscretization = @colloc2;
    end
    
    
    methods
        function A = linop(domain)
            % A = LINOP()        Domain defaults to [-1,1].
            % A = LINOP(DOMAIN)
            if nargin==0
                domain = [-1 1];
            elseif nargin==1 && isa(domain,'linop')
                A = domain;
                return
            end
            A.fundomain = domain;
        end
        
        function d = domain(A)
            d = A.fundomain;
        end
        
        function d = get.diffOrder(A)
            d = A.diffOrder;
        end
        
        
        function C = minus(A,B)
            % C = A - B
            C = A + (-B);
        end
               
        function C = uminus(A)
            C = A;
            C.delayFun = @(z) -A.delayFun(z);
        end
        
        function C = horzcat(varargin)
            C = chebmatrix( varargin );
        end
        
        function C = vertcat(varargin)
            C = chebmatrix( varargin' );
        end
        
        
        function L = op(A)
            % OP(A) returns function handle for chebfuns
            L = A.delayFun( op([]) );
            L = L.func;
        end
        
        function L = matrix(A,dim,matrixType)
            % MATRIX(A,DIM) returns a collocation matrix using A's matrixType property.
            % MATRIX(A,DIM,DISCRETECLASS) uses the given constructor.            

            if nargin < 3
                matrixType = linop.defaultDiscretization;  
            end
            
            L = A.delayFun( matrixType(dim,domain(A)) );
        end
        
        function L = coeff(A)
            L = A.delayFun( coeff([]) );
            L = [L.coeffs{:}];
        end
        
        function L = feval(A,B)
            L = mtimes(A,B);
        end
        
    end
        
    methods (Static)
        function D = diff(varargin)
            % LINOP.DIFF  Differentiation operator.
            %
            % LINOP.DIFF returns the first-order differentation operator for
            % functions defined on [-1,1].
            %
            % LINOP.DIFF(DOMAIN) applies to functions defined on DOMAIN, which
            % may include breakpoints.
            %
            % LINOP.DIFF(DOMAIN,M) is the mth order derivative.
            p = inputParser;
            addOptional(p,'domain',[-1 1],@isnumeric);
            mcheck = @(m) validateattributes(m,{'numeric'},{'scalar','nonnegative','integer'});
            addOptional(p,'m',1,mcheck);
            parse(p,varargin{:});
            domain = p.Results.domain;
            m = p.Results.m;
            
            D = linopOperator(domain);
            D.delayFun = @(z) diff(z,m);
            D.diffOrder = m;
        end
        
        function C = cumsum(varargin)
            % LINOP.CUMSUM  Antiderivative operator.
            %
            % LINOP.CUMSUM returns the first-order antiderivative operator for
            % functions defined on [-1,1]. The result of applying the operator
            % is defined uniquely by having value zero at the left endpoint.
            %
            % LINOP.CUMSUM(DOMAIN) applies to functions defined on DOMAIN, which
            % may include breakpoints.
            %
            % LINOP.CUMSUM(DOMAIN,M) is the mth-repeated antiderivative.
            p = inputParser;
            addOptional(p,'domain',[-1 1],@isnumeric);
            mcheck = @(m) validateattributes(m,{'numeric'},{'scalar','nonnegative','integer'});
            addOptional(p,'m',1,mcheck);
            parse(p,varargin{:});
            domain = p.Results.domain;
            m = p.Results.m;
            
            C = linopOperator(domain);
            C.delayFun = @(z) cumsum(z,m);
            C.diffOrder = -m;
        end
        
        function I = eye(domain)
            % I = EYE(DOMAIN)   identity operator on the same domain
            if nargin==0, domain = [-1 1]; end
            I = linopOperator(domain);
            I.delayFun = @(z) eye(z);
            I.diffOrder = 0;
        end
        
        function Z = zeros(domain)
            % Z = ZEROS(DOMAIN)   zero operator on the same domain
            if nargin==0, domain = [-1 1]; end
            Z = linopOperator(domain);
            Z.delayFun = @(z) zeros(z);
            Z.diffOrder = 0;
        end
        
        function U = diag(u)
            % D = DIAG(U)  diagonal operator from the chebfun U
            U = linopOperator(u.domain);
            U.delayFun = @(z) diag(z,u);
            U.diffOrder = 0;
        end
        
        function S = sum(domain)
            % SUM(DOMAIN)  integration functional on the domain
            if nargin==0, domain = [-1 1]; end                        
            S = linopFunctional(domain);
            S.delayFun = @(z) sum(z);
            S.diffOrder = -1;
        end
        
        function E = evalAt(location, varargin)
            p = inputParser;
            addRequired(p,'location');
            addOptional(p,'domain',[-1 1]);
            valid = @(x) ischar(x) || isnumeric(x);
            addOptional(p,'direction',0,valid);
            parse(p,location,varargin{:});
            location = p.Results.location;
            domain = p.Results.domain;
            direction = p.Results.direction;
            if (location < domain(1)) || (location > domain(end))
                error('Evaluation location is not in the domain.')
            end
            
            % Convert direction argument into a number.
            if ischar(direction)
                if any( strncmpi(direction,{'left','-'},1) )
                    direction = -1;
                elseif any( strncmpi(direction,{'right','+'},1) )
                    direction = +1;
                else
                    error('Direction must be ''left'', ''right'', ''+'', or ''-''.')
                end
            end

            E = linopFunctional(domain);
            E.delayFun = @(z) evalAt(z,location,direction);
        end
        
        function E = eval(domain)
            % EVAL(DOMAIN) returns a function E. The output of E(X) is an
            % evaluator at X in the domain.
            if nargin==0, domain = [-1 1]; end
            E = @(x) linop.evalAt(domain,x);
        end
        
        function F = inner(f)
            F = linopFunctional(domain(f));
            F.delayFun = @(z) inner(z,f);
            F.diffOrder = 0;
        end

        function F = dot(f)   % synonym for inner()
            F = inner(f);
        end

    end
    

    
end