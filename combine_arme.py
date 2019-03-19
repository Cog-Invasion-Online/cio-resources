from panda3d.core import PNMImage, Filename, PNMImageHeader

CHANNEL_AO = 0
CHANNEL_ROUGHNESS = 1
CHANNEL_METALLIC = 2
CHANNEL_EMISSIVE = 3

def setChannel(img, x, y, channel, val):
    if channel == CHANNEL_AO:
        img.setRed(x, y, val)
    elif channel == CHANNEL_ROUGHNESS:
        img.setGreen(x, y, val)
    elif channel == CHANNEL_METALLIC:
        img.setBlue(x, y, val)
    elif channel == CHANNEL_EMISSIVE:
        img.setAlpha(x, y, val)
        
def getChannel(img, x, y, channel):
    if channel == CHANNEL_AO:
        return img.getRed(x, y)
    elif channel == CHANNEL_ROUGHNESS:
        return img.getGreen(x, y)
    elif channel == CHANNEL_METALLIC:
        return img.getBlue(x, y)
    elif channel == CHANNEL_EMISSIVE:
        return img.getAlpha(x, y)

def getChannelName(channel):
    if channel == CHANNEL_AO:
        return "AO"
    elif channel == CHANNEL_ROUGHNESS:
        return "Roughness"
    elif channel == CHANNEL_METALLIC:
        return "Metallic"
    elif channel == CHANNEL_EMISSIVE:
        return "Emissive"

ao = Filename(raw_input("AO Image: "))
roughness = Filename(raw_input("Roughness Image: "))
metallic = Filename(raw_input("Metallic Image: "))
emissive = Filename(raw_input("Emissive Image: "))

size = [1024, 1024]

fImgs = [ao, roughness, metallic, emissive]
imgs = {}

foundSize = False

for i in xrange(len(fImgs)):
    fImg = fImgs[i]
    if fImg.exists():
        img = PNMImage()
        img.read(fImg)
        img.makeRgb()
        if not foundSize:
            size = [img.getReadXSize(), img.getReadYSize()]
            foundSize = True
        imgs[i] = img
    else:
        # assume it is a constant value
        imgs[i] = float(fImg.getFullpath())
        
print "Size:", size
        
output = PNMImage(*size)
output.setNumChannels(4)
output.setColorType(PNMImageHeader.CTFourChannel)
output.fill(1.0, 0.0, 0.0)
output.alphaFill(1.0)

for channel, img in imgs.items():
    print "Filling in", getChannelName(channel), "channel..."
    if isinstance(img, float):
        print "Value", img
    for x in xrange(size[0]):
        for y in xrange(size[1]):
            if isinstance(img, float):
                setChannel(output, x, y, channel, img)
            else:
                setChannel(output, x, y, channel, getChannel(img, x, y, 0))
            
outputFile = Filename(raw_input("Output image: "))
output.write(outputFile)
        
    
