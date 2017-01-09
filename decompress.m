function y = decompress(x)
        
    xC=bin2dec(char(reshape(x,length(x)/8,8)+48));
    yC=Arith07(xC);
	y=yC{1}';

end