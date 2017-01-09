function b = int2bin(i, n)
    if exist('n')
        b = dec2bin(i,n);
    else
        d = whos('i');
        switch d.class
        case 'uint8'
	    b = dec2bin(i,8);
        case 'uint16'
            b = dec2bin(i,16);
        case 'uint32'
	    b = dec2bin(i,32);
        case 'uint64'
            b = dec2bin(i,64);
        case 'int8'
	    b = dec2bin(i,8);
        case 'int16'
            b = dec2bin(i,16);
        case 'int32'
	    b = dec2bin(i,32);
        case 'int64'
            b = dec2bin(i,64);
        end
    end 
    
    b = str2num(b(:))';
end
