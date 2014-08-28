function X = plus(X,Y)
%PLUS Merges two LMI objects to one LMI

if isa(X,'constraint')
    X = set(X);
elseif isa(X,'sdpvar')
    X = set(X);
end

if isa(Y,'constraint')
    Y = set(Y);
elseif isa(Y,'sdpvar')
    Y = set(Y);
end

% Support set+[]
if isempty(X)
    X = Y;
    return
elseif isempty(Y)   
    return
end

if ~((isa(X,'lmi')) & (isa(Y,'lmi')))
    error('Both arguments must be constraints')
end

nX = length(X.LMIid);
nY = length(Y.LMIid);
if nX==0
    X = Y;
    return
end
if nY == 0
    return;
end

% X assumed to be a long list of constraint and Y short list to be added
if nY > nX
    Z = X;
    X = Y;
    Y = Z;
end

xBlock = isa(X.clauses{1},'cell');
yBlock = isa(Y.clauses{1},'cell');
if yBlock && xBlock && length(X.clauses{1})>1  && length(Y.clauses{1})>1
    % Both objects are long blocks of constraints. Join these on high level
    for i = 1:length(Y.clauses)
        X.clauses{end+1} = Y.clauses{i};
    end
elseif ~xBlock && ~yBlock
    % Both have been flattened
    for i = 1:length(Y.clauses)
        X.clauses{end+1} = Y.clauses{i};
    end
else
    % This is the standard case. X has been populated with a bunch of
    % constraints (growing list) while Y is yet another constraint to be
    % added to that list.
    if ~xBlock
        % Lift to a single block
        temp = X.clauses;
        X.clauses = [];
        X.clauses{1} = temp;
    end
    % New block in X? This is where performance comes from. Handling cells
    % of cells is way faster in MATLAB, than a long cell (quadratic running
    % time, appears to be nasty copying going on when adding new elements)
    if length(X.clauses{end}) >= 100
        X.clauses{end+1} = {};
    end
    % Assume Y isn't too big, as we now flatten it and put it in the last
    % block of X
    Y.clauses = [Y.clauses{:}];
    j = length(X.clauses);
    for i = 1:length(Y.clauses)
        X.clauses{j}{end+1} = Y.clauses{i};
    end
end
aux = X.LMIid;
X.LMIid = [X.LMIid Y.LMIid];

% VERY FAST UNIQUE BECAUSE THIS IS CALLED A LOT OF TIMES....
if ~(max(aux) < min(Y.LMIid))
    i = sort(X.LMIid);
    i = i(diff([i NaN])~=0);
    if length(i)<nX+nY
        % Flatten first. This typically doesn't happen, so we accept this.
        X.clauses = [X.clauses{:}];
        [i,j] = unique(X.LMIid);
        X = subsref(X,struct('type','()','subs',{{j}}));
    end
end
