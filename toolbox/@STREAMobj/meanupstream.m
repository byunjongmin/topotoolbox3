function m = meanupstream(S,val,weights)

%MEANUPSTREAM Mean (weighted) upstream  values
%
% Syntax
%
%     m = meanupstream(S,val)
%     m = meanupstream(S,val,weights)
%
% Description
%
%     meanupstream calculates the mean weighted average of values val 
%     upstream to each location in a stream network (STREAMobj) S. val is a
%     node attribute list. The function allows to calculate the weighted
%     average give by the vector weights which must have same size as val.
%
% Input arguments
%
%     S        STREAMobj
%     val      node attribute list of values (e.g. derived by
%              STREAMobj/gradient or STREAMobj/getnal)
%     weights  weights same size as val
%
% Output arguments
%
%     m        node attribute list with average weighted upstream values
%
% Example
%
%     DEM = GRIDobj('srtm_bigtujunga30m_utm11.tif');
%     FD = FLOWobj(DEM,'preprocess','carve');
%     S = STREAMobj(FD,'minarea',1e5,'unit','map');
%     A = flowacc(FD);
%     c = chitransform(S,A,'mn',0.39);
%     z = imposemin(S,DEM);
%     mc = mchi(S,z,c);
%     uc = meanupstream(S,mc,getnal(S,A));
%     % plot results
%     imageschs(DEM,DEM,'colormap',[1 1 1],'colorbar',false)
%     hold on
%     plotc(S,uc);
%
%
% See also: STREAMobj, STREAMobj/getnal
%
% Author: Wolfgang Schwanghart (schwangh[at]uni-potsdam.de)
% Date: 2. July, 2024

arguments
    S    STREAMobj
    val  {mustBeGRIDobjOrNal(val,S)}
    weights {mustBeNumeric,mustBePositive} = 1
end

val = ezgetnal(S,val);
weights = ezgetnal(S,weights);

nr = numel(S.x);
M = sparse(S.ix,S.ixc,1,nr,nr);
M = speye(nr)-M';

weightsaccum = M\weights;
valaccum = M\(val.*weights);

m = valaccum./weightsaccum;