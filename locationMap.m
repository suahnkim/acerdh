function [map, compressed] = locationMap(image,zero,one)

    map = image(image == zero | image == one);
    map = map - min(zero,one);
    if zero > one
        map = ~map;
    else
        map = logical(map);
    end
    
    cMap = compress(map);
%     disp(['mapsize : ' num2str(numel(map)) ' compressed : ' num2str(numel(cMap))])
    if numel(cMap) < numel(map)
        map = cMap;
        compressed = 1;
    else
        map = map';
        compressed = 0;
    end

end