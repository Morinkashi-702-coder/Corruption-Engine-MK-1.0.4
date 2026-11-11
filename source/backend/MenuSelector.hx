package backend;

class MenuSelector {
    public static var currentMenu:String = "NullDemo";
    private static var menuList:Array<String> = ["oldmenu", "NullDemo"];
    private static var currentIndex:Int = 1; // Empezar en "NullDemo"

    public static function init():Void {
        // Inicializar desde gameData.ini
        #if desktop
        try {
            var gameConfig = GameConfig.getInstance();
            var mainMenuStyle:String = gameConfig.getValue("menu", "mainmenustyle", "NullDemo").toLowerCase();
            
            // Si es "sempaidemo" o "oldmenu", usar "oldmenu" del menuList
            if (mainMenuStyle == "sempaidemo" || mainMenuStyle == "oldmenu") {
                currentIndex = 0;
                currentMenu = menuList[0];
            } else {
                currentIndex = 1;
                currentMenu = menuList[1];
            }
        } catch(e:Dynamic) { }
        #end
    }

    public static function getMenu():String {
        return currentMenu;
    }

    // Called by the external menu preview so the running session remembers
    // which menu the player actually selected.
    public static function setMenu(menu:String):Void {
        var normalized:String = menu.toLowerCase();
        if (normalized == 'sempaidemo' || normalized == 'oldmenu') {
            currentIndex = 0;
            currentMenu = menuList[0];
        } else {
            currentIndex = 1;
            currentMenu = menuList[1];
        }
    }

    public static function nextMenu() {
        currentIndex = (currentIndex + 1) % menuList.length;
        currentMenu = menuList[currentIndex];
    }

    public static function previousMenu() {
        currentIndex = (currentIndex - 1 + menuList.length) % menuList.length;
        currentMenu = menuList[currentIndex];
    }
}

