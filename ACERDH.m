function [image, repetitions image_hist capacity_hist] = rhebp(image)

image = uint8(image);

brightness = mean2(image);
temp_count_sum=0;
embedding = 1;
repetition = 0;
headerSize = 80;
lastImage = image;
counter1=0;
while 1
    repetition = repetition + 1;
    disp(num2str(repetition))
    

    hist = imhist(image);
    
    [~, highPeak] = max(hist(2:end-1));
    highPeak = highPeak;% -1;
    
           hist = hist(1:end-1)+hist(2:end);
        [~, lowPeak] = min(hist);
        lowPeak = lowPeak -1;
    d = sign(lowPeak-highPeak);
    
    [map, c] = locationMap(image,lowPeak,lowPeak-d);
    mapSize = numel(map);
    lastPixels = image(end-15:end);
    capacity = numel(image(image==highPeak)) - numel(lastPixels(lastPixels==highPeak));
    
    disp(['highPeak : ' num2str(highPeak) ' lowPeak : ' num2str(lowPeak) ' c : ' num2str(capacity)])
    
    if capacity < mapSize+headerSize
        embedding = 0;
        image = lastImage;
        disp('too big map');
        continue;
    else
        lastImage = image;
    end
    
    if embedding == 1
        capacity = numel(image(image==highPeak));
    end
    
    % assembly header
    clear data;
    data.comp = c;
    data.map = map;
    data.rep = logical(repetition-1);
    data.highPeak = highPeak;
    data.lowPeak = lowPeak;
    data.load = randi([0,1],1,capacity-headerSize-mapSize);
    
    if embedding == 0
        data.LSB = mod(image(end-15:end),2);
        image(end-15:end) = image(end-15:end) - data.LSB;
        newLSB = [int2bin(highPeak,8)  int2bin(lowPeak,8)];
        image(end-15:end) = image(end-15:end) + uint8(newLSB);
        [n,m] = size(image);
        lastPixels = image(end-15:end);
        image = image(1:end-16);
        data = data2bin(data);
        data = data';
    else
        data.LSB = zeros(1,16);
        data = data2bin(data);
    end
    
    
    
    % embedd data
    
    %disp(['capacity ' num2str(numel(image(image==highPeak))) ' data ' num2str(numel(data))])
    if d>0
        image(image>highPeak & image<lowPeak) = image(image>highPeak & image<lowPeak)+1;
        try
            image(image==highPeak) = image(image==highPeak)+data;
        catch
            d = numel(data)
            c = numel(image(image==highPeak))
            return
        end
    else
        image(image>lowPeak & image<highPeak) = image(image>lowPeak & image<highPeak)-1;
        try
            image(image==highPeak) = image(image==highPeak)-data;
        catch
            d = numel(data)
            c = numel(image(image==highPeak))
            return
        end
    end
    
    if embedding == 0
        image = [image lastPixels];
        image = reshape(image,n,m);
        capacity_hist(counter1)=capacity_hist(counter1-1)+capacity-headerSize-mapSize;
        image_hist(:,:,counter1)=image;
        break
    end
    counter1=counter1+1;
    image_hist(:,:,counter1)=image;
    temp_count_sum=temp_count_sum+capacity-headerSize-mapSize;
    capacity_hist(counter1)=temp_count_sum;
end

end