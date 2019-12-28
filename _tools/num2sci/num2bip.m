function str = num2bip(num,sgf,pfx,trz)
% Convert a scalar numeric into a binary-prefixed string. (ISO/IEC 80000-13)
%
% (c) 2017 Stephen Cobeldick
%
% Convert a scalar numeric value into a string. The string gives the value
% as a coefficient with a binary prefix, for example 1024 -> '1 Ki'. If the
% rounded |num|<10^-4 or |num|>=1024^9 then E-notation is used, without a prefix.
%
%%% Syntax:
%  str = num2bip(num)
%  str = num2bip(num,sgf)
%  str = num2bip(num,sgf,pfx)
%  str = num2bip(num,sgf,pfx,trz)
%
% See also BIP2NUM NUM2SIP SIP2NUM NUM2STR MAT2STR SPRINTF NUM2WORDS WORDS2NUM NATSORT NATSORTFILES
%
%% Examples %%
%
% num2bip(10240)  OR  num2bip(1.024e4)  OR  num2bip(pow2(10,10))  OR  num2bip(10*2^10)
%  ans = '10 Ki'
% num2bip(10240,4,true)
%  ans = '10 kibi'
% num2bip(10240,4,false,true)
%  ans = '10.00 Ki'
%
% num2bip(1023,3)
%  ans = '1020 '
% num2bip(1023,2)
%  ans = '1 Ki'
%
% num2bip(-5.555e9,3)
%  ans = '-5.17 Gi'
%
% num2bip(2^19,[],'Mi')
%  ans = '0.5 Mi'
%
% ['Memory: ',num2bip(200*1024^2,[],true),'byte']
%  ans = 'Memory: 200 mebibyte'
%
% sprintf('Data saved in %sbytes.',num2bip(1234567890,8,true))
%  ans = 'Data saved in 1.1497809 gibibytes.'
%
% num2bip(bip2num('9 Ti'))
%  ans = '9 Ti'
%
%% Binary Prefix Strings (ISO/IEC 80000-13) %%
%
% Order  |1024^1 |1024^2 |1024^3 |1024^4 |1024^5 |1024^6 |1024^7 |1024^8 |
% -------|-------|-------|-------|-------|-------|-------|-------|-------|
% Name   | kibi  | mebi  | gibi  | tebi  | pebi  | exbi  | zebi  | yobi  |
% -------|-------|-------|-------|-------|-------|-------|-------|-------|
% Symbol*|  Ki   |  Mi   |  Gi   |  Ti   |  Pi   |  Ei   |  Zi   |  Yi   |
% -------|-------|-------|-------|-------|-------|-------|-------|-------|
%
%% Input and Output Arguments %%
%
%%% Inputs (*=default):
%  num = NumericScalar, the value to be converted to string <str>.
%  sgf = NumericScalar, the significant figures in the coefficient, *5.
%  pfx = CharacterVector, forces the output to use that prefix, e.g. 'Ki'.
%      = LogicalScalar, true/false* -> select binary prefix as name/symbol.
%  trz = LogicalScalar, true/false* -> select if decimal trailing zeros are required.
%
%%% Output:
%  str = Input <num> as a string: coefficient + space character + binary prefix.
%
% str = num2bip(num,*sgf,*pfx,*trz)

%% Input Wrangling %%
%
pfC = {...
    '','Ki',  'Mi',  'Gi',  'Ti',  'Pi',  'Ei',  'Zi',  'Yi';...
    '','kibi','mebi','gibi','tebi','pebi','exbi','zebi','yobi'};
vPw = [0, +10,   +20,   +30,   +40,   +50,   +60,   +70,   +80];
pfB = 2;
dPw = 10;
%
assert(isnumeric(num)&&isscalar(num)&&isreal(num),'First input <num> must be a real numeric scalar.')
num = double(num);
%
if nargin<2 || isnumeric(sgf)&&isempty(sgf)
	sgf = 5;
else
	assert(isnumeric(sgf)&&isscalar(sgf)&&isreal(sgf),'Second input <sgf> must be a numeric scalar.')
	sgf = double(sgf);
end
%
if nargin<3 || isnumeric(pfx)&&isempty(pfx)
	pfx = false;
	adj = n2pAdjust(log2(abs(num)),dPw);
elseif ischar(pfx)&&size(pfx,1)<2 % user-requested prefix:
	[row,col] = find(strcmp(pfC,pfx));
	if numel(row)<1
		str = sprintf('''%s'', ',pfC{:});
		error('Third input <pfx> can be one of the following:\n%s',str) %#ok<SPERR>
	end
	pfx = 1 < row(1);
	pwr = vPw(col(1));
	adj = [pwr,pwr];
else % determine prefix powers pfx0<=pwr<pfx1:
	assert(islogical(pfx)&&isscalar(pfx),'Third input <pfx> can be a logical scalar.')
	adj = n2pAdjust(log2(abs(num)),dPw);
end
%
if nargin<4 || isnumeric(trz)&&isempty(trz)
	trz = false;
else
	assert(islogical(trz)&&isscalar(trz),'Fourth input <trz> must be a logical scalar.')
end
%
%% Generate String %%
%
% Obtain the coefficients:
vec = num./pfB.^adj;
% Determine the number of decimal places:
dcp = sgf-1-n2pPower(log10(abs(vec)));
% Round coefficients to decimal places:
vec = round(vec.*10.^dcp).*10.^-dcp;
% Identify which prefix is required:
idx = 1+any(abs(vec)==[pfB^dPw,1]);
% Obtain the required prefix index:
idp = vPw==adj(idx);
if any(idp) % Use prefix:
	pwr = 1+n2pPower(log10(abs(vec(idx))));
	fmt = n2pFormat(trz,sgf,pwr);
	str = sprintf(fmt,max(sgf,pwr),vec(idx),pfC{1+pfx,idp});
else % No suitable prefix:
	fmt = n2pFormat(trz,sgf,1);
	str = sprintf(fmt,sgf,num,'');
end
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%num2bip
function pwr = n2pPower(pwr)
pwr = floor(pwr);
pwr(~isfinite(pwr)) = 0;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%n2pPower
function adj = n2pAdjust(pwr,dPw)
adj = dPw*((0:1)+floor(n2pPower(pwr)/dPw));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%n2pAdjust
function fmt = n2pFormat(trz,sgf,pwr)
if trz && (sgf>pwr)
	fmt = '%#.*g%s';
else
	fmt = '%.*g%s';
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%n2pFormat