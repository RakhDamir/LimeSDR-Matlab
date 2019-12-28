function str = num2sip(num,sgf,pfx,trz)
% Convert a scalar numeric into an metric prefixed string. (SI/engineering)
%
% (c) 2017 Stephen Cobeldick
%
% Convert a scalar numeric value into a string. The string gives the value
% as a coefficient with a metric prefix, for example 1000 -> '1 k'. If the
% rounded |num|<10^-24 or |num|>=10^27 then E-notation is used, without a prefix.
%
%%% Syntax:
%  str = num2sip(num)
%  str = num2sip(num,sgf)
%  str = num2sip(num,sgf,pfx)
%  str = num2sip(num,sgf,pfx,trz)
%
% See also SIP2NUM NUM2BIP BIP2NUM NUM2STR MAT2STR SPRINTF NUM2WORDS WORDS2NUM NATSORT NATSORTFILES
%
%% Examples %%
%
% num2sip(10000)  OR  num2sip(1e4)
%  ans = '10 k'
% num2sip(10000,4,true)
%  ans = '10 kilo'
% num2sip(10000,4,false,true)
%  ans = '10.00 k'
%
% num2sip(999,2)
%  ans = '1 k'
% num2sip(999,3)
%  ans = '999 '
%
% num2sip(-5.555e9,3)
%  ans = '-5.56 G'
%
% num2sip(10^2,[],'k')
%  ans = '0.1 k'
%
% ['Power: ',num2sip(200*1000^2,[],true),'watt']
%  ans = 'Power: 200 megawatt'
%
% sprintf('Clock frequency is %shertz.',num2sip(1234567890,8,true))
%  ans = 'Clock frequency is 1.2345679 gigahertz.'
%
% num2sip(sip2num('9 T'))
%  ans = '9 T'
%
%% SI Prefix Strings %%
%
% Order  |1000^1 |1000^2 |1000^3 |1000^4 |1000^5 |1000^6 |1000^7 |1000^8 |
% -------|-------|-------|-------|-------|-------|-------|-------|-------|
% Name   | kilo  | mega  | giga  | tera  | peta  | exa   | zetta | yotta |
% -------|-------|-------|-------|-------|-------|-------|-------|-------|
% Symbol*|   k   |   M   |   G   |   T   |   P   |   E   |   Z   |   Y   |
%
% Order  |1000^-1|1000^-2|1000^-3|1000^-4|1000^-5|1000^-6|1000^-7|1000^-8|
% -------|-------|-------|-------|-------|-------|-------|-------|-------|
% Name   | milli | micro | nano  | pico  | femto | atto  | zepto | yocto |
% -------|-------|-------|-------|-------|-------|-------|-------|-------|
% Symbol*|   m   |   u   |   n   |   p   |   f   |   a   |   z   |   y   |
%
%% Input and Output Arguments %%
%
%%% Inputs (*=default):
%  num = NumericScalar, the value to be converted to string <str>.
%  sgf = NumericScalar, the significant figures in the coefficient, *5.
%  pfx = CharacterVector, forces the output to use that prefix, e.g. 'k'.
%      = LogicalScalar, true/false* -> select binary prefix as name/symbol.
%  trz = LogicalScalar, true/false* -> select if decimal trailing zeros are required.
%
%%% Output:
%  str = Input <num> as a string: coefficient + space character + SI prefix.
%
% str = num2sip(num,*sgf,*pfx,*trz)

%% Input Wrangling %%
%
pfC = {...
    'y',    'z',    'a',   'f',    'p',   'n',   'u',    'm',    '','k',   'M',   'G',   'T',   'P',   'E',  'Z',    'Y';...
    'yocto','zepto','atto','femto','pico','nano','micro','milli','','kilo','mega','giga','tera','peta','exa','zetta','yotta'};
vPw = [ -24,    -21,   -18,    -15,   -12,    -9,     -6,     -3,+0,    +3,   +6,     +9,   +12,   +15,  +18,    +21,    +24];
pfB = 10;
dPw = 3;
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
	adj = n2pAdjust(log10(abs(num)),dPw);
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
	adj = n2pAdjust(log10(abs(num)),dPw);
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
%dcp = sgf-1-n2pPower(log10(abs(vec)));
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%num2sip
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