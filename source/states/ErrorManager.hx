package;

class ErrorManager {
    public static function safeCall<T>(fn:() -> T, context:String = "", defaultValue:T = null):T {
        try {
            return fn();
        } catch(e) {
            trace('[ERROR] Error en ' + context + ': ' + e);
            return defaultValue;
        }
    }
    
    public static function trySet<T>(obj:T, fn:T -> Void, context:String = ""):Bool {
        try {
            if (obj != null) {
                fn(obj);
                return true;
            }
        } catch(e) {
            trace('[ERROR] Error en ' + context + ': ' + e);
        }
        return false;
    }
}
