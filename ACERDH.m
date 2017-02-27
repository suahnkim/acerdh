% Main source code for ACERDH.
% Copyright (2017), Rolf Lussi + Suah Kim, All rights reserved.
% Written by Rolf Lussi with help from Suah Kim
% See paper for more details: Automatic contrast enhancement using reversible data hiding http://ieeexplore.ieee.org/document/7368603/

% License Info (LGPL):
% This library is free software; you can redistribute it and/or
% modify it under the terms of the GNU Lesser General Public
% License as published by the Free Software Foundation; either
% version 3 of the License, or (at your option) any later version.
%
% This library is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% Lesser General Public License for more details
%
% You should have received a copy of the GNU Lesser General Public
% License along with this library; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

function [image, repetition, image_hist, capacity_hist] = ACERDH(image)

image = uint8(image);
temp_count_sum=0;
embedding = 1;
repetition = 0;
headerSize = 80;
lastImage = image;
counter1=0;
while 1
    repetition = repetition + 1;
    disp(num2str(repetition))
    
    % Find frequency of all pixels 
    hist = imhist(image);
    
    % Highest peak
    [~, highPeak] = max(hist(2:end-1));
    highPeak = highPeak;
    
    % Lowest peak
    hist = hist(1:end-1)+hist(2:end);
    [~, lowPeak] = min(hist);
    lowPeak = lowPeak -1;
    
    % Determine the direction of the histogram shifting
    d = sign(lowPeak-highPeak);
    
    % Concurrent location map generation
    [map, c] = locationMap(image,lowPeak,lowPeak-d);
    mapSize = numel(map);
    lastPixels = image(end-15:end);
    capacity = numel(image(image==highPeak)) - numel(lastPixels(lastPixels==highPeak));
    
    disp(['highPeak : ' num2str(highPeak) ' lowPeak : ' num2str(lowPeak) ' c : ' num2str(capacity)])
    
    % Case where next repetition can not embed, go back to previous
    % repetition
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
    
    % Assemble header
    clear data;
    data.comp = c;
    data.map = map;
    data.rep = logical(repetition-1);
    data.highPeak = highPeak;
    data.lowPeak = lowPeak;
    data.load = randi([0,1],1,capacity-headerSize-mapSize);
    
    if embedding == 0  % Preparation for last embedding repetition
        data.LSB = mod(image(end-15:end),2);
        image(end-15:end) = image(end-15:end) - data.LSB;
        newLSB = [int2bin(highPeak,8)  int2bin(lowPeak,8)];
        image(end-15:end) = image(end-15:end) + uint8(newLSB);
        [n,m] = size(image);
        lastPixels = image(end-15:end);
        image = image(1:end-16);
        data = data2bin(data);
        data = data';
    else % Otherwise
        data.LSB = zeros(1,16);
        data = data2bin(data);
    end
    
    % Embedd data
    if d>0 % RHS 
        image(image>highPeak & image<lowPeak) = image(image>highPeak & image<lowPeak)+1;
        try
            image(image==highPeak) = image(image==highPeak)+data;
        catch
            d = numel(data)
            c = numel(image(image==highPeak))
            return
        end
    else % LHS
        image(image>lowPeak & image<highPeak) = image(image>lowPeak & image<highPeak)-1;
        try
            image(image==highPeak) = image(image==highPeak)-data;
        catch
            d = numel(data)
            c = numel(image(image==highPeak))
            return
        end
    end
    
    % Restore previous repetition and quit the program
    if embedding == 0
        image = [image lastPixels];
        image = reshape(image,n,m);
        capacity_hist(counter1)=capacity_hist(counter1-1)+capacity-headerSize-mapSize;
        image_hist(:,:,counter1)=image;
        break
    end
    
    % Update
    counter1=counter1+1;
    image_hist(:,:,counter1)=image;
    temp_count_sum=temp_count_sum+capacity-headerSize-mapSize;
    capacity_hist(counter1)=temp_count_sum;
end

end
