function b = data2bin(d)

    % header fields
    b = [double(d.comp), double(d.rep)];
    b = [b zeros(1,14)];
    b = [b int2bin(uint8(d.highPeak),8)];
    b = [b int2bin(uint8(d.lowPeak),8)];
    b = [b d.LSB];
    
    % sizes of map and payload
    b = [b int2bin(uint16(numel(d.map)),16)];
    b = [b int2bin(uint16(numel(d.load)),16)];

    % map and payload
    b = [b d.map];
    b = [b d.load];
    b = uint8(b');
end