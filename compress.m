function y = compress(x)
    xC=cell(2,1);
    xC{1}=double(x);
    yC =  Arith07(xC);
    y = reshape(dec2bin(yC)-48,1,[]);
end