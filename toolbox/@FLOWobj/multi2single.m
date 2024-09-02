function [FD,S] = multi2single(FD,options)
%MULTI2SINGLE Converts multiple to single flow direction
%
% Syntax
%
%     FD = multi2single(FDm)
%     FD = multi2single(FDm,pn,pv,...)
%     [FD,S] = multi2single(FDm,pn,pv,...)
%
% Description
%
%     multi2single converts a multiple flow direction FLOWobj FDm into a 
%     single flow direction FLOWobj. Additional arguments enable to convert
%     only the channelized part defined by a minimum upstream area from
%     multi to single. 
%
% Input arguments
%
%     FDm   multiple flow directions
%     
%     Parameter name/value pairs
%
%     'minarea'      minimum upstream area required to initiate streams. The
%                    default is 0. Higher values will result in flow
%                    networks that have multiple flow directions up to the
%                    defined upstream area, and single flow directions
%                    downstream.
%     'unit'         unit of value determined with the parameter 'minarea':
%                    'pixels' (default) or 'mapunits'.
%     'channelheads' linear index into DEM with channelheads. 
%     'W'            GRIDobj with weights for weighted flow accumulation
%
% Output arguments
%
%     FD    FLOWobj. If 'minarea' == 0 (default), then FD will be a FLOWobj  
%           with single flow directions. Otherwise, FLOWobj will be of type 
%           'multi'.
%     S     STREAMobj (only applicable if 'minarea' is set >0 or
%           channelheads are provided.)
%     
%
% Example
% 
%     DEM = GRIDobj('srtm_bigtujunga30m_utm11.tif');
%     FD  = FLOWobj(DEM,'preprocess','carve','mex',true);
%     DEM = imposemin(FD,DEM,0.0001);
%     FD  = FLOWobj(DEM,'multi');
%     [FD,S]  = multi2single(FD,'minarea',100);
%     A   = flowacc(FD);
%     imageschs(DEM,log(A),'colormap',flowcolor)
%     hold on
%     plot(S,'k')
%     hold off
%
% See also: FLOWobj, FLOWobj/ismulti
%
% Author: Wolfgang Schwanghart (schwangh[at]uni-potsdam.de)
% Date: 31. August, 2024

arguments
    FD
    options.minarea (1,1) {mustBeNumeric,mustBeNonnegative} = 0
    options.unit {mustBeMember(options.unit,{'pixels','mapunits'})} = 'pixels'
    options.channelheads = []
    options.probability (1,1) = false
    options.randomize (1,1) = false
    options.W = GRIDobj(FD)+1
end

switch FD.type
    case 'single'
        
        % do nothing
        
    otherwise
        
        if options.randomize
            FD = randomize(FD);
        end
        
        if options.minarea > 0 || ~isempty(options.channelheads)
            
            if isempty(options.channelheads)
                
                unit    = validatestring(options.unit,{'pixels', 'mapunits'});
                switch unit
                    case 'mapunits'
                        minarea = options.minarea/(FD.cellsize.^2);
                    otherwise
                        minarea = options.minarea;
                end
                
                % Find stream network initiation points. This should not be
                % done via thresholding flow accumulation derived from multiple
                % flow directions because we may erroneously include pixels in
                % diverging parts of the river network.
                
                ix  = FD.ix;
                ixc = FD.ixc;
                fr  = FD.fraction;
                A   = options.W.Z;
                ini = false(FD.size);
                for r = 1:numel(ix)
                    if A(ix(r)) < minarea
                        A(ixc(r)) = A(ixc(r)) + fr(r)*A(ix(r));
                    elseif A(ix(r)) >=minarea
                        ini(ix(r)) = true;
                    end
                end
                
            else
                if isa(options.channelheads,'GRIDobj')
                    ini = options.channelheads.Z > 0;
                else
                    ini = false(FD.size);
                    ini(options.channelheads) = true;
                end
            end
            
            if nargout == 2
                channelheads = find(ini);
            end
            
        end
        
        RR = (1:numel(FD.ix))';
        IX = double(FD.ix);
        if ~options.probability
            % Incidence matrix
            S  = sparse(RR,IX,FD.fraction,max(RR),max(IX));
            [~,ii] = max(S,[],1);
        else
            [IXX,ix] = sort(IX);
            c = FD.fraction(ix);
            
            % cumulative probabilities for each edge leaving each giver
            for r = 2:numel(IXX)
                if IXX(r) == IXX(r-1)
                    c(r) = c(r)+c(r-1);
                end
            end
            
            [~,a,b] = unique(IXX);
            R = rand(size(a));
            R = R(b);
            
            II = c > R;
            I = II;
            for r = 2:numel(IXX)
                if IXX(r) == IXX(r-1) && II(r-1)
                    I(r) = false;
                end
            end
            
            frac = false(size(FD.fraction));
            frac(ix) = I;
            S  = sparse(RR,IX,frac,max(RR),max(IX));
            [~,ii] = max(S,[],1);
                    
            
            
        end
        I  = false(size(RR));
        I(ii) = true;
        
        if options.minarea <= 0 && isempty(options.channelheads)
        
            FD.ix  = FD.ix(I);
            FD.ixc = FD.ixc(I);
            FD.fraction = [];
        
            FD.type = 'single';
            
            if nargout == 2
                S = [];
            end
            
        else
            
            ix = FD.ix(I);
            ixc = FD.ixc(I);
            
            for r = 1:numel(ix)
                ini(ixc(r)) = ini(ixc(r)) || ini(ix(r));
            end
            
            I = I | ~ini(FD.ix);
            
            FD.fraction(ini(FD.ix)) = 1;
            FD.ix = FD.ix(I);
            FD.ixc = FD.ixc(I);
            FD.fraction = FD.fraction(I);
            
            FD.type = 'multi';
            
            if nargout == 2
                FD.type = 'single';
                S = STREAMobj(FD,'channelheads',channelheads);
                FD.type = 'multi';
            end
        end
            
        
end
end



