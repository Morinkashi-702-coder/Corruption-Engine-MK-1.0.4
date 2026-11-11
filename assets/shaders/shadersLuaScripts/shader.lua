function onCreate()
initLuaShader("chroma")
initLuaShader("bloom")
initLuaShader("barrel")

makeLuaSprite("chromaShader")
setSpriteShader("chromaShader", "chroma")

makeLuaSprite("bloomShader")
setSpriteShader("bloomShader", "bloom")

makeLuaSprite("barrelShader")
setSpriteShader("barrelShader", "barrel")

runHaxeCode([[
trace(ShaderFilter);
game.camGame.setFilters([new ShaderFilter(game.getLuaObject("chromaShader").shader),
new ShaderFilter(game.getLuaObject("bloomShader").shader),
new ShaderFilter(game.getLuaObject("barrelShader").shader) 

]);

game.camHUD.setFilters([new ShaderFilter(game.getLuaObject("chromaShader").shader)
new ShaderFilter(game.getLuaObject("bloomShader").shader) 

]);
]])
end

function onSongStart()
setChrome(0.002)
setShaderFloat("barrelShader", "chromaticIntensity", 0.25);
setShaderFloat("barrelShader", "distortionIntensity", -0.25);
setShaderFloat("barrelShader", "offset", 0);
setShaderFloat("barrelShader", "zoom", 1.0);
setShaderFloat("barrelShader", "angle", 0);
setShaderFloat("barrelShader", "mirrorX", false);
setShaderFloat("barrelShader", "mirrorY", false);
end

function onUpdate(elapsed)
setShaderFloat("bloomShader", "intensity", 0.1);
setShaderFloat("bloomShader", "blurSize", 0.01);

if curStep == 863 then
setShaderFloat("barrelShader", "zoom", 0.25);
end
if curStep == 871 then
setShaderFloat("barrelShader", "zoom", 0.2);
end
if curStep == 876 then
setShaderFloat("barrelShader", "zoom", 0.15);
end
if curStep == 882 then
setShaderFloat("barrelShader", "zoom", 0.1);
end
if curStep == 890 then
setShaderFloat("barrelShader", "zoom", 0.05);
end
if curStep == 895 then
setShaderFloat("barrelShader", "zoom", 1.0);
end
end

function setChrome(chromeOffset)
setShaderFloat("chromaShader", "rOffset", chromeOffset);
setShaderFloat("chromaShader", "gOffset", 0.0);
setShaderFloat("chromaShader", "bOffset", chromeOffset * -1);
end

function boundTo(value, min, max)
return math.max(min, math.min(max, value))
end
function math.lerp(from,to,i)
return from+(to-from)*i
end

